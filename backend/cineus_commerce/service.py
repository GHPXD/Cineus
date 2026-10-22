import json
from .ledger import Ledger
from .providers import GooglePlay, AppleStore, AdMobSSV
from .security import CommerceError, security_event
from .config import CLUB

class CommerceService:
    def __init__(self, settings, ledger=None, google=None, apple=None, admob=None):
        self.ledger = ledger or Ledger(settings)
        self.providers = {'google':google or GooglePlay(settings),'apple':apple or AppleStore(settings)}
        self.admob = admob or AdMobSSV(settings)

    def verify_purchase(self, platform, proof, expected_owner=None):
        source = self.ledger.source(platform,proof)
        if expected_owner:
            with self.ledger.db.connection() as db:
                old=db.execute('SELECT owner FROM purchases WHERE source=?',(source,)).fetchone()
                if old and old['owner']!=expected_owner:
                    raise CommerceError('proof_owner_mismatch',409)
        sequence = self.ledger.begin_verification(source)
        provider = self.providers[platform]
        try:
            result = provider.verify(proof)
        except Exception:
            self._poll_result(source,False)
            raise
        self.ledger.apply_purchase(platform,proof,sequence,result,expected_owner)
        self._poll_result(source,True)
        if result.needs_ack:
            # Grant commits first. A failed acknowledgement remains in the durable
            # outbox and is retried by reconciliation; it cannot lose the grant.
            try:
                provider.acknowledge(proof,result.product)
                with self.ledger.db.transaction() as db:
                    db.execute('UPDATE purchases SET needs_ack=0 WHERE source=? AND sequence=?',(source,sequence))
            except CommerceError:
                security_event('provider_ack_pending')
        return source

    def _poll_result(self, source, success):
        now=self.ledger.now()
        with self.ledger.db.transaction() as db:
            if not db.execute('SELECT 1 FROM purchases WHERE source=?',(source,)).fetchone():
                return
            previous=db.execute('SELECT failures FROM provider_polls WHERE source=?',(source,)).fetchone()
            failures=0 if success else (previous[0]+1 if previous else 1)
            delay=300 if success else min(3600,60*2**min(failures-1,6))
            db.execute('INSERT OR REPLACE INTO provider_polls VALUES(?,?,?,?)',(source,now,now+delay,failures))

    def notification(self, platform, event_id, timestamp, proof):
        if self.ledger.enqueue_event(platform,event_id,{'proof':proof},timestamp):
            self.process_event(platform,event_id,proof)

    def process_event(self, platform, event_id, proof):
        try:
            if proof is not None:
                token=proof['purchase_token'] if isinstance(proof,dict) else proof
                source=self.verify_purchase(platform,token)
                if isinstance(proof,dict) and platform=='google':
                    with self.ledger.db.connection() as db:
                        purchase=db.execute('SELECT owner,product FROM purchases WHERE source=?',(source,)).fetchone()
                    cycle,revenue=self.providers['google'].verify_order(token,proof['order_id'],purchase['product'])
                    if cycle:
                        self.ledger.apply_historical_cycle('google',token,cycle,revenue)
                    elif revenue:
                        with self.ledger.db.transaction() as db:
                            self.ledger._revenue(db,'google',purchase['owner'],purchase['product'],revenue,self.ledger.now())
            self.ledger.event_finished(platform,event_id)
        except CommerceError as error:
            self.ledger.event_finished(platform,event_id,error.code)
            raise
        except Exception:
            self.ledger.event_finished(platform,event_id,'processing_failed')
            raise CommerceError('processing_failed',503) from None

    def reconcile(self, owner=None, limit=100):
        # Operation is bounded; schedule repeatedly for larger ledgers.
        with self.ledger.db.connection() as db:
            if owner:
                rows = db.execute('SELECT * FROM purchases WHERE owner=? ORDER BY observed_at LIMIT ?',
                                  (owner,limit)).fetchall()
                events = []
            else:
                rows = db.execute('''SELECT p.* FROM purchases p LEFT JOIN provider_polls q ON p.source=q.source
                    WHERE q.available_at IS NULL OR q.available_at<=?
                    ORDER BY COALESCE(q.attempted_at,0),p.observed_at LIMIT ?''',(self.ledger.now(),limit)).fetchall()
                events = db.execute('SELECT * FROM provider_events WHERE completed=0 ORDER BY attempts,received_at LIMIT ?',
                                    (limit,)).fetchall()
            cycles=db.execute('''SELECT c.*,p.proof FROM cycle_grants c JOIN purchases p ON p.source=c.purchase_source
                LEFT JOIN cycle_polls q ON q.source=c.source
                WHERE c.platform='google' AND (q.available_at IS NULL OR q.available_at<=?)
                AND (? IS NULL OR c.owner=?) ORDER BY COALESCE(q.attempted_at,0),c.observed_at LIMIT ?''',
                (self.ledger.now(),owner,owner,limit)).fetchall()
        succeeded = failed = 0
        for row in rows:
            try:
                self.verify_purchase(row['platform'],self.ledger.secrets.decrypt(row['proof']),owner)
                succeeded += 1
            except Exception:
                failed += 1
        for event in events:
            try:
                payload = json.loads(self.ledger.secrets.decrypt(event['payload']))
                self.process_event(event['platform'],event['event_id'],payload['proof'])
                succeeded += 1
            except Exception:
                failed += 1
        for row in cycles:
            try:
                token=self.ledger.secrets.decrypt(row['proof'])
                cycle,revenue=self.providers['google'].verify_order(token,self.ledger.secrets.decrypt(row['order_proof']),CLUB)
                if cycle:self.ledger.apply_historical_cycle('google',token,cycle,revenue)
                succeeded+=1
                success=True
            except Exception:
                failed+=1
                success=False
            # Separate poll rows have no purchase FK: cycle IDs are independent
            # origins, with the same bounded retry/backoff as purchase polling.
            self._cycle_poll_result(row['source'],success)
        return {'verified':succeeded,'pending':failed}

    def _cycle_poll_result(self,source,success):
        now=self.ledger.now()
        with self.ledger.db.transaction() as db:
            old=db.execute('SELECT failures FROM cycle_polls WHERE source=?',(source,)).fetchone()
            failures=0 if success else (old[0]+1 if old else 1)
            delay=300 if success else min(3600,60*2**min(failures-1,6))
            db.execute('INSERT OR REPLACE INTO cycle_polls VALUES(?,?,?,?)',(source,now,now+delay,failures))
