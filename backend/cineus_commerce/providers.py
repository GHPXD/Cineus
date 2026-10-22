"""Concrete provider verification. Client booleans and decoded-only JWTs are never proof."""
import base64
import json
from pathlib import Path
import re
import threading
import time
from urllib.parse import parse_qsl, quote
import requests
from dataclasses import replace
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from google.auth.transport.requests import AuthorizedSession, Request
from google.oauth2 import id_token, service_account
from appstoreserverlibrary.api_client import AppStoreServerAPIClient,GetTransactionHistoryVersion
from appstoreserverlibrary.models.TransactionHistoryRequest import TransactionHistoryRequest,ProductType
from appstoreserverlibrary.models.Environment import Environment
from appstoreserverlibrary.signed_data_verifier import SignedDataVerifier
from .config import Settings,CLUB,TICKET_PRODUCTS
from .ledger import VerifiedPurchase,VerifiedRevenue
from .security import CommerceError, bounded, uuid_value, security_event
from .subscriptions import google_subscription,google_order,apple_subscription

def epoch(text):
    from datetime import datetime
    try:
        return int(datetime.fromisoformat(text.replace('Z','+00:00')).timestamp())
    except (ValueError,TypeError,AttributeError):
        raise CommerceError('invalid_provider_response',502) from None

