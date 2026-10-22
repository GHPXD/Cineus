from dataclasses import replace
from datetime import datetime,timezone
from types import SimpleNamespace as Object
import pytest
from cineus_commerce.config import CLUB,NIGHT,CITY,PLUS
from cineus_commerce.ledger import Ledger,VerifiedPurchase,VerifiedCycle,VerifiedRevenue
from cineus_commerce.subscriptions import google_subscription,google_order,apple_subscription
from cineus_commerce.security import CommerceError
from cineus_commerce.service import CommerceService
from cineus_commerce.providers import AppleStore,GooglePlay
from cineus_commerce.reporting import report
from test_ledger import payload,apply

def stamp(date):return int(datetime.fromisoformat(date).replace(tzinfo=timezone.utc).timestamp())

@pytest.fixture
def club_settings(settings):
    return replace(settings,google_products={**settings.google_products,'club':CLUB},apple_products={**settings.apple_products,'club':CLUB},google_club_base_plan='monthly',club_calendar={'2026-10':NIGHT,'2026-11':CITY})

def google(owner,state='ACTIVE'):
    return {'testPurchase':{},'externalAccountIdentifiers':{'obfuscatedExternalAccountId':owner},
        'subscriptionState':'SUBSCRIPTION_STATE_'+state,'startTime':'2026-10-15T00:00:00Z',
        'acknowledgementState':'ACKNOWLEDGEMENT_STATE_PENDING',
        'lineItems':[{'productId':'club','expiryTime':'2026-11-15T00:00:00Z','offerDetails':{'basePlanId':'monthly'},'autoRenewingPlan':{'autoRenewEnabled':True}}]}

@pytest.mark.parametrize('state,active',[('ACTIVE',True),('CANCELED',True),('IN_GRACE_PERIOD',True),('ON_HOLD',False),('PAUSED',False),('EXPIRED',False),('PENDING',False),('PENDING_PURCHASE_CANCELED',False)])
def test_google_subscription_states(club_settings,credentials,state,active):
    result=google_subscription(club_settings,google(credentials['owner'],state))
    assert result.revoked is not active
    assert result.valid_until==stamp('2026-11-15')
    assert result.needs_ack is active

def test_google_plan_environment_owner_and_order_binding(club_settings,credentials):
    data=google(credentials['owner']);data['lineItems'][0]['offerDetails']['basePlanId']='annual'
    with pytest.raises(CommerceError):google_subscription(club_settings,data)
    data=google(credentials['owner']);data.pop('testPurchase')
    with pytest.raises(CommerceError):google_subscription(club_settings,data)
    data=google('not-a-uuid')
    with pytest.raises(CommerceError):google_subscription(club_settings,data)
    order={'purchaseToken':'token','orderId':'GPA.1..0','state':'PROCESSED','createTime':'2026-10-15T00:00:00Z','total':{'currencyCode':'BRL','units':'9','nanos':900000000},'lineItems':[{'productId':'club','subscriptionDetails':{'basePlanId':'monthly','servicePeriodStartTime':'2026-10-15T00:00:00Z'}}]}
    cycle,revenue=google_order(club_settings,order,'token',CLUB,'GPA.1..0')
    assert revenue.gross_nanos==9900000000 and cycle.starts_at==stamp('2026-10-15')
    with pytest.raises(CommerceError):google_order(club_settings,order,'stolen',CLUB,'GPA.1..0')
    assert google_order(club_settings,{**order,'state':'REFUNDED'},'token',CLUB,'GPA.1..0')[0].revoked

def apple(owner,**kwargs):
    return Object(bundleId='dev.cineus.cineus',environment='Sandbox',type='Auto-Renewable Subscription',productId='club',quantity=1,inAppOwnershipType='PURCHASED',appAccountToken=owner,purchaseDate=stamp('2026-10-15')*1000,expiresDate=stamp('2026-11-15')*1000,revocationDate=None,transactionId='1234',originalTransactionId='1234',signedDate=stamp('2026-10-15')*1000,price=9900,currency='BRL',**kwargs)

def test_apple_grace_cancel_expiry_and_refund(club_settings,credentials):
    transaction=apple(credentials['owner'])
    renewal=Object(originalTransactionId='1234',autoRenewStatus=0,gracePeriodExpiresDate=stamp('2026-11-18')*1000)
    cancelled=apple_subscription(club_settings,transaction,1,renewal)
    assert cancelled.state=='cancelled' and not cancelled.revoked
    grace=apple_subscription(club_settings,transaction,4,renewal)
    assert grace.valid_until==stamp('2026-11-18') and not grace.revoked
    expired=apple_subscription(club_settings,transaction,2)
    assert expired.revoked and not expired.cycles[0].revoked
    transaction.revocationDate=transaction.purchaseDate+1000
    assert apple_subscription(club_settings,transaction,5).cycles[0].revoked
    transaction.appAccountToken='other-owner'
    with pytest.raises(CommerceError):apple_subscription(club_settings,transaction)

