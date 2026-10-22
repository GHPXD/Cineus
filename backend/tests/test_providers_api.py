import base64
from dataclasses import replace
from types import SimpleNamespace
from urllib.parse import urlencode
import json
import time
import pytest
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import ec
from fastapi.testclient import TestClient
from appstoreserverlibrary.models.Environment import Environment
from appstoreserverlibrary.signed_data_verifier import SignedDataVerifier
from cineus_commerce.app import create_app
from cineus_commerce.config import PREMIERE
from cineus_commerce.ledger import VerifiedPurchase
from cineus_commerce.providers import GooglePlay, AppleStore, AdMobSSV
from cineus_commerce.security import CommerceError, b64, unb64
from cineus_commerce.service import CommerceService
from conftest import identity

def google_data(owner, state='PURCHASED'):
    return {'testPurchaseContext':{'fopType':'TEST'},'productLineItem':[{'productId':'premiere'}],
            'purchaseStateContext':{'purchaseState':state},'purchaseCompletionTime':'2026-10-14T00:00:00Z',
            'obfuscatedExternalAccountId':owner,'acknowledgementState':'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED'}

def apple_data(settings,owner):
    return SimpleNamespace(environment=Environment.SANDBOX,bundleId=settings.apple_bundle,
        productId='premiere',type='Non-Consumable',quantity=1,inAppOwnershipType='PURCHASED',
        appAccountToken=owner,purchaseDate=1791936000000,revocationDate=None,transactionId='123456')

@pytest.mark.parametrize('state,revoked',[('PURCHASED',False),('PENDING',True),('CANCELLED',True)])
def test_google_api_truth_and_account_binding(settings,credentials,state,revoked):
    purchase=GooglePlay(settings).decode(google_data(credentials['owner'],state))
    assert purchase.owner==credentials['owner'] and purchase.revoked is revoked

@pytest.mark.parametrize('change',[
    {'testPurchaseContext':None}, {'obfuscatedExternalAccountId':None},
    {'productLineItem':[{'productId':'wrong-app-product'}]},
    {'purchaseStateContext':{'purchaseState':'UNSPECIFIED'}},
    {'purchaseCompletionTime':None},
])
def test_google_rejects_unbound_environment_product_and_unknown_state(settings,credentials,change):
    with pytest.raises(CommerceError):
        GooglePlay(settings).decode({**google_data(credentials['owner']),**change})

def test_google_fetches_authoritative_endpoint_and_encodes_token(settings,credentials,monkeypatch):
    class Session:
        def __enter__(self): return self
        def __exit__(self,*args): pass
        def get(self,url,timeout):
            assert url.endswith('/purchases/productsv2/tokens/secret%2Ftoken%3Fredirect')
            assert url.startswith('https://androidpublisher.googleapis.com/') and timeout==12
            return SimpleNamespace(status_code=200,raise_for_status=lambda:None,json=lambda:google_data(credentials['owner']))
    provider=GooglePlay(settings)
    monkeypatch.setattr(provider,'_session',lambda:Session())
    assert provider.verify('secret/token?redirect').product==PREMIERE

@pytest.mark.parametrize('attribute,value',[
    ('bundleId','other.app'),('environment',Environment.PRODUCTION),('appAccountToken',None),
    ('type','Consumable'),('inAppOwnershipType','FAMILY_SHARED'),('quantity',2),
])
def test_apple_rejects_wrong_binding_and_product_type(settings,credentials,attribute,value):
    data=apple_data(settings,credentials['owner']); setattr(data,attribute,value)
    with pytest.raises(CommerceError): AppleStore(settings).decode(data)

def test_apple_revocation_and_cryptographic_verification_are_required(settings,credentials,monkeypatch):
    provider=AppleStore(settings)
    data=apple_data(settings,credentials['owner'])
    assert provider.decode(data).revoked is False
    data.revocationDate=1791936000000
    assert provider.decode(data).revoked is True
    provider.client=SimpleNamespace(get_transaction_info=lambda _:SimpleNamespace(signedTransactionInfo='e30.e30.invalid'))
    provider.verifier=SignedDataVerifier([],False,Environment.SANDBOX,settings.apple_bundle,None)
    monkeypatch.setattr(provider,'_ready',lambda:None)
    with pytest.raises(CommerceError): provider.verify('123456')

def ssv(ledger,principal,settings,clock,private=None,**changes):
    attempt=ledger.start_reward(principal)['attempt_id']
    fields={'ad_network':'test','ad_unit':'test-unit','custom_data':attempt,'reward_amount':'2',
            'reward_item':'tickets','timestamp':str(clock[0]*1000),'transaction_id':'one','user_id':principal.owner}
    fields.update(changes)
    signed=urlencode(sorted(fields.items()))
    private=private or ec.generate_private_key(ec.SECP256R1())
    sig=private.sign(signed.encode(),ec.ECDSA(hashes.SHA256()))
    verifier=AdMobSSV(settings,now=lambda:clock[0])
    verifier.keys={'1':private.public_key()}; verifier.fetched_at=clock[0]
    return verifier,(signed+'&signature='+b64(sig)+'&key_id=1').encode()

