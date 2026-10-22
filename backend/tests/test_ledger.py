from concurrent.futures import ThreadPoolExecutor
from dataclasses import replace
import base64
import json
import sqlite3
import uuid
import pytest
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey
from cineus_commerce.config import PREMIERE, PLUS, Settings
from cineus_commerce.ledger import Ledger, VerifiedPurchase
from cineus_commerce.security import CommerceError, unb64
from conftest import identity

def payload(ledger,principal):
    envelope=ledger.snapshot(principal)
    ledger.secrets.signer.public_key().verify(unb64(envelope['signature']),unb64(envelope['payload']))
    return json.loads(unb64(envelope['payload']))

def apply(ledger,owner,proof,revoked=False,product=PREMIERE):
    source=ledger.source('google',proof)
    seq=ledger.begin_verification(source)
    ledger.apply_purchase('google',proof,seq,VerifiedPurchase(owner,product,ledger.now()-10,revoked=revoked),owner)
    return source

def test_identity_idempotency_authentication_and_no_plaintext(ledger,credentials,principal):
    assert ledger.register(**credentials)==principal
    assert ledger.authenticate(credentials['token'])==principal
    with ledger.db.connection() as db:
        assert db.execute('SELECT COUNT(*) FROM accounts').fetchone()[0]==1
        serialized=str([tuple(r) for r in db.execute('SELECT * FROM devices')])
    assert credentials['token'] not in serialized
    with pytest.raises(CommerceError):
        ledger.register(**{**credentials,'token':identity()['token']})
    with pytest.raises(CommerceError): ledger.authenticate('invalid')

def test_expiry_recovery_revokes_old_device_without_moving_ambiguous_credit(ledger,credentials,principal,clock):
    attempt=ledger.start_reward(principal)
    receipt=ledger.confirm_reward('event',attempt['attempt_id'],principal.owner,clock[0])
    assert payload(ledger,principal)['rewards'][0]['id']==receipt
    new=identity()
    recovered=ledger.recover(principal.owner,credentials['recovery'],new['device'],new['token'])
    with pytest.raises(CommerceError): ledger.authenticate(credentials['token'])
    assert ledger.authenticate(new['token'])==recovered
    assert payload(ledger,recovered)['rewards']==[]
    with pytest.raises(CommerceError): ledger.acknowledge_reward(recovered,receipt)
    clock[0]+=91*86400
    with pytest.raises(CommerceError): ledger.authenticate(new['token'])

def test_purchase_replay_is_idempotent_and_proof_encrypted(ledger,principal):
    source=apply(ledger,principal.owner,'secret-provider-token')
    revision=payload(ledger,principal)['revision']
    for _ in range(3): apply(ledger,principal.owner,'secret-provider-token')
    result=payload(ledger,principal)
    assert result['revision']==revision and len(result['grants'])==1
    assert len(result['grants'][0]['items'])==6
    with ledger.db.connection() as db:
        row=db.execute('SELECT * FROM purchases WHERE source=?',(source,)).fetchone()
        assert 'secret-provider-token' not in row['proof']
        assert ledger.secrets.decrypt(row['proof'])=='secret-provider-token'

def test_cross_owner_receipt_theft_is_rejected(ledger,principal):
    other=identity(); ledger.register(**other)
    source=ledger.source('google','proof')
    sequence=ledger.begin_verification(source)
    with pytest.raises(CommerceError):
        ledger.apply_purchase('google','proof',sequence,VerifiedPurchase(principal.owner,PREMIERE,ledger.now()),other['owner'])
    assert payload(ledger,principal)['grants']==[]

def test_revocation_preserves_another_origin_and_plus(ledger,principal):
    apply(ledger,principal.owner,'origin-one')
    apply(ledger,principal.owner,'origin-two')
    apply(ledger,principal.owner,'plus',product=PLUS)
    apply(ledger,principal.owner,'origin-one',revoked=True)
    grants=payload(ledger,principal)['grants']
    assert sum(g['revoked'] for g in grants)==1
    assert sum(not g['revoked'] for g in grants if g['product']==PREMIERE)==1
    assert next(g for g in grants if g['product']==PLUS)['revoked'] is False

