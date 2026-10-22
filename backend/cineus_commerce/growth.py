"""Authenticated product operations. No client value can mint purchased tickets."""
import base64
import json
import re
import secrets
import zlib
from .security import CommerceError, bounded, opaque

SCHEMA = '''
CREATE TABLE IF NOT EXISTS player_backups(owner TEXT PRIMARY KEY REFERENCES accounts(id), revision INTEGER NOT NULL, payload TEXT NOT NULL, updated_at INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS analytics_consent(owner TEXT PRIMARY KEY REFERENCES accounts(id), enabled INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS analytics_events(owner TEXT NOT NULL REFERENCES accounts(id), id TEXT NOT NULL, event TEXT NOT NULL, occurred_at INTEGER NOT NULL, received_at INTEGER NOT NULL, properties TEXT NOT NULL, PRIMARY KEY(owner,id));
CREATE INDEX IF NOT EXISTS analytics_time ON analytics_events(received_at);
CREATE TABLE IF NOT EXISTS editorial_feedback(owner TEXT NOT NULL REFERENCES accounts(id), id TEXT NOT NULL, payload TEXT NOT NULL, created_at INTEGER NOT NULL, PRIMARY KEY(owner,id));
CREATE TABLE IF NOT EXISTS friendly_games(code TEXT PRIMARY KEY, owner TEXT NOT NULL REFERENCES accounts(id), guest TEXT REFERENCES accounts(id), mode TEXT NOT NULL, movie INTEGER NOT NULL, host_score INTEGER, guest_score INTEGER, created_at INTEGER NOT NULL, expires_at INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS wallet_spends(owner TEXT NOT NULL REFERENCES accounts(id), operation TEXT NOT NULL, amount INTEGER NOT NULL CHECK(amount>0), state TEXT NOT NULL CHECK(state IN ('reserved','committed','refunded')), created_at INTEGER NOT NULL, PRIMARY KEY(owner,operation));
'''
EVENTS = {
 'ad_load_started':{'placement'}, 'ad_load_failed':{'placement'}, 'video_completed':set(), 'reward_verification_pending':set(),
 'app_active':set(), 'tutorial_completed':{'mode'}, 'game_opened':{'mode','kind'},
 'game_completed':{'mode','kind','outcome','score','score_cents','revealed_steps'},
 'daily_opened':{'mode'}, 'extra_hint_bought':{'mode','hint','ticket_cost'},
 'rewarded_help_delivered':{'outcome'}, 'tickets_insufficient':{'requested'},
 'rewarded_requested':set(), 'ad_available':{'placement'}, 'ad_shown':{'placement'},
 'ad_value':{'placement','currency','value_micros','precision'}, 'reward_credit_delivered':{'amount'},
 'rewarded_completed':{'reward','amount'}, 'collection_opened':set(),
 'item_previewed':{'product_id','item_id'}, 'collection_item_equipped':{'item_id'},
 'purchase_started':{'product_id'}, 'purchase_verified':{'product_id'},
 'purchase_restored':{'product_id'}, 'purchase_revoked':{'product_id'},
 'pass_purchase_started':set(), 'pass_entitlement_active':set(), 'pass_restore_started':set(),
 'mission_claimed':{'amount'}, 'experiment_exposed':{'variant'},
 'archive_opened':{'mode'}, 'invite_created':{'mode'}, 'invite_joined':{'mode'},
 'backup_saved':set(), 'backup_restored':set(),
}
ENUMS = {
 'mode':{'clue','poster','colors'}, 'kind':{'daily','stage','challenge','training','archive'},
 'outcome':{'won','lost','finished','help_and_ticket','tickets'},
 'placement':{'rewarded','interstitial','banner','native'}, 'variant':{'control','economy_v2'},
 'currency':{'BRL','USD','EUR'}, 'precision':{'unknown','estimated','publisherProvided','precise'},
 'reward':{'tickets'}, 'hint':{'director','year','runtime','guidance'},
}

def exact(value, fields):
    if not isinstance(value, dict) or set(value) != set(fields):
        raise CommerceError()

def integer(value, low=0, high=1000):
    if type(value) is not int or not low <= value <= high:
        raise CommerceError()
    return value