def test_two_cycles_permanent_cosmetics_expiry_refund_and_plus(club_settings,credentials,clock,tmp_path):
    clock[0]=stamp('2026-11-16');ledger=Ledger(club_settings,now=lambda:clock[0]);principal=ledger.register(**credentials)
    apply(ledger,principal.owner,'plus',product=PLUS)
    def update(p):
        source=ledger.source('google','subscription-token');seq=ledger.begin_verification(source)
        ledger.apply_purchase('google','subscription-token',seq,p,principal.owner)
    first=VerifiedCycle('order-oct',stamp('2026-10-15'),authority_at=clock[0])
    second=VerifiedCycle('order-nov',stamp('2026-11-15'),authority_at=clock[0])
    p=VerifiedPurchase(principal.owner,CLUB,first.starts_at,valid_until=stamp('2026-12-15'),cycles=(first,second))
    update(p);revision=payload(ledger,principal)['revision'];update(p)
    assert payload(ledger,principal)['revision']==revision
    grants=payload(ledger,principal)['grants'];assert {g['product'] for g in grants}=={CLUB,PLUS,NIGHT,CITY}
    assert len([i for g in grants for i in g['items']])==14
    update(replace(p,revoked=True,state='expired'))
    grants=payload(ledger,principal)['grants'];assert all(not g['revoked'] and g['valid_until'] is None for g in grants if g['product']!=CLUB)
    refund=replace(first,revoked=True,authority_at=clock[0]+1)
    ledger.apply_historical_cycle('google','subscription-token',refund,None)
    ledger.apply_historical_cycle('google','subscription-token',first,None)
    grants=payload(ledger,principal)['grants'];assert next(g for g in grants if g['product']==NIGHT)['revoked']
    assert not next(g for g in grants if g['product']==CITY)['revoked']
    backup=tmp_path/'cycles.sqlite';ledger.db.backup(backup)
    restored=Ledger(replace(club_settings,database=backup),now=ledger.now)
    assert payload(restored,principal)['grants']==grants
    with restored.db.connection() as db:
        assert all('order-' not in r['order_proof'] for r in db.execute('SELECT order_proof FROM cycle_grants'))

def test_missing_content_preserves_obligation_and_historical_poll_backoff(club_settings,credentials,clock):
    clock[0]=stamp('2026-11-16');ledger=Ledger(club_settings,now=lambda:clock[0]);p=ledger.register(**credentials)
    cycle=VerifiedCycle('oct',stamp('2026-10-15'))
    class Provider:
        calls=0
        def verify(self,proof):return VerifiedPurchase(p.owner,CLUB,cycle.starts_at,valid_until=stamp('2026-12-15'),cycles=(cycle,))
        def verify_order(self,*args):self.calls+=1;raise CommerceError('unavailable',503)
    provider=Provider();service=CommerceService(club_settings,ledger=ledger,google=provider)
    service.verify_purchase('google','token',p.owner)
    assert service.reconcile()['pending']==1 and provider.calls==1
    assert service.reconcile()['pending']==0 and provider.calls==1
    clock[0]+=61
    assert service.reconcile()['pending']==1 and provider.calls==2

def test_financial_overflow_rolls_back_purchase(club_settings,credentials,clock):
    ledger=Ledger(club_settings,now=lambda:clock[0]);p=ledger.register(**credentials)
    source=ledger.source('google','proof');seq=ledger.begin_verification(source)
    with pytest.raises(CommerceError):ledger.apply_purchase('google','proof',seq,VerifiedPurchase(p.owner,PLUS,1,revenue=(VerifiedRevenue('order',1,'BRL',10**21),)))
    assert payload(ledger,p)['grants']==[]

def test_apple_adapter_recovers_two_history_cycles_and_checks_current_cancelled_status(club_settings,credentials):
    settings=replace(club_settings,apple_key_path='unused',apple_key_id='unused',apple_issuer='unused',apple_roots=('unused',))
    first=apple(credentials['owner']);second=apple(credentials['owner'])
    second.transactionId='1235';second.purchaseDate=stamp('2026-11-15')*1000;second.expiresDate=stamp('2026-12-15')*1000
    store=AppleStore(settings)
    class Client:
        def get_transaction_info(self,proof):return Object(signedTransactionInfo='old')
        def get_transaction_history(self,*args):return Object(signedTransactions=['old','new'],hasMore=False,revision='r1')
        def get_all_subscription_statuses(self,*args):return Object(data=[Object(lastTransactions=[Object(originalTransactionId='1234',signedTransactionInfo='new',signedRenewalInfo='renewal',status=1)])])
    class Verifier:
        def verify_and_decode_signed_transaction(self,value):return first if value=='old' else second
        def verify_and_decode_renewal_info(self,value):return Object(originalTransactionId='1234',autoRenewStatus=0)
    store.client=Client();store.verifier=Verifier()
    result=store.verify('1234')
    assert result.state=='cancelled' and not result.revoked
    assert {c.id for c in result.cycles}=={'1234','1235'}
    second.appAccountToken='00000000-0000-4000-8000-000000000001'
    with pytest.raises(CommerceError):store.verify('1234')

def test_schema_one_migrates_without_losing_purchase_and_report_is_aggregate(settings,credentials,clock):
    ledger=Ledger(settings,now=lambda:clock[0]);principal=ledger.register(**credentials)
    apply(ledger,principal.owner,'sensitive-token',product=PLUS)
    with ledger.db.connection() as db:
        for name in ['cycle_polls','cycle_grants','purchase_states','financial_orders']:db.execute('DROP TABLE '+name)
        db.execute("UPDATE metadata SET value='1' WHERE key='schema'")
    upgraded=Ledger(settings,now=ledger.now)
    assert len(payload(upgraded,principal)['grants'])==1
    result=report(upgraded)
    assert 'sensitive-token' not in str(result) and principal.owner not in str(result)
    assert result['ad_revenue'] is None and result['financial_by_platform_product_currency_state']==[]