def test_out_of_order_inflight_verification_cannot_restore_refund(ledger,principal):
    source=apply(ledger,principal.owner,'proof')
    older=ledger.begin_verification(source)
    newer=ledger.begin_verification(source)
    ledger.apply_purchase('google','proof',newer,VerifiedPurchase(principal.owner,PREMIERE,1,True))
    ledger.apply_purchase('google','proof',older,VerifiedPurchase(principal.owner,PREMIERE,1,False))
    assert payload(ledger,principal)['grants'][0]['revoked'] is True

def test_transaction_failure_rolls_back_grant_and_revision(ledger,principal):
    with ledger.db.connection() as db:
        db.execute("CREATE TRIGGER fail_audit BEFORE INSERT ON audit BEGIN SELECT RAISE(ABORT,'simulated disk failure'); END")
    with pytest.raises(sqlite3.IntegrityError): apply(ledger,principal.owner,'proof')
    assert payload(ledger,principal)['grants']==[]
    assert payload(ledger,principal)['revision']==0

def test_reward_signature_callback_repeats_and_daily_cap(ledger,principal,clock):
    for i in range(3):
        attempt=ledger.start_reward(principal)
        receipt=ledger.confirm_reward(str(i),attempt['attempt_id'],principal.owner,clock[0])
        assert ledger.confirm_reward(str(i),attempt['attempt_id'],principal.owner,clock[0])==receipt
    with pytest.raises(CommerceError): ledger.start_reward(principal)
    assert len(payload(ledger,principal)['rewards'])==3
    clock[0]+=86400
    assert ledger.start_reward(principal)['amount']==2

def test_concurrent_duplicate_callback_commits_one_reward(ledger,principal,clock):
    attempt=ledger.start_reward(principal)['attempt_id']
    with ThreadPoolExecutor(max_workers=6) as pool:
        result=list(pool.map(lambda _:ledger.confirm_reward('same-event',attempt,principal.owner,clock[0]),range(12)))
    assert len(set(result))==1
    assert len(payload(ledger,principal)['rewards'])==1

def test_acked_delivery_not_sent_again_and_identity_is_required(ledger,principal,clock):
    attempt=ledger.start_reward(principal)['attempt_id']
    receipt=ledger.confirm_reward('one',attempt,principal.owner,clock[0])
    assert len(payload(ledger,principal)['rewards'])==1
    ledger.acknowledge_reward(principal,receipt)
    ledger.acknowledge_reward(principal,receipt)
    assert payload(ledger,principal)['rewards']==[]

def test_notification_deduplication_conflict_and_window(ledger,clock):
    assert ledger.enqueue_event('google','one',{'proof':'a'},clock[0])
    ledger.event_finished('google','one')
    assert not ledger.enqueue_event('google','one',{'proof':'a'},clock[0])
    with pytest.raises(CommerceError): ledger.enqueue_event('google','one',{'proof':'b'},clock[0])
    for stamp in [clock[0]+301,clock[0]-31*86400]:
        with pytest.raises(CommerceError): ledger.enqueue_event('google','old',{},stamp)

def test_backup_reopen_and_environment_separation(ledger,principal,settings,tmp_path):
    apply(ledger,principal.owner,'proof')
    backup=tmp_path/'snapshot.sqlite'
    ledger.db.backup(backup)
    restored=Ledger(replace(settings,database=backup),now=ledger.now)
    assert len(payload(restored,principal)['grants'])==1
    with pytest.raises(ValueError): Ledger(replace(settings,environment='production'))

def test_session_rotation_keeps_installation_and_pending_reward_delivery(ledger,credentials,principal,clock):
    attempt=ledger.start_reward(principal)['attempt_id']
    receipt=ledger.confirm_reward('event',attempt,principal.owner,clock[0])
    assert payload(ledger,principal)['rewards']
    fresh=identity()['token']
    renewed=ledger.recover(principal.owner,credentials['recovery'],principal.device,fresh)
    assert renewed==principal
    with pytest.raises(CommerceError): ledger.authenticate(credentials['token'])
    assert ledger.authenticate(fresh)==principal
    assert payload(ledger,renewed)['rewards'][0]['id']==receipt
    assert ledger.recover(principal.owner,credentials['recovery'],principal.device,fresh)==principal