class GooglePlay:
    def __init__(self, settings: Settings):
        self.settings = settings

    def _session(self):
        if not self.settings.google_credentials or not self.settings.google_products:
            raise CommerceError('google_not_configured',503)
        credentials = service_account.Credentials.from_service_account_file(
            self.settings.google_credentials, scopes=['https://www.googleapis.com/auth/androidpublisher'])
        return AuthorizedSession(credentials,refresh_timeout=12,max_refresh_attempts=1)

    def verify(self, proof):
        bounded(proof)
        package = quote(self.settings.google_package,safe='')
        token = quote(proof,safe='')
        try:
            with self._session() as session:
                response = session.get(f'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{package}/purchases/productsv2/tokens/{token}',timeout=12)
                if response.status_code in {400,404} and CLUB in self.settings.google_products.values():
                    subscription=session.get(f'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{package}/purchases/subscriptionsv2/tokens/{token}',timeout=12)
                    subscription.raise_for_status()
                    data=subscription.json()
                    verified=google_subscription(self.settings,data)
                    order_id=data['lineItems'][0].get('latestSuccessfulOrderId')
                    if order_id:
                        cycle,revenue=self.verify_order(proof,order_id,CLUB)
                        verified=google_subscription(self.settings,data,cycle,revenue)
                    return verified
                if response.status_code == 404:
                    raise CommerceError('invalid_purchase',400)
                response.raise_for_status()
                data=response.json();verified=self.decode(data)
                if data.get('orderId'):
                    try:
                        _,revenue=self.verify_order(proof,data['orderId'],verified.product)
                        verified=replace(verified,revenue=(revenue,))
                    except CommerceError:security_event('order_reporting_pending')
                return verified
        except CommerceError:
            raise
        except Exception:
            # Provider exceptions can contain a purchase token in the URL.
            raise CommerceError('google_temporarily_unavailable',503) from None

    def verify_order(self,proof,order_id,product):
        try:
            bounded(order_id,256)
            with self._session() as session:
                response=session.get('https://androidpublisher.googleapis.com/androidpublisher/v3/applications/'
                    +quote(self.settings.google_package,safe='')+'/orders/'+quote(order_id,safe=''),timeout=12)
                response.raise_for_status()
                return google_order(self.settings,response.json(),proof,product,order_id)
        except CommerceError:raise
        except Exception:raise CommerceError('google_order_unavailable',503) from None

    def decode(self, data):
        if bool(data.get('testPurchaseContext')) != (self.settings.environment != 'production'):
            raise CommerceError('purchase_environment_mismatch')
        items = data.get('productLineItem',[])
        if len(items) != 1 or items[0].get('productId') not in self.settings.google_products:
            raise CommerceError('unsupported_product')
        if self.settings.google_products[items[0]['productId']]==CLUB:
            raise CommerceError('unsupported_product')
        state = data.get('purchaseStateContext',{}).get('purchaseState')
        if state not in {'PURCHASED','PENDING','CANCELLED','CANCELED'}:
            raise CommerceError('invalid_provider_response',502)
        offer = items[0].get('productOfferDetails',{})
        if offer.get('quantity',1) != 1 or offer.get('rentOfferDetails') is not None:
            raise CommerceError('unsupported_purchase')
        if (offer.get('consumptionState') == 'CONSUMPTION_STATE_CONSUMED' and
            self.settings.google_products[items[0]['productId']] not in TICKET_PRODUCTS):
            raise CommerceError('unsupported_purchase')
        owner = uuid_value(data.get('obfuscatedExternalAccountId'))
        revoked = state != 'PURCHASED' or offer.get('refundableQuantity') == 0
        completed = data.get('purchaseCompletionTime')
        if state == 'PURCHASED' and not completed:
            raise CommerceError('invalid_provider_response',502)
        return VerifiedPurchase(owner,self.settings.google_products[items[0]['productId']],
            epoch(completed) if completed else 0, revoked=revoked,
            needs_ack=state=='PURCHASED' and not revoked and data.get('acknowledgementState')=='ACKNOWLEDGEMENT_STATE_PENDING')

    def acknowledge(self, proof, product):
        store_id = next((k for k,v in self.settings.google_products.items() if v==product),None)
        if not store_id:
            raise CommerceError('unsupported_product')
        try:
            with self._session() as session:
                response = session.post('https://androidpublisher.googleapis.com/androidpublisher/v3/applications/'
                    + quote(self.settings.google_package,safe='') + '/purchases/products/' + quote(store_id,safe='')
                    + '/tokens/' + quote(proof,safe='') + ':acknowledge',json={},timeout=12) if product!=CLUB else session.post(
                    'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/'
                    +quote(self.settings.google_package,safe='')+'/purchases/subscriptions/'+quote(store_id,safe='')
                    +'/tokens/'+quote(proof,safe='')+':acknowledge',json={},timeout=12)
                response.raise_for_status()
        except Exception:
            raise CommerceError('google_ack_pending',503) from None

    def notification(self, bearer, body):
        s = self.settings
        if not all((s.google_push_audience,s.google_push_email,s.google_subscription)):
            raise CommerceError('google_push_not_configured',503)
        try:
            claims = id_token.verify_oauth2_token(bearer,Request(),audience=s.google_push_audience)
            if (claims.get('email') != s.google_push_email or claims.get('email_verified') is not True
                or claims.get('iss') not in {'accounts.google.com','https://accounts.google.com'}):
                raise ValueError()
        except Exception:
            raise CommerceError('invalid_provider_auth',401) from None
        try:
            if body['subscription'] != s.google_subscription:
                raise CommerceError('invalid_provider_auth',401)
            message = body['message']
            raw = base64.b64decode(message['data'],validate=True)
            if len(raw)>32768:
                raise ValueError()
            data = json.loads(raw)
            if data['packageName'] != s.google_package:
                raise CommerceError('purchase_application_mismatch')
            stamp = int(data['eventTimeMillis'])//1000
            if data.get('testNotification') is not None:
                return bounded(message['messageId'],256),stamp,None
            event = data.get('oneTimeProductNotification') or data.get('subscriptionNotification') or data.get('voidedPurchaseNotification')
            if not event:
                raise CommerceError('notification_not_supported',400)
            proof=bounded(event['purchaseToken'])
            if data.get('voidedPurchaseNotification') and event.get('orderId'):
                proof={'purchase_token':proof,'order_id':bounded(event['orderId'],256)}
            return bounded(message['messageId'],256),stamp,proof
        except CommerceError:
            raise
        except (ValueError,KeyError,TypeError):
            raise CommerceError() from None

