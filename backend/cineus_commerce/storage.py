"""SQLite authority for a single service instance; WAL + immediate transactions.

Never deploy this database on an ephemeral filesystem or share it over NFS.
"""
from contextlib import contextmanager
from pathlib import Path
import sqlite3
import hashlib
import time
from .config import Settings
from .security import CommerceError

SCHEMA = '''
CREATE TABLE IF NOT EXISTS metadata(key TEXT PRIMARY KEY, value TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS accounts(
 id TEXT PRIMARY KEY, recovery_hash TEXT NOT NULL, revision INTEGER NOT NULL DEFAULT 0,
 created_at INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS devices(
 id TEXT PRIMARY KEY, owner TEXT NOT NULL REFERENCES accounts(id), token_hash TEXT NOT NULL UNIQUE,
 expires_at INTEGER NOT NULL, revoked INTEGER NOT NULL DEFAULT 0);
CREATE TABLE IF NOT EXISTS purchases(
 source TEXT PRIMARY KEY, owner TEXT NOT NULL REFERENCES accounts(id), platform TEXT NOT NULL,
 product TEXT NOT NULL, proof TEXT NOT NULL, valid_from INTEGER NOT NULL,
 valid_until INTEGER, revoked INTEGER NOT NULL, sequence INTEGER NOT NULL,
 observed_at INTEGER NOT NULL, needs_ack INTEGER NOT NULL DEFAULT 0);
CREATE TABLE IF NOT EXISTS verification_sequences(source TEXT PRIMARY KEY, value INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS cycle_grants(
 source TEXT PRIMARY KEY, owner TEXT NOT NULL REFERENCES accounts(id), platform TEXT NOT NULL,
 purchase_source TEXT NOT NULL REFERENCES purchases(source), product TEXT, cycle_month TEXT NOT NULL,
 valid_from INTEGER NOT NULL, revoked INTEGER NOT NULL, order_proof TEXT NOT NULL,
 observed_at INTEGER NOT NULL, authority_at INTEGER NOT NULL);
CREATE INDEX IF NOT EXISTS cycles_purchase ON cycle_grants(purchase_source);
CREATE TABLE IF NOT EXISTS cycle_polls(
 source TEXT PRIMARY KEY REFERENCES cycle_grants(source), attempted_at INTEGER NOT NULL,
 available_at INTEGER NOT NULL, failures INTEGER NOT NULL DEFAULT 0);
CREATE TABLE IF NOT EXISTS purchase_states(
 source TEXT PRIMARY KEY REFERENCES purchases(source), state TEXT NOT NULL, observed_at INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS financial_orders(
 source TEXT PRIMARY KEY, owner TEXT NOT NULL REFERENCES accounts(id), platform TEXT NOT NULL,
 product TEXT NOT NULL, purchased_at INTEGER NOT NULL, currency TEXT NOT NULL,
 gross_nanos INTEGER NOT NULL, proceeds_nanos INTEGER, state TEXT NOT NULL, observed_at INTEGER NOT NULL, authority_at INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS provider_polls(
 source TEXT PRIMARY KEY REFERENCES purchases(source), attempted_at INTEGER NOT NULL,
 available_at INTEGER NOT NULL, failures INTEGER NOT NULL DEFAULT 0);
CREATE TABLE IF NOT EXISTS provider_events(
 platform TEXT NOT NULL, event_id TEXT NOT NULL, payload TEXT NOT NULL, digest TEXT NOT NULL,
 received_at INTEGER NOT NULL, completed INTEGER NOT NULL DEFAULT 0,
 attempts INTEGER NOT NULL DEFAULT 0, last_error TEXT, PRIMARY KEY(platform,event_id));
CREATE TABLE IF NOT EXISTS reward_attempts(
 id TEXT PRIMARY KEY, owner TEXT NOT NULL REFERENCES accounts(id), device TEXT NOT NULL,
 created_at INTEGER NOT NULL, expires_at INTEGER NOT NULL, used INTEGER NOT NULL DEFAULT 0);
CREATE TABLE IF NOT EXISTS rewards(
 id TEXT PRIMARY KEY, owner TEXT NOT NULL REFERENCES accounts(id), attempt TEXT NOT NULL UNIQUE,
 occurred_at INTEGER NOT NULL, day TEXT NOT NULL, amount INTEGER NOT NULL CHECK(amount=2),
 claimed_by TEXT, acknowledged INTEGER NOT NULL DEFAULT 0);
CREATE INDEX IF NOT EXISTS rewards_owner_day ON rewards(owner,day);
CREATE TABLE IF NOT EXISTS rate_limits(bucket TEXT PRIMARY KEY, started INTEGER NOT NULL, count INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS audit(
 id INTEGER PRIMARY KEY AUTOINCREMENT, occurred_at INTEGER NOT NULL, action TEXT NOT NULL,
 owner TEXT, reference TEXT);
'''

