"""Provider-authoritative billing periods; cosmetics have independent origins."""
from datetime import datetime
import re
from .config import CLUB
from .ledger import VerifiedPurchase,VerifiedCycle,VerifiedRevenue
from .security import CommerceError,uuid_value,bounded

def instant(value):
    try:
        parsed=datetime.fromisoformat(value.replace('Z','+00:00'))
        if parsed.tzinfo is None:raise ValueError()
        return int(parsed.timestamp())
    except (ValueError,AttributeError,TypeError):raise CommerceError('invalid_provider_response',502) from None

def money(value):
    try:
        currency=value['currencyCode']
        units=int(value.get('units','0'));nanos=value.get('nanos',0)
        if not re.fullmatch(r'[A-Z]{3}',currency) or type(nanos) is not int or abs(nanos)>=10**9:raise ValueError()
        return currency,units*10**9+nanos
    except (KeyError,ValueError,TypeError):raise CommerceError('invalid_provider_response',502) from None

def google_order(settings,data,proof,product,order_id):
    if data.get('purchaseToken')!=proof or data.get('orderId')!=order_id:
        raise CommerceError('order_binding_mismatch',502)
    rows=data.get('lineItems',[])
    if len(rows)!=1 or settings.google_products.get(rows[0].get('productId'))!=product:
        raise CommerceError('order_binding_mismatch',502)
    state=data.get('state')
    if state not in {'PENDING','PROCESSED','CANCELED','PENDING_REFUND','PARTIALLY_REFUNDED','REFUNDED'}:
        raise CommerceError('invalid_provider_response',502)
    at=instant(data['createTime']);authority=instant(data.get('lastEventTime') or data['createTime'])
    currency,gross=money(data['total'])
    proceeds=None
    if data.get('developerRevenueInBuyerCurrency'):
        c,proceeds=money(data['developerRevenueInBuyerCurrency'])
        if c!=currency:raise CommerceError('invalid_provider_response',502)
    revenue=VerifiedRevenue(bounded(order_id,256),at,currency,gross,proceeds,state,authority)
    cycle=None
    if product==CLUB and state not in {'PENDING','CANCELED'}:
        detail=rows[0].get('subscriptionDetails',{})
        if detail.get('basePlanId')!=settings.google_club_base_plan:
            raise CommerceError('unsupported_subscription_plan')
        cycle=VerifiedCycle(order_id,instant(detail.get('servicePeriodStartTime') or data['createTime']),state=='REFUNDED',authority)
    return cycle,revenue

def google_subscription(settings,data,cycle=None,revenue=None):
    if ('testPurchase' in data)!=(settings.environment!='production'):
        raise CommerceError('purchase_environment_mismatch')
    items=data.get('lineItems',[])
    if len(items)!=1 or settings.google_products.get(items[0].get('productId'))!=CLUB:
        raise CommerceError('unsupported_product')
    item=items[0]
    if (item.get('offerDetails',{}).get('basePlanId')!=settings.google_club_base_plan
        or 'autoRenewingPlan' not in item or item['autoRenewingPlan'].get('installmentDetails')):
        raise CommerceError('unsupported_subscription_plan')
    states={
        'SUBSCRIPTION_STATE_PENDING':'pending','SUBSCRIPTION_STATE_ACTIVE':'active',
        'SUBSCRIPTION_STATE_PAUSED':'paused','SUBSCRIPTION_STATE_IN_GRACE_PERIOD':'grace',
        'SUBSCRIPTION_STATE_ON_HOLD':'billing_retry','SUBSCRIPTION_STATE_CANCELED':'cancelled',
        'SUBSCRIPTION_STATE_EXPIRED':'expired','SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED':'pending_cancelled',
    }
    state=states.get(data.get('subscriptionState'))
    if state is None:raise CommerceError('invalid_provider_response',502)
    owner=uuid_value(data.get('externalAccountIdentifiers',{}).get('obfuscatedExternalAccountId'))
    start=instant(data['startTime']) if data.get('startTime') else 0
    end=instant(item['expiryTime']) if item.get('expiryTime') else start
    entitled=state in {'active','grace','cancelled'}
    if cycle and cycle.revoked:entitled=False
    return VerifiedPurchase(owner,CLUB,start,revoked=not entitled,valid_until=end,
        needs_ack=entitled and data.get('acknowledgementState')=='ACKNOWLEDGEMENT_STATE_PENDING',
        cycles=(cycle,) if cycle else (),revenue=(revenue,) if revenue else (),state=state)

def apple_subscription(settings,transaction,status=1,renewal=None,extra_cycles=(),extra_revenue=()):
    kind=getattr(transaction.type,'value',transaction.type)
    environment=getattr(transaction.environment,'value',transaction.environment)
    if (transaction.bundleId!=settings.apple_bundle or environment!=('Production' if settings.environment=='production' else 'Sandbox')):
        raise CommerceError('purchase_application_mismatch')
    if kind!='Auto-Renewable Subscription' or settings.apple_products.get(transaction.productId)!=CLUB or transaction.quantity!=1:
        raise CommerceError('unsupported_product')
    if getattr(transaction.inAppOwnershipType,'value',transaction.inAppOwnershipType)!='PURCHASED':
        raise CommerceError('unsupported_purchase')
    owner=uuid_value(transaction.appAccountToken)
    if type(transaction.purchaseDate) is not int or type(transaction.expiresDate) is not int:
        raise CommerceError('invalid_provider_response',502)
    start,end=transaction.purchaseDate//1000,transaction.expiresDate//1000
    if end<start or start<0:raise CommerceError('invalid_provider_response',502)
    revoked=transaction.revocationDate is not None
    status=getattr(status,'value',status)
    if status not in {1,2,3,4,5}:raise CommerceError('invalid_provider_response',502)
    state={1:'active',2:'expired',3:'billing_retry',4:'grace',5:'revoked'}[status]
    if renewal:
        if renewal.originalTransactionId!=transaction.originalTransactionId:
            raise CommerceError('order_binding_mismatch',502)
        if status==4 and type(renewal.gracePeriodExpiresDate) is int:
            end=max(end,renewal.gracePeriodExpiresDate//1000)
        if status==1 and getattr(renewal.autoRenewStatus,'value',renewal.autoRenewStatus)==0:state='cancelled'
    cycle=VerifiedCycle(str(transaction.transactionId),start,revoked,
        (getattr(transaction,'signedDate',None) or transaction.purchaseDate)//1000)
    revenue=list(extra_revenue)
    price=getattr(transaction,'price',None);currency=getattr(transaction,'currency',None)
    if type(price) is int and isinstance(currency,str):
        revenue.append(VerifiedRevenue(cycle.id,start,currency,price*1000000,None,'REFUNDED' if revoked else 'PROCESSED',cycle.authority_at))
    return VerifiedPurchase(owner,CLUB,start,revoked=revoked or status not in {1,4},valid_until=end,
        cycles=tuple({c.id:c for c in (*extra_cycles,cycle)}.values()),revenue=tuple({r.id:r for r in revenue}.values()),state=state)