class AppleStore:
    def __init__(self, settings: Settings):
        self.settings = settings
        self.client = self.verifier = None

    def _ready(self):
        s = self.settings
        if not all((s.apple_key_path,s.apple_key_id,s.apple_issuer,s.apple_roots,s.apple_products)):
            raise CommerceError('apple_not_configured',503)
        if s.environment == 'production' and not s.apple_app_id:
            raise CommerceError('apple_not_configured',503)
        if self.client is None:
            environment = Environment.PRODUCTION if s.environment=='production' else Environment.SANDBOX
            self.client = AppStoreServerAPIClient(Path(s.apple_key_path).read_bytes(),
                s.apple_key_id,s.apple_issuer,s.apple_bundle,environment)
            self.verifier = SignedDataVerifier([Path(p).read_bytes() for p in s.apple_roots],
                True,environment,s.apple_bundle,s.apple_app_id)

    def verify(self, proof):
        if not re.fullmatch(r'[0-9]{1,32}',str(proof)):
            raise CommerceError('invalid_purchase')
        self._ready()
        try:
            response = self.client.get_transaction_info(proof)
            transaction = self.verifier.verify_and_decode_signed_transaction(response.signedTransactionInfo)
            if str(transaction.transactionId) != proof:
                raise CommerceError('invalid_purchase')
            verified=self.decode(transaction)
            if verified.product==CLUB:
                cycles=list(verified.cycles);revenue=list(verified.revenue)
                revision=None
                for _ in range(10):
                    history=self.client.get_transaction_history(proof,revision,TransactionHistoryRequest(
                        productIds=[transaction.productId],productTypes=[ProductType.AUTO_RENEWABLE]),GetTransactionHistoryVersion.V2)
                    for signed in history.signedTransactions or []:
                        previous=self.verifier.verify_and_decode_signed_transaction(signed)
                        if previous.originalTransactionId!=transaction.originalTransactionId:continue
                        decoded=apple_subscription(self.settings,previous)
                        if decoded.owner!=verified.owner:raise CommerceError('order_binding_mismatch',502)
                        cycles.extend(decoded.cycles);revenue.extend(decoded.revenue)
                    if not history.hasMore:break
                    if not history.revision or history.revision==revision:raise CommerceError('invalid_provider_response',502)
                    revision=history.revision
                else:raise CommerceError('subscription_history_requires_review',503)
                status=self.client.get_all_subscription_statuses(proof)
                for group in status.data or []:
                    for item in group.lastTransactions or []:
                        if item.originalTransactionId!=transaction.originalTransactionId:continue
                        latest=self.verifier.verify_and_decode_signed_transaction(item.signedTransactionInfo)
                        renewal=self.verifier.verify_and_decode_renewal_info(item.signedRenewalInfo) if item.signedRenewalInfo else None
                        if latest.originalTransactionId!=transaction.originalTransactionId or uuid_value(latest.appAccountToken)!=verified.owner:
                            raise CommerceError('order_binding_mismatch',502)
                        return apple_subscription(self.settings,latest,item.status,renewal,cycles,revenue)
                raise CommerceError('subscription_status_unavailable',503)
            return verified
        except CommerceError:
            raise
        except Exception:
            raise CommerceError('apple_verification_failed',503) from None

    def decode(self, transaction):
        s = self.settings
        env = getattr(transaction.environment,'value',transaction.environment)
        expected = 'Production' if s.environment=='production' else 'Sandbox'
        if transaction.bundleId != s.apple_bundle or env != expected:
            raise CommerceError('purchase_application_mismatch')
        if transaction.productId not in s.apple_products:
            raise CommerceError('unsupported_product')
        kind = getattr(transaction.type,'value',transaction.type)
        ownership = getattr(transaction.inAppOwnershipType,'value',transaction.inAppOwnershipType)
        if self.settings.apple_products[transaction.productId]==CLUB:
            return apple_subscription(self.settings,transaction)
        expected_kind = 'Consumable' if s.apple_products[transaction.productId] in TICKET_PRODUCTS else 'Non-Consumable'
        if kind != expected_kind or transaction.quantity != 1 or ownership != 'PURCHASED':
            raise CommerceError('unsupported_purchase')
        if not isinstance(transaction.purchaseDate,int) or transaction.purchaseDate<0:
            raise CommerceError('invalid_provider_response',502)
        revoked=transaction.revocationDate is not None
        price=getattr(transaction,'price',None);currency=getattr(transaction,'currency',None)
        revenue=() if type(price) is not int or not isinstance(currency,str) else (
            VerifiedRevenue(str(transaction.transactionId),transaction.purchaseDate//1000,currency,price*1000000,
                state='REFUNDED' if revoked else 'PROCESSED',authority_at=(getattr(transaction,'signedDate',None) or transaction.purchaseDate)//1000),)
        return VerifiedPurchase(uuid_value(transaction.appAccountToken),s.apple_products[transaction.productId],
            transaction.purchaseDate//1000, revoked=revoked,revenue=revenue)

    def notification(self, signed_payload):
        self._ready()
        try:
            notification = self.verifier.verify_and_decode_notification(bounded(signed_payload,65536))
            stamp = notification.signedDate//1000
            if getattr(notification.notificationType,'value',notification.notificationType) == 'TEST':
                return bounded(notification.notificationUUID,256),stamp,None
            transaction = self.verifier.verify_and_decode_signed_transaction(notification.data.signedTransactionInfo)
            self.decode(transaction)  # Application, environment, type and binding checked twice.
            return bounded(notification.notificationUUID,256),stamp,str(transaction.transactionId)
        except CommerceError:
            raise
        except Exception:
            raise CommerceError('invalid_provider_auth',401) from None

class AdMobSSV:
    KEYS_URL = 'https://www.gstatic.com/admob/reward/verifier-keys.json'
    def __init__(self, settings: Settings, now=None):
        self.settings = settings
        self.now = now or time.time
        self.keys, self.fetched_at = {},0
        self.lock = threading.Lock()

    def _key(self,key_id):
        with self.lock:
            if self.now()-self.fetched_at > 21600 or (key_id not in self.keys and self.now()-self.fetched_at > 60):
                try:
                    response = requests.get(self.KEYS_URL,timeout=10,allow_redirects=False)
                    response.raise_for_status()
                    if len(response.content)>65536:
                        raise ValueError()
                    keys = {}
                    for record in response.json()['keys']:
                        key = serialization.load_pem_public_key(record['pem'].encode())
                        if not isinstance(key,ec.EllipticCurvePublicKey) or not isinstance(key.curve,ec.SECP256R1):
                            raise ValueError()
                        keys[str(record['keyId'])] = key
                    self.keys,self.fetched_at = keys,self.now()
                except Exception:
                    raise CommerceError('admob_keys_unavailable',503) from None
            if key_id not in self.keys:
                raise CommerceError('invalid_provider_auth',401)
            return self.keys[key_id]

    def verify(self, query: bytes):
        if not self.settings.admob_units:
            raise CommerceError('admob_not_configured',503)
        if len(query)>8192:
            raise CommerceError()
        try:
            raw = query.decode('ascii')
            signed, tail = raw.rsplit('&signature=',1)
            signature,key_id = tail.split('&key_id=')
            if '&' in key_id or not key_id.isdigit():
                raise ValueError()
            fields = parse_qsl(signed,keep_blank_values=True,strict_parsing=True)
            if len(fields) != len(dict(fields)) or any(k in {'signature','key_id'} for k,v in fields):
                raise ValueError()
            data = dict(fields)
            sig = parse_qsl('signature='+signature,strict_parsing=True)[0][1]
            decoded = base64.b64decode(sig+'='*(-len(sig)%4),altchars=b'-_',validate=True)
            self._key(key_id).verify(decoded,signed.encode('ascii'),ec.ECDSA(hashes.SHA256()))
            if (data['ad_unit'] not in self.settings.admob_units or data['reward_amount']!='2'
                or data['reward_item']!='tickets'):
                raise CommerceError('invalid_reward_configuration')
            return {'transaction':data['transaction_id'],'attempt':data['custom_data'],
                    'owner':data['user_id'],'occurred_at':int(data['timestamp'])//1000}
        except CommerceError:
            raise
        except Exception:
            raise CommerceError('invalid_provider_auth',401) from None