class Growth:
    def __init__(self, ledger):
        self.ledger = ledger
        with ledger.db.connection() as db:
            db.executescript(SCHEMA)
            if 'device' not in {r['name'] for r in db.execute('PRAGMA table_info(wallet_spends)')}:
                db.execute("ALTER TABLE wallet_spends ADD COLUMN device TEXT NOT NULL DEFAULT ''")
            columns={r['name'] for r in db.execute('PRAGMA table_info(friendly_games)')}
            for name in ['host_assisted','guest_assisted']:
                if name not in columns: db.execute('ALTER TABLE friendly_games ADD COLUMN '+name+' INTEGER NOT NULL DEFAULT 0')
        self.prune()

    def prune(self):
        # The worker runs this even when no player uploads another event.
        with self.ledger.db.transaction() as db:
            db.execute('DELETE FROM analytics_events WHERE received_at<?',
              (self.ledger.now()-60*86400,))

    def command(self, p, action, nonce, data):
        opaque(nonce)
        handlers = {'bootstrap':self.bootstrap, 'consent':self.consent, 'events':self.events,
          'feedback':self.feedback, 'backup_get':self.backup_get, 'backup_status':self.backup_status, 'backup_put':self.backup_put,
          'backup_delete':self.backup_delete, 'friend_create':self.friend_create,
          'friend_join':self.friend_join, 'friend_score':self.friend_score, 'friend_list':self.friend_list,
          'wallet':self.wallet, 'wallet_reserve':self.wallet_reserve,
          'wallet_commit':self.wallet_commit, 'wallet_refund':self.wallet_refund}
        if action not in handlers:
            raise CommerceError()
        value = handlers[action](p, data)
        return self.ledger.secrets.snapshot({'version':1,'audience':'cineus.growth.v1',
          'environment':self.ledger.settings.environment, 'owner':p.owner,'device':p.device,
          'issued_at':self.ledger.now(),'nonce':nonce,'action':action,'data':value})

    def bootstrap(self, p, data):
        exact(data, [])
        # A server-controlled rollout defaults to zero. Clients cannot select a treatment.
        percent = self.ledger.settings.economy_rollout_percent
        bucket = int(self.ledger.secrets.digest('economy_v2',p.owner)[:8],16) % 100
        return {'calendar':'calendar-20261020-v1','variant':'economy_v2' if bucket < percent else 'control',
          'stage_bonus':4 if bucket < percent else 10, 'daily_tickets':10,
          'banner_holdout':int(self.ledger.secrets.digest('banner_holdout_v1',p.owner)[:8],16)%100 < 10,
          'config_version':1}

    def consent(self, p, data):
        exact(data,['enabled'])
        if type(data['enabled']) is not bool: raise CommerceError()
        with self.ledger.db.transaction() as db:
            db.execute('INSERT OR REPLACE INTO analytics_consent VALUES(?,?)',(p.owner,int(data['enabled'])))
            if not data['enabled']:
                db.execute('DELETE FROM analytics_events WHERE owner=?',(p.owner,))
        return {'enabled':data['enabled']}

    def events(self, p, data):
        exact(data,['events'])
        rows = data['events']
        if not isinstance(rows,list) or not 1<=len(rows)<=50: raise CommerceError()
        clean=[]; now=self.ledger.now()
        for row in rows:
            exact(row,['id','event','occurred_at','properties'])
            bounded(row['id'],80)
            if row['event'] not in EVENTS: raise CommerceError()
            stamp=integer(row['occurred_at'],now-60*86400,now+300)
            props=row['properties']
            if not isinstance(props,dict) or set(props)-EVENTS[row['event']]: raise CommerceError()
            for key,value in props.items():
                if key in ENUMS:
                    if not isinstance(value,str) or value not in ENUMS[key]: raise CommerceError()
                elif key in {'product_id','item_id'}:
                    if not isinstance(value,str) or not re.fullmatch(r'[a-z0-9_.]{1,100}',value): raise CommerceError()
                else: integer(value,0,10**12 if key=='value_micros' else 1000)
            clean.append((p.owner,row['id'],row['event'],stamp,now,json.dumps(props,separators=(',',':'))))
        with self.ledger.db.transaction() as db:
            allowed=db.execute('SELECT enabled FROM analytics_consent WHERE owner=?',(p.owner,)).fetchone()
            if not allowed or not allowed[0]: raise CommerceError('consent_required',403)
            db.execute('DELETE FROM analytics_events WHERE received_at<?',(now-60*86400,))
            db.executemany('INSERT OR IGNORE INTO analytics_events VALUES(?,?,?,?,?,?)',clean)
        return {'accepted':[row['id'] for row in rows]}

    def feedback(self, p, data):
        exact(data,['id','mode','category','movie_id','question','note'])
        bounded(data['id'],80)
        if data['mode'] not in {'clue','poster','colors'} or data['category'] not in {'clue','artwork','difficulty','other'}: raise CommerceError()
        if data['movie_id'] is not None: integer(data['movie_id'],1,32767)
        for key,maximum in [('question',160),('note',500)]:
            if not isinstance(data[key],str) or len(data[key])>maximum: raise CommerceError()
        self.ledger.db.rate_limit('feedback:'+p.owner,10,86400,self.ledger.now())
        with self.ledger.db.transaction() as db:
            db.execute('INSERT OR IGNORE INTO editorial_feedback VALUES(?,?,?,?)',
              (p.owner,data['id'],self.ledger.secrets.encrypt(json.dumps(data)),self.ledger.now()))
        return {'accepted':data['id']}

    def backup_get(self,p,data):
        exact(data,[])
        with self.ledger.db.connection() as db:
            row=db.execute('SELECT * FROM player_backups WHERE owner=?',(p.owner,)).fetchone()
        return {'revision':row['revision'] if row else 0,'payload':self.ledger.secrets.decrypt(row['payload']) if row else None}

    def backup_status(self,p,data):
        exact(data,[])
        with self.ledger.db.connection() as db:
            row=db.execute('SELECT revision,updated_at FROM player_backups WHERE owner=?',(p.owner,)).fetchone()
        return {'revision':row['revision'] if row else 0,'updated_at':row['updated_at'] if row else None}

    def backup_put(self,p,data):
        exact(data,['revision','payload'])
        revision=integer(data['revision'],0,2**31-1)
        payload=bounded(data['payload'],55000)
        try:
            decoder=zlib.decompressobj()
            raw=decoder.decompress(base64.b64decode(payload,validate=True),4*1024*1024+1)
            if len(raw)>4*1024*1024 or not decoder.eof or decoder.unused_data: raise ValueError()
            content=json.loads(raw)
            if not isinstance(content,dict): raise ValueError()
            exact(content,['version','tables','catalogs'] if content.get('version')==2 else ['version','tables'])
            if content['version'] not in {1,2} or not isinstance(content['tables'],dict): raise ValueError()
            if content['version']==2 and (not isinstance(content['catalogs'],list) or len(content['catalogs'])>100): raise ValueError()
            # Backups cannot write purchased balance, entitlement or identity tables.
            if set(content['tables'])-{'game_sessions','color_sessions','color_stage_slots','journey_completions','journey_claims','character_discovery','journey_offers','economy_stage_contracts','ticket_rewards'}: raise ValueError()
            if any(not isinstance(rows,list) or len(rows)>20000 for rows in content['tables'].values()): raise ValueError()
        except (ValueError,TypeError,zlib.error): raise CommerceError('invalid_backup') from None
        with self.ledger.db.transaction() as db:
            old=db.execute('SELECT revision FROM player_backups WHERE owner=?',(p.owner,)).fetchone()
            current=old[0] if old else 0
            if current!=revision: raise CommerceError('backup_conflict',409)
            db.execute('INSERT OR REPLACE INTO player_backups VALUES(?,?,?,?)',
              (p.owner,current+1,self.ledger.secrets.encrypt(payload),self.ledger.now()))
        return {'revision':current+1}

    def backup_delete(self,p,data):
        exact(data,[])
        with self.ledger.db.transaction() as db: db.execute('DELETE FROM player_backups WHERE owner=?',(p.owner,))
        return {'deleted':True}

    def friend_create(self,p,data):
        exact(data,['mode','movie','score']+(['assisted'] if 'assisted' in data else []))
        assisted=data.get('assisted',False)
        if type(assisted) is not bool: raise CommerceError()
        if data['mode'] not in {'clue','poster'}: raise CommerceError()
        movie=integer(data['movie'],1,500); score=integer(data['score'],0,10 if data['mode']=='clue' else 5)
        now=self.ledger.now(); code=secrets.token_urlsafe(9)
        with self.ledger.db.transaction() as db:
            db.execute('DELETE FROM friendly_games WHERE expires_at<?',(now,))
            if db.execute('SELECT COUNT(*) FROM friendly_games WHERE owner=?',(p.owner,)).fetchone()[0]>=10: raise CommerceError('invite_limit',409)
            db.execute('INSERT INTO friendly_games(code,owner,guest,mode,movie,host_score,guest_score,created_at,expires_at,host_assisted) VALUES(?,?,NULL,?,?,?,NULL,?,?,?)',(code,p.owner,data['mode'],movie,score,now,now+7*86400,int(assisted)))
        return {'code':code,'expires_at':now+7*86400}

    def _friend(self,db,code):
        if not isinstance(code,str) or not re.fullmatch(r'[A-Za-z0-9_-]{12}',code): raise CommerceError()
        row=db.execute('SELECT * FROM friendly_games WHERE code=? AND expires_at>?',(code,self.ledger.now())).fetchone()
        if not row: raise CommerceError('invite_not_found',404)
        return row

    def friend_join(self,p,data):
        exact(data,['code'])
        with self.ledger.db.transaction() as db:
            row=self._friend(db,data['code'])
            if row['owner']==p.owner: raise CommerceError('own_invite',409)
            if row['guest'] not in {None,p.owner}: raise CommerceError('invite_full',409)
            db.execute('UPDATE friendly_games SET guest=? WHERE code=?',(p.owner,row['code']))
        return {'mode':row['mode'],'movie':row['movie'],'code':row['code']}

    def friend_score(self,p,data):
        exact(data,['code','score']+(['assisted'] if 'assisted' in data else []))
        assisted=data.get('assisted',False)
        if type(assisted) is not bool: raise CommerceError()
        with self.ledger.db.transaction() as db:
            row=self._friend(db,data['code'])
            if row['guest']!=p.owner: raise CommerceError('invite_not_found',404)
            score=integer(data['score'],0,10 if row['mode']=='clue' else 5)
            if row['guest_score'] is not None and (row['guest_score']!=score or row['guest_assisted']!=int(assisted)): raise CommerceError('result_locked',409)
            db.execute('UPDATE friendly_games SET guest_score=?,guest_assisted=? WHERE code=?',(score,int(assisted),row['code']))
        return {'accepted':True,'ranked':False}

    def friend_list(self,p,data):
        exact(data,[])
        with self.ledger.db.connection() as db:
            rows=db.execute('SELECT * FROM friendly_games WHERE (owner=? OR guest=?) AND expires_at>? ORDER BY created_at DESC LIMIT 20',(p.owner,p.owner,self.ledger.now())).fetchall()
        return {'games':[{'code':r['code'],'mode':r['mode'],'host_score':r['host_score'],
          'guest_score':r['guest_score'],'host':r['owner']==p.owner,'ranked':False,'expires_at':r['expires_at'],
          'host_assisted':bool(r['host_assisted']),'guest_assisted':bool(r['guest_assisted'])} for r in rows]}

    def _balance(self,db,owner):
        from .config import TICKET_PRODUCTS
        credits=sum(TICKET_PRODUCTS.get(r['product'],0) for r in db.execute('SELECT product FROM purchases WHERE owner=? AND revoked=0',(owner,)))
        debits=db.execute("SELECT COALESCE(SUM(amount),0) FROM wallet_spends WHERE owner=? AND state IN ('reserved','committed')",(owner,)).fetchone()[0]
        return max(0,credits-debits)

    def wallet(self,p,data):
        exact(data,[])
        with self.ledger.db.transaction() as db:
            # Recovery revokes the previous device. Its unfinished reservations
            # must not strand purchased funds on an inaccessible installation.
            db.execute("UPDATE wallet_spends SET state='refunded' WHERE owner=? AND state='reserved' AND device<>? AND device IN (SELECT id FROM devices WHERE owner=? AND revoked=1)",(p.owner,p.device,p.owner))
            return {'balance':self._balance(db,p.owner)}

    def wallet_reserve(self,p,data):
        exact(data,['operation','amount'])
        operation=bounded(data['operation'],80); amount=integer(data['amount'],1,10)
        with self.ledger.db.transaction() as db:
            row=db.execute('SELECT * FROM wallet_spends WHERE owner=? AND operation=?',(p.owner,operation)).fetchone()
            if row:
                if row['amount']!=amount or row['state']=='refunded': raise CommerceError('operation_conflict',409)
            else:
                if self._balance(db,p.owner)<amount: raise CommerceError('insufficient_tickets',409)
                db.execute("INSERT INTO wallet_spends(owner,operation,amount,state,created_at,device) VALUES(?,?,?,'reserved',?,?)",(p.owner,operation,amount,self.ledger.now(),p.device))
            return {'operation':operation,'balance':self._balance(db,p.owner)}

    def _settle(self,p,data,state):
        exact(data,['operation']); operation=bounded(data['operation'],80)
        with self.ledger.db.transaction() as db:
            row=db.execute('SELECT state FROM wallet_spends WHERE owner=? AND operation=?',(p.owner,operation)).fetchone()
            if not row: raise CommerceError('operation_not_found',404)
            if row[0] not in {'reserved',state}: raise CommerceError('operation_conflict',409)
            db.execute('UPDATE wallet_spends SET state=? WHERE owner=? AND operation=?',(state,p.owner,operation))
            return {'balance':self._balance(db,p.owner)}

    def wallet_commit(self,p,data): return self._settle(p,data,'committed')
    def wallet_refund(self,p,data): return self._settle(p,data,'refunded')
