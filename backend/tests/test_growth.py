import base64
import json
import secrets
import zlib
from dataclasses import replace
from concurrent.futures import ThreadPoolExecutor
import pytest
from conftest import identity
from cineus_commerce.growth import Growth
from cineus_commerce.security import CommerceError
from cineus_commerce.ledger import VerifiedPurchase,Ledger
from cineus_commerce.config import TICKET_PRODUCTS

def decoded(envelope):
    return json.loads(base64.urlsafe_b64decode(envelope['payload']+'='*(-len(envelope['payload'])%4)))

def call(growth,p,action,data=None):
    nonce=secrets.token_urlsafe(32)
    payload=decoded(growth.command(p,action,nonce,data or {}))
    assert payload['nonce']==nonce and payload['owner']==p.owner
    assert payload['device']==p.device and payload['action']==action
    return payload['data']

def test_nonce_scope_and_safe_remote_parameters(ledger,principal):
    growth=Growth(ledger)
    value=call(growth,principal,'bootstrap')
    assert value['stage_bonus']==10 and value['daily_tickets']==10
    assert call(growth,principal,'bootstrap')==value
    with pytest.raises(CommerceError): call(growth,principal,'bootstrap',{'stage_bonus':0})
    with pytest.raises(CommerceError): growth.command(principal,'bootstrap','bad',{})
    with pytest.raises(ValueError):replace(ledger.settings,economy_rollout_percent=101)

def test_opt_in_idempotent_events_and_erasure(ledger,principal,clock):
    growth=Growth(ledger)
    event={'id':'a','event':'game_completed','occurred_at':clock[0],
      'properties':{'mode':'poster','kind':'stage','score':5,'outcome':'won'}}
    with pytest.raises(CommerceError):call(growth,principal,'events',{'events':[event]})
    call(growth,principal,'consent',{'enabled':True})
    for _ in range(2):call(growth,principal,'events',{'events':[event]})
    with ledger.db.connection() as db:assert db.execute('SELECT COUNT(*) FROM analytics_events').fetchone()[0]==1
    with pytest.raises(CommerceError):call(growth,principal,'events',{'events':[{**event,'properties':{'guess':'secret'}}]})
    with pytest.raises(CommerceError):call(growth,principal,'events',{'events':[event]*51})
    call(growth,principal,'consent',{'enabled':False})
    with ledger.db.connection() as db:assert db.execute('SELECT COUNT(*) FROM analytics_events').fetchone()[0]==0

def test_backup_ownership_cas_encryption_and_forbidden_tables(ledger,principal):
    growth=Growth(ledger)
    def packed(tables):return base64.b64encode(zlib.compress(json.dumps({'version':1,'tables':tables}).encode())).decode()
    payload=packed({'game_sessions':[]})
    assert call(growth,principal,'backup_put',{'revision':0,'payload':payload})['revision']==1
    with ledger.db.connection() as db:
        assert payload not in db.execute('SELECT payload FROM player_backups').fetchone()[0]
    assert call(growth,principal,'backup_get')['payload']==payload
    with pytest.raises(CommerceError,match='backup_conflict'):call(growth,principal,'backup_put',{'revision':0,'payload':payload})
    other=ledger.register(**identity())
    assert call(growth,other,'backup_get')['payload'] is None
    for table in ['player_tickets','purchases','collection_ownership','devices']:
        with pytest.raises(CommerceError):call(growth,principal,'backup_put',{'revision':1,'payload':packed({table:[]})})
    bomb=base64.b64encode(zlib.compress(b' '* (4*1024*1024+1))).decode()
    with pytest.raises(CommerceError):call(growth,principal,'backup_put',{'revision':1,'payload':bomb})
    for value in [[],None,'not an object']:
        malformed=base64.b64encode(zlib.compress(json.dumps(value).encode())).decode()
        with pytest.raises(CommerceError):call(growth,principal,'backup_put',{'revision':1,'payload':malformed})
    call(growth,principal,'backup_delete')
    assert call(growth,principal,'backup_get')['revision']==0


def test_worker_retention_does_not_require_another_upload(ledger,principal,clock):
    growth=Growth(ledger)
    call(growth,principal,'consent',{'enabled':True})
    call(growth,principal,'events',{'events':[{'id':'old','event':'app_active',
      'occurred_at':clock[0],'properties':{}}]})
    clock[0]+=60*86400+1
    growth.prune()
    with ledger.db.connection() as db:
        assert db.execute('SELECT COUNT(*) FROM analytics_events').fetchone()[0]==0
        assert db.execute('SELECT enabled FROM analytics_consent WHERE owner=?',(principal.owner,)).fetchone()[0]==1