class Database:
    def __init__(self, settings: Settings):
        self.path = Path(settings.database)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with self.connection() as db:
            db.execute('PRAGMA journal_mode=WAL')
            db.executescript(SCHEMA)
        with self.transaction() as db:
            schema=db.execute("SELECT value FROM metadata WHERE key='schema'").fetchone()
            if schema and schema[0] not in {'1','2'}:
                raise ValueError('Unsupported database schema')
            db.execute("INSERT OR REPLACE INTO metadata VALUES('schema','2')")
            for key, expected in [('environment', settings.environment),
                ('hash_key_fingerprint',hashlib.sha256(settings.hash_key).hexdigest()),
                ('encryption_key_fingerprint',hashlib.sha256(settings.encryption_key).hexdigest()),
                ('google_package',settings.google_package),('apple_bundle',settings.apple_bundle)]:
                row = db.execute('SELECT value FROM metadata WHERE key=?', (key,)).fetchone()
                if row and row['value'] != expected:
                    raise ValueError('Database environment/schema mismatch')
                db.execute('INSERT OR IGNORE INTO metadata VALUES(?,?)', (key, expected))
        self.path.chmod(0o600)

    @contextmanager
    def connection(self):
        db = sqlite3.connect(self.path, timeout=10, isolation_level=None)
        db.row_factory = sqlite3.Row
        db.execute('PRAGMA foreign_keys=ON')
        db.execute('PRAGMA synchronous=FULL')
        try:
            yield db
        finally:
            db.close()

    @contextmanager
    def transaction(self):
        with self.connection() as db:
            db.execute('BEGIN IMMEDIATE')
            try:
                yield db
                db.execute('COMMIT')
            except BaseException:
                db.execute('ROLLBACK')
                raise

    def rate_limit(self, bucket, limit, seconds, now):
        rejected = False
        with self.transaction() as db:
            db.execute('DELETE FROM rate_limits WHERE started < ?', (now - 86400,))
            row = db.execute('SELECT * FROM rate_limits WHERE bucket=?', (bucket,)).fetchone()
            if not row or row['started'] + seconds <= now:
                db.execute('INSERT OR REPLACE INTO rate_limits VALUES(?,?,1)', (bucket, now))
            elif row['count'] >= limit:
                rejected = True
            else:
                db.execute('UPDATE rate_limits SET count=count+1 WHERE bucket=?', (bucket,))
        if rejected:
            raise CommerceError('rate_limited', 429)

    def backup(self, destination):
        target = Path(destination)
        if target.resolve() == self.path.resolve() or target.exists():
            raise ValueError('Choose a new backup path')
        target.parent.mkdir(parents=True, exist_ok=True)
        with self.connection() as source:
            with sqlite3.connect(target) as backup:
                source.backup(backup)
                if backup.execute('PRAGMA integrity_check').fetchone()[0] != 'ok':
                    raise RuntimeError('Backup verification failed')
        target.chmod(0o600)

def audit(db, action, owner=None, reference=None, now=None):
    db.execute('INSERT INTO audit(occurred_at,action,owner,reference) VALUES(?,?,?,?)',
               (now if now is not None else int(time.time()), action, owner, reference))
