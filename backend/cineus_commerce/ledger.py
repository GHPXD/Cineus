from dataclasses import dataclass
from datetime import datetime, timezone
import hmac
import json
import secrets
import time
import re
from .config import Settings, PRODUCT_ITEMS, CLUB
from .security import CommerceError, Secrets, opaque, uuid_value, bounded
from .storage import Database, audit

@dataclass(frozen=True)
class Principal:
    owner: str
    device: str

@dataclass(frozen=True)
class VerifiedCycle:
    id: str
    starts_at: int
    revoked: bool = False
    authority_at: int = 0

@dataclass(frozen=True)
class VerifiedRevenue:
    id: str
    purchased_at: int
    currency: str
    gross_nanos: int
    proceeds_nanos: int | None = None
    state: str = 'PROCESSED'
    authority_at: int = 0

@dataclass(frozen=True)
class VerifiedPurchase:
    owner: str
    product: str
    valid_from: int
    revoked: bool = False
    valid_until: int | None = None
    needs_ack: bool = False
    cycles: tuple[VerifiedCycle,...] = ()
    revenue: tuple[VerifiedRevenue,...] = ()
    state: str = 'active'

class Ledger:
    def __init__(self, settings: Settings, now=None):
        self.settings, self.secrets = settings, Secrets(settings)
        self.db = Database(settings)
        self.now = now or (lambda: int(time.time()))

    def register(self, owner, device, token, recovery):
        uuid_value(owner); uuid_value(device); opaque(token); opaque(recovery)
        now = self.now()
        th, rh = self.secrets.digest('token', token), self.secrets.digest('recovery', recovery)
        with self.db.transaction() as db:
            account = db.execute('SELECT * FROM accounts WHERE id=?', (owner,)).fetchone()
            if account:
                existing = db.execute('SELECT * FROM devices WHERE id=? AND owner=?', (device,owner)).fetchone()
                if (not hmac.compare_digest(account['recovery_hash'], rh) or not existing or
                    not hmac.compare_digest(existing['token_hash'], th) or existing['revoked']):
                    raise CommerceError('invalid_credentials', 401)
            else:
                if db.execute('SELECT 1 FROM devices WHERE id=?', (device,)).fetchone():
                    raise CommerceError('invalid_credentials', 401)
                db.execute('INSERT INTO accounts(id,recovery_hash,created_at) VALUES(?,?,?)', (owner,rh,now))
                db.execute('INSERT INTO devices(id,owner,token_hash,expires_at) VALUES(?,?,?,?)',
                           (device,owner,th,now+90*86400))
                audit(db,'identity_created',owner,device,now)
        return Principal(owner,device)

    def authenticate(self, token):
        try:
            opaque(token)
        except CommerceError:
            raise CommerceError('invalid_credentials',401) from None
        with self.db.connection() as db:
            row = db.execute('SELECT * FROM devices WHERE token_hash=?',
                             (self.secrets.digest('token',token),)).fetchone()
        if not row or row['revoked'] or row['expires_at'] <= self.now():
            raise CommerceError('invalid_credentials',401)
        return Principal(row['owner'],row['id'])

    def recover(self, owner, recovery, new_device, new_token):
        uuid_value(owner); uuid_value(new_device); opaque(recovery); opaque(new_token)
        now = self.now()
        with self.db.transaction() as db:
            row = db.execute('SELECT recovery_hash FROM accounts WHERE id=?',(owner,)).fetchone()
            if not row or not hmac.compare_digest(row[0],self.secrets.digest('recovery',recovery)):
                raise CommerceError('invalid_credentials',401)
            existing = db.execute('SELECT * FROM devices WHERE id=?',(new_device,)).fetchone()
            token_hash = self.secrets.digest('token',new_token)
            if existing:
                if existing['owner'] != owner:
                    raise CommerceError('invalid_credentials',401)
                db.execute('UPDATE devices SET revoked=1 WHERE owner=? AND id<>?',(owner,new_device))
                db.execute('UPDATE devices SET token_hash=?,expires_at=?,revoked=0 WHERE id=?',
                           (token_hash,now+90*86400,new_device))
                audit(db,'identity_renewed',owner,new_device,now)
            else:
                db.execute('UPDATE devices SET revoked=1 WHERE owner=?',(owner,))
                db.execute('INSERT INTO devices(id,owner,token_hash,expires_at) VALUES(?,?,?,?)',
                           (new_device,owner,token_hash,now+90*86400))
                audit(db,'identity_recovered',owner,new_device,now)
        return Principal(owner,new_device)

    def source(self, platform, proof):
        if platform not in {'google','apple'}:
            raise CommerceError()
        return platform + ':' + self.secrets.digest('purchase:'+platform, bounded(proof))

    def begin_verification(self, source):
        with self.db.transaction() as db:
            db.execute('INSERT INTO verification_sequences VALUES(?,1) ON CONFLICT(source) DO UPDATE SET value=value+1',(source,))
            return db.execute('SELECT value FROM verification_sequences WHERE source=?',(source,)).fetchone()[0]

    def apply_purchase(self, platform, proof, sequence, purchase: VerifiedPurchase, expected_owner=None):
        source, now = self.source(platform,proof), self.now()
        if purchase.product not in PRODUCT_ITEMS:
            raise CommerceError('unsupported_product')
        uuid_value(purchase.owner)
        if expected_owner and purchase.owner != expected_owner:
            raise CommerceError('proof_owner_mismatch',409)
        with self.db.transaction() as db:
            if not db.execute('SELECT 1 FROM accounts WHERE id=?',(purchase.owner,)).fetchone():
                raise CommerceError('identity_not_registered',409)
            old = db.execute('SELECT * FROM purchases WHERE source=?',(source,)).fetchone()
            if old and (old['owner'] != purchase.owner or old['product'] != purchase.product):
                raise CommerceError('proof_owner_mismatch',409)
            if old and old['sequence'] >= sequence:
                return source
            # A stale in-flight verification cannot override a newer request.
            newest = db.execute('SELECT value FROM verification_sequences WHERE source=?',(source,)).fetchone()
            if not newest or sequence != newest[0]:
                return source
            changed = not old or any((old['revoked'] != int(purchase.revoked),
                old['valid_until'] != purchase.valid_until, old['valid_from'] != purchase.valid_from))
            db.execute('''INSERT INTO purchases VALUES(?,?,?,?,?,?,?,?,?,?,?)
                ON CONFLICT(source) DO UPDATE SET revoked=excluded.revoked,
                valid_until=excluded.valid_until, valid_from=excluded.valid_from,
                sequence=excluded.sequence, observed_at=excluded.observed_at, needs_ack=excluded.needs_ack''',
                (source,purchase.owner,platform,purchase.product,self.secrets.encrypt(proof),
                 purchase.valid_from,purchase.valid_until,int(purchase.revoked),sequence,now,int(purchase.needs_ack)))
            for cycle in purchase.cycles:
                if purchase.product != CLUB:
                    raise CommerceError('invalid_cycle')
                changed = self._cycle(db,source,platform,purchase.owner,cycle,now) or changed
            for revenue in purchase.revenue:
                self._revenue(db,platform,purchase.owner,purchase.product,revenue,now)
            previous_state=db.execute('SELECT state FROM purchase_states WHERE source=?',(source,)).fetchone()
            db.execute('INSERT OR REPLACE INTO purchase_states VALUES(?,?,?)',(source,purchase.state,now))
            if previous_state and previous_state['state']!=purchase.state:
                audit(db,'purchase_state_changed',purchase.owner,source,now)
            if changed:
                db.execute('UPDATE accounts SET revision=revision+1 WHERE id=?',(purchase.owner,))
                audit(db,'purchase_revoked' if purchase.revoked else 'purchase_verified',purchase.owner,source,now)
        return source

    def cycle_source(self,platform,cycle):
        return platform+':'+self.secrets.digest('cycle:'+platform,bounded(cycle,256))

    def _cycle(self,db,purchase_source,platform,owner,cycle,now):
        if type(cycle.starts_at) is not int or not 0<=cycle.starts_at<=now+300:
            raise CommerceError('invalid_cycle')
        key=self.cycle_source(platform,cycle.id)
        month=datetime.fromtimestamp(cycle.starts_at,timezone.utc).strftime('%Y-%m')
        product=self.settings.club_calendar.get(month)
        old=db.execute('SELECT * FROM cycle_grants WHERE source=?',(key,)).fetchone()
        if old and (old['owner']!=owner or (old['product'] and product and old['product']!=product)):
            raise CommerceError('cycle_conflict',409)
        authority=cycle.authority_at or now
        if old and (old['authority_at']>authority or
            (old['authority_at']==authority and old['revoked'] and not cycle.revoked)):
            return False
        product=old['product'] if old and old['product'] else product
        changed=not old or old['revoked']!=int(cycle.revoked) or old['product']!=product
        db.execute('''INSERT INTO cycle_grants VALUES(?,?,?,?,?,?,?,?,?,?,?)
            ON CONFLICT(source) DO UPDATE SET product=excluded.product,revoked=excluded.revoked,
            observed_at=excluded.observed_at,authority_at=excluded.authority_at''',(key,owner,platform,purchase_source,product,month,
            cycle.starts_at,int(cycle.revoked),self.secrets.encrypt(cycle.id),now,authority))
        if changed:
            audit(db,'cycle_revoked' if cycle.revoked else 'cycle_granted' if product else 'cycle_content_missing',owner,key,now)
        return changed

    def _revenue(self,db,platform,owner,product,value,now):
        if (not re.fullmatch(r'[A-Z]{3}',value.currency) or type(value.gross_nanos) is not int
            or not 0<=value.gross_nanos<=9*10**18 or (value.proceeds_nanos is not None and
            (type(value.proceeds_nanos) is not int or not -9*10**18<=value.proceeds_nanos<=9*10**18))):
            raise CommerceError('invalid_financial_record')
        key=self.cycle_source(platform,value.id)
        old=db.execute('SELECT * FROM financial_orders WHERE source=?',(key,)).fetchone()
        if old and (old['owner']!=owner or old['product']!=product):
            raise CommerceError('order_conflict',409)
        authority=value.authority_at or now
        if old and (old['authority_at']>authority or
            (old['authority_at']==authority and old['state']=='REFUNDED' and value.state!='REFUNDED')): return
        db.execute('''INSERT INTO financial_orders VALUES(?,?,?,?,?,?,?,?,?,?,?)
            ON CONFLICT(source) DO UPDATE SET gross_nanos=excluded.gross_nanos,
            proceeds_nanos=excluded.proceeds_nanos,state=excluded.state,observed_at=excluded.observed_at,authority_at=excluded.authority_at''',
            (key,owner,platform,product,value.purchased_at,value.currency,value.gross_nanos,value.proceeds_nanos,value.state,now,authority))

    def apply_historical_cycle(self,platform,proof,cycle,revenue):
        source=self.source(platform,proof)
        with self.db.transaction() as db:
            row=db.execute('SELECT owner,product FROM purchases WHERE source=?',(source,)).fetchone()
            if not row or row['product']!=CLUB: raise CommerceError('cycle_not_found',404)
            if self._cycle(db,source,platform,row['owner'],cycle,self.now()):
                db.execute('UPDATE accounts SET revision=revision+1 WHERE id=?',(row['owner'],))
            if revenue:self._revenue(db,platform,row['owner'],CLUB,revenue,self.now())

    def enqueue_event(self, platform, event_id, payload, timestamp):
        bounded(event_id,256)
        now = self.now()
        if timestamp > now+300 or timestamp < now-30*86400:
            raise CommerceError('event_outside_window')
        raw = json.dumps(payload,sort_keys=True,separators=(',',':'))
        digest = self.secrets.digest('event',raw)
        with self.db.transaction() as db:
            old = db.execute('SELECT * FROM provider_events WHERE platform=? AND event_id=?',(platform,event_id)).fetchone()
            if old:
                if not hmac.compare_digest(old['digest'],digest):
                    raise CommerceError('event_conflict',409)
                return not bool(old['completed'])
            db.execute('INSERT INTO provider_events(platform,event_id,payload,digest,received_at) VALUES(?,?,?,?,?)',
                       (platform,event_id,self.secrets.encrypt(raw),digest,now))
            audit(db,'event_received',reference=platform+':'+event_id,now=now)
        return True

    def event_finished(self, platform, event_id, error=None):
        with self.db.transaction() as db:
            db.execute('UPDATE provider_events SET attempts=attempts+1,last_error=?,completed=? WHERE platform=? AND event_id=?',
                       (error,0 if error else 1,platform,event_id))

    def start_reward(self, principal):
        now = self.now()
        day = datetime.fromtimestamp(now,timezone.utc).date().isoformat()
        with self.db.transaction() as db:
            used = db.execute('SELECT COUNT(*) FROM rewards WHERE owner=? AND day=?',(principal.owner,day)).fetchone()[0]
            if used >= 3:
                raise CommerceError('daily_reward_limit',409)
            # Reuse the outstanding attempt; rapid taps do not create more slots.
            pending = db.execute('SELECT * FROM reward_attempts WHERE owner=? AND device=? AND used=0 AND expires_at>?',
                                 (principal.owner,principal.device,now)).fetchone()
            if pending:
                return {'attempt_id':pending['id'],'expires_at':pending['expires_at'],'amount':2}
            token = secrets.token_urlsafe(32)
            db.execute('INSERT INTO reward_attempts VALUES(?,?,?,?,?,0)',
                       (token,principal.owner,principal.device,now,now+1800))
        return {'attempt_id':token,'expires_at':now+1800,'amount':2}

    def confirm_reward(self, transaction, attempt, owner, occurred_at):
        bounded(transaction,256); opaque(attempt); uuid_value(owner)
        now = self.now()
        if occurred_at > now+300 or occurred_at < now-86400:
            raise CommerceError('reward_outside_window')
        receipt = 'admob:' + self.secrets.digest('reward',transaction)
        day = datetime.fromtimestamp(occurred_at,timezone.utc).date().isoformat()
        with self.db.transaction() as db:
            old = db.execute('SELECT * FROM rewards WHERE id=?',(receipt,)).fetchone()
            if old:
                if old['owner'] != owner or old['attempt'] != attempt:
                    raise CommerceError('reward_conflict',409)
                return receipt
            slot = db.execute('SELECT * FROM reward_attempts WHERE id=? AND owner=?',(attempt,owner)).fetchone()
            if not slot or slot['used'] or not slot['created_at'] <= occurred_at <= slot['expires_at']:
                raise CommerceError('invalid_reward_attempt',409)
            count = db.execute('SELECT COUNT(*) FROM rewards WHERE owner=? AND day=?',(owner,day)).fetchone()[0]
            if count >= 3:
                raise CommerceError('daily_reward_limit',409)
            db.execute('UPDATE reward_attempts SET used=1 WHERE id=?',(attempt,))
            db.execute('INSERT INTO rewards(id,owner,attempt,occurred_at,day,amount) VALUES(?,?,?,?,?,2)',
                       (receipt,owner,attempt,occurred_at,day))
            db.execute('UPDATE accounts SET revision=revision+1 WHERE id=?',(owner,))
            audit(db,'reward_confirmed',owner,receipt,now)
        return receipt

    def snapshot(self, principal):
        now = self.now()
        with self.db.transaction() as db:
            account = db.execute('SELECT revision FROM accounts WHERE id=?',(principal.owner,)).fetchone()
            rows = db.execute('SELECT * FROM purchases WHERE owner=? ORDER BY source',(principal.owner,)).fetchall()
            grants=[{'source':r['source'],'product':r['product'],
                'valid_from':r['valid_from'],'valid_until':r['valid_until'],
                'revoked':bool(r['revoked']),'items':list(PRODUCT_ITEMS[r['product']])} for r in rows]
            for r in db.execute('SELECT * FROM cycle_grants WHERE owner=? AND product IS NOT NULL ORDER BY source',(principal.owner,)):
                grants.append({'source':r['source'],'product':r['product'],'valid_from':r['valid_from'],
                    'valid_until':None,'revoked':bool(r['revoked']),'items':list(PRODUCT_ITEMS[r['product']])})
            # An ambiguous delivery stays assigned to its original installation.
            # Same-installation retries recover it; another device cannot double-credit it.
            db.execute('UPDATE rewards SET claimed_by=? WHERE owner=? AND acknowledged=0 AND claimed_by IS NULL',
                       (principal.device,principal.owner))
            rewards = db.execute('SELECT * FROM rewards WHERE owner=? AND acknowledged=0 AND claimed_by=? ORDER BY id',
                                 (principal.owner,principal.device)).fetchall()
            day = datetime.fromtimestamp(now,timezone.utc).date().isoformat()
            used = db.execute('SELECT COUNT(*) FROM rewards WHERE owner=? AND day=?',(principal.owner,day)).fetchone()[0]
            payload = {'version':1,'environment':self.settings.environment,'audience':self.settings.audience,
                'rewarded_used_today':used,
                'owner':principal.owner,'device':principal.device,'revision':account[0],
                'issued_at':now,'grants':grants,
                'rewards':[{'id':r['id'],'amount':r['amount'],'occurred_at':r['occurred_at'],'attempt':r['attempt']} for r in rewards]}
        return self.secrets.snapshot(payload)

    def acknowledge_reward(self, principal, receipt):
        bounded(receipt,80)
        with self.db.transaction() as db:
            row = db.execute('SELECT * FROM rewards WHERE id=?',(receipt,)).fetchone()
            if not row or row['owner'] != principal.owner or row['claimed_by'] != principal.device:
                raise CommerceError('reward_not_found',404)
            db.execute('UPDATE rewards SET acknowledged=1 WHERE id=?',(receipt,))
            audit(db,'reward_delivery_ack',principal.owner,receipt,self.now())