def test_private_async_game_only_guest_can_submit_no_overwrite(ledger,principal,clock):
    growth=Growth(ledger);guest=ledger.register(**identity());stranger=ledger.register(**identity())
    value=call(growth,principal,'friend_create',{'mode':'poster','movie':1,'score':5});code=value['code']
    with pytest.raises(CommerceError):call(growth,principal,'friend_join',{'code':code})
    assert call(growth,guest,'friend_join',{'code':code})['movie']==1
    with pytest.raises(CommerceError):call(growth,stranger,'friend_join',{'code':code})
    with pytest.raises(CommerceError):call(growth,stranger,'friend_score',{'code':code,'score':5})
    for _ in range(2):call(growth,guest,'friend_score',{'code':code,'score':3})
    with pytest.raises(CommerceError):call(growth,guest,'friend_score',{'code':code,'score':4})
    row=call(growth,principal,'friend_list')['games'][0]
    assert row['guest_score']==3 and row['ranked'] is False and 'owner' not in row
    clock[0]+=7*86400+1
    with pytest.raises(CommerceError):call(growth,guest,'friend_join',{'code':code})

def test_wallet_authority_duplicates_rollback_refund_and_recovery(ledger,principal,credentials):
    growth=Growth(ledger);product=next(iter(TICKET_PRODUCTS))
    assert call(growth,principal,'wallet')['balance']==0
    proof='verified-token';source=ledger.source('google',proof)
    for _ in range(2):ledger.apply_purchase('google',proof,ledger.begin_verification(source),VerifiedPurchase(principal.owner,product,ledger.now()))
    assert call(growth,principal,'wallet')['balance']==20
    def reserve():return call(growth,principal,'wallet_reserve',{'operation':'same','amount':10})
    with ThreadPoolExecutor(2) as pool:assert all(r['balance']==10 for r in pool.map(lambda _:reserve(),range(2)))
    call(growth,principal,'wallet_commit',{'operation':'same'})
    with pytest.raises(CommerceError):call(growth,principal,'wallet_refund',{'operation':'same'})
    call(growth,principal,'wallet_reserve',{'operation':'cancel','amount':5})
    for _ in range(2):call(growth,principal,'wallet_refund',{'operation':'cancel'})
    assert call(growth,principal,'wallet')['balance']==10
    other=identity();recovered=ledger.recover(principal.owner,credentials['recovery'],other['device'],other['token'])
    assert call(growth,recovered,'wallet')['balance']==10
    ledger.apply_purchase('google',proof,ledger.begin_verification(source),VerifiedPurchase(principal.owner,product,ledger.now(),revoked=True))
    assert call(growth,recovered,'wallet')['balance']==0
    with pytest.raises(CommerceError):call(growth,recovered,'wallet_reserve',{'operation':'overdraft','amount':1})

def test_feedback_is_bounded_and_encrypted(ledger,principal):
    growth=Growth(ledger)
    data={'id':'1','mode':'colors','category':'artwork','movie_id':None,'question':'q1','note':'Fix this'}
    call(growth,principal,'feedback',data)
    with ledger.db.connection() as db:assert 'Fix this' not in db.execute('SELECT payload FROM editorial_feedback').fetchone()[0]
    with pytest.raises(CommerceError):call(growth,principal,'feedback',{**data,'note':'x'*501})


def test_backup_status_is_private_metadata_without_progress_payload(ledger,principal):
    growth=Growth(ledger)
    assert call(growth,principal,'backup_status')=={'revision':0,'updated_at':None}
    payload=base64.b64encode(zlib.compress(json.dumps({'version':1,'tables':{}}).encode())).decode()
    call(growth,principal,'backup_put',{'revision':0,'payload':payload})
    assert call(growth,principal,'backup_status')=={'revision':1,'updated_at':ledger.now()}
    other=ledger.register(**identity())
    assert call(growth,other,'backup_status')=={'revision':0,'updated_at':None}
    with pytest.raises(CommerceError):call(growth,other,'backup_status',{'owner':principal.owner})
    call(growth,principal,'consent',{'enabled':True})
    call(growth,principal,'events',{'events':[{'id':'native','event':'ad_shown','occurred_at':ledger.now(),
      'properties':{'placement':'native'}}]})