def test_admob_verifies_real_ecdsa_over_unmodified_query(ledger,principal,settings,clock):
    verifier,query=ssv(ledger,principal,settings,clock)
    verified=verifier.verify(query)
    receipt=ledger.confirm_reward(**verified)
    assert ledger.confirm_reward(**verified)==receipt
    with pytest.raises(CommerceError): verifier.verify(query.replace(b'reward_amount=2',b'reward_amount=9'))
    with pytest.raises(CommerceError): verifier.verify(query+b'&user_id=another')

@pytest.mark.parametrize('fields',[{'ad_unit':'other'},{'reward_item':'money'},{'reward_amount':'9'}])
def test_admob_rejects_validly_signed_wrong_placement_or_reward(ledger,principal,settings,clock,fields):
    verifier,query=ssv(ledger,principal,settings,clock,**fields)
    with pytest.raises(CommerceError): verifier.verify(query)

def test_callback_fails_then_replays_durably(ledger,principal,settings,clock):
    class Provider:
        failed=True
        def verify(self,proof):
            if self.failed: raise CommerceError('provider_unavailable',503)
            return VerifiedPurchase(principal.owner,PREMIERE,clock[0]-10)
    provider=Provider(); service=CommerceService(settings,ledger,google=provider)
    with pytest.raises(CommerceError): service.notification('google','event',clock[0],'proof')
    with ledger.db.connection() as db:
        event=db.execute('SELECT * FROM provider_events').fetchone()
        assert event['completed']==0 and event['attempts']==1 and 'proof' not in event['payload']
    provider.failed=False
    assert service.reconcile()['pending']==0
    service.notification('google','event',clock[0],'proof')
    assert len(json.loads(unb64(ledger.snapshot(principal)['payload']))['grants'])==1

def test_api_auth_payload_privilege_and_recovery(settings,ledger,credentials,clock):
    service=CommerceService(settings,ledger)
    client=TestClient(create_app(settings,service))
    assert client.get('/v1/snapshot').status_code==401
    response=client.post('/v1/identity',json=credentials)
    assert response.status_code==200
    assert 'signature' in response.json() and 'token' not in response.json()
    auth={'Authorization':'Bearer '+credentials['token']}
    assert client.get('/v1/snapshot',headers=auth).status_code==200
    malicious={**credentials,'verified':True,'token':'secret'}
    rejected=client.post('/v1/identity',json=malicious)
    assert rejected.status_code==400 and 'secret' not in rejected.text
    assert client.post('/v1/rewards/ack',headers=auth,json={'receipt_id':"' OR 1=1--"}).status_code==404
    assert client.get('/v1/snapshot',headers={**auth,'Origin':'https://attacker.test'}).headers.get('access-control-allow-origin') is None
    assert client.get('/health').headers['x-content-type-options']=='nosniff'
    too_big=client.post('/v1/identity',content=b'x'*65537)
    assert too_big.status_code==413 and too_big.headers['cache-control']=='no-store'

def test_api_registration_bruteforce_limit_and_environment_default_closed(settings,ledger):
    client=TestClient(create_app(settings,CommerceService(settings,ledger)))
    for _ in range(10): assert client.post('/v1/identity',json=identity()).status_code==200
    assert client.post('/v1/identity',json=identity()).status_code==429
    unconfigured=replace(settings,google_products={},admob_units=())
    with pytest.raises(CommerceError): GooglePlay(unconfigured).verify('proof')
    with pytest.raises(CommerceError): AdMobSSV(unconfigured).verify(b'')

def test_google_notification_oidc_and_subscription_are_checked(settings,credentials,monkeypatch,clock):
    s=replace(settings,google_push_audience='https://server.test/callbacks/google',
        google_push_email='push@test.iam.gserviceaccount.com',google_subscription='projects/p/subscriptions/s')
    from cineus_commerce import providers
    claims={'iss':'https://accounts.google.com','email':s.google_push_email,'email_verified':True}
    monkeypatch.setattr(providers.id_token,'verify_oauth2_token',lambda *a,**k:claims)
    message={'packageName':s.google_package,'eventTimeMillis':str(clock[0]*1000),
             'oneTimeProductNotification':{'purchaseToken':'proof'}}
    body={'subscription':s.google_subscription,'message':{'messageId':'1','data':base64.b64encode(json.dumps(message).encode()).decode()}}
    assert GooglePlay(s).notification('jwt',body)[2]=='proof'
    claims['email']='other@test.iam.gserviceaccount.com'
    with pytest.raises(CommerceError): GooglePlay(s).notification('jwt',body)

def test_failed_poll_does_not_starve_other_transactions(ledger,principal,settings,clock):
    for proof in ['a','b']:
        source=ledger.source('google',proof)
        ledger.apply_purchase('google',proof,ledger.begin_verification(source),
            VerifiedPurchase(principal.owner,PREMIERE,clock[0]-10))
    seen=[]
    class Provider:
        def verify(self,proof):
            seen.append(proof)
            raise CommerceError('temporary',503)
    service=CommerceService(settings,ledger,google=Provider())
    service.reconcile(limit=1); service.reconcile(limit=1)
    assert set(seen)=={'a','b'}
