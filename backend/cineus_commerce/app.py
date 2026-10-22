"""Small authenticated API; no checkout or test-grant endpoint."""
from functools import partial
from typing import Literal
import logging
from fastapi import FastAPI, Request, Depends
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.responses import FileResponse
from .content import ContentRelease
from pydantic import BaseModel, ConfigDict, Field
from starlette.concurrency import run_in_threadpool
from .config import Settings
from .service import CommerceService
from .growth import Growth
from .security import CommerceError, bounded, security_event

class StrictBody(BaseModel):
    model_config = ConfigDict(extra='forbid',strict=True)

class Registration(StrictBody):
    owner: str = Field(min_length=36,max_length=36)
    device: str = Field(min_length=36,max_length=36)
    token: str = Field(min_length=43,max_length=43)
    recovery: str = Field(min_length=43,max_length=43)

class Recovery(Registration):
    pass

class Purchase(StrictBody):
    platform: Literal['google','apple']
    proof: str = Field(min_length=1,max_length=4096)

class Receipt(StrictBody):
    receipt_id: str = Field(min_length=1,max_length=80)

class AppleNotification(StrictBody):
    signedPayload: str = Field(min_length=1,max_length=65500)

class GrowthCommand(StrictBody):
    action: str = Field(min_length=1,max_length=32)
    nonce: str = Field(min_length=43,max_length=43)
    payload: dict

def bearer(request):
    value = request.headers.get('authorization','')
    if not value.startswith('Bearer ') or len(value)>8192:
        raise CommerceError('invalid_credentials',401)
    return value[7:]

def create_app(settings: Settings, service=None):
    service = service or CommerceService(settings)
    ledger = service.ledger
    growth = Growth(ledger)
    app = FastAPI(title='Cineus Commerce',docs_url=None,redoc_url=None,openapi_url=None)
    app.state.commerce = service
    content = ContentRelease(settings.content_directory)

    @app.exception_handler(CommerceError)
    async def rejected(request,error):
        security_event(error.code)
        return JSONResponse({'error':error.code},status_code=error.status)

    @app.exception_handler(RequestValidationError)
    async def invalid_body(request,error):
        # Pydantic's default response can reflect the user's proof/secret.
        return JSONResponse({'error':'invalid_request'},status_code=400)

    @app.middleware('http')
    async def protections(request: Request, call_next):
        try:
            chunks, length = [],0
            async for chunk in request.stream():
                length += len(chunk)
                if length > 65536:
                    raise CommerceError('payload_too_large',413)
                chunks.append(chunk)
            request._body = b''.join(chunks)
            # The network peer is trusted, never an arbitrary X-Forwarded-For.
            peer = request.client.host if request.client else 'unknown'
            category = 'auth' if request.url.path in {'/v1/identity','/v1/identity/recover'} else 'api'
            key = ledger.secrets.digest('rate',category+':'+peer)
            await run_in_threadpool(ledger.db.rate_limit,key,10 if category=='auth' else 180,
                                    900 if category=='auth' else 60,ledger.now())
            response = await call_next(request)
        except CommerceError as error:
            security_event(error.code)
            response = JSONResponse({'error':error.code},status_code=error.status)
        except Exception:
            security_event('internal_failure')
            response = JSONResponse({'error':'temporarily_unavailable'},status_code=503)
        response.headers.update({
            'Cache-Control':'no-store','X-Content-Type-Options':'nosniff','X-Frame-Options':'DENY',
            'Content-Security-Policy':"default-src 'none'; frame-ancestors 'none'",
            'Referrer-Policy':'no-referrer','Permissions-Policy':'camera=(), microphone=(), geolocation=()',
        })
        if settings.environment=='production':
            response.headers['Strict-Transport-Security']='max-age=31536000; includeSubDomains'
        return response

    def principal(request: Request):
        p = ledger.authenticate(bearer(request))
        ledger.db.rate_limit(ledger.secrets.digest('owner_rate',p.owner),60,60,ledger.now())
        return p

    @app.get('/health')
    def health():
        with ledger.db.connection() as db:
            db.execute('SELECT 1').fetchone()
        return {'status':'ok'}

    @app.post('/v1/growth')
    def growth_operation(body: GrowthCommand,p=Depends(principal)):
        return growth.command(p,body.action,body.nonce,body.payload)

    @app.post('/v1/identity')
    def register(body: Registration):
        p = ledger.register(body.owner,body.device,body.token,body.recovery)
        return ledger.snapshot(p)

    @app.post('/v1/identity/recover')
    def recover(body: Recovery):
        p = ledger.recover(body.owner,body.recovery,body.device,body.token)
        return ledger.snapshot(p)

    @app.get('/v1/snapshot')
    def snapshot(p=Depends(principal)):
        return ledger.snapshot(p)

    @app.get('/v1/content')
    def content_manifest(p=Depends(principal)):
        return content.envelope(ledger)

    @app.get('/v1/content/assets/{digest}')
    def content_asset(digest: str,p=Depends(principal)):
        file,kind=content.asset(digest)
        return FileResponse(file,media_type=kind,headers={'ETag':'"'+digest+'"'})

    @app.post('/v1/purchases/verify')
    def verify(body: Purchase,p=Depends(principal)):
        ledger.db.rate_limit(ledger.secrets.digest('verification_rate',p.owner),10,60,ledger.now())
        service.verify_purchase(body.platform,body.proof,p.owner)
        return ledger.snapshot(p)

    @app.post('/v1/reconcile')
    def reconcile(p=Depends(principal)):
        ledger.db.rate_limit(ledger.secrets.digest('reconcile_rate',p.owner),3,300,ledger.now())
        service.reconcile(p.owner)
        return ledger.snapshot(p)

    @app.post('/v1/rewards/start')
    def start(p=Depends(principal)):
        if not settings.admob_units:
            raise CommerceError('admob_not_configured',503)
        return ledger.start_reward(p)

    @app.post('/v1/rewards/ack')
    def acknowledge(body: Receipt,p=Depends(principal)):
        ledger.acknowledge_reward(p,body.receipt_id)
        return {'acknowledged':True}

    @app.post('/callbacks/google')
    def google(request: Request,body: dict):
        eid,stamp,proof = service.providers['google'].notification(bearer(request),body)
        service.notification('google',eid,stamp,proof)
        return {'accepted':True}

    @app.post('/callbacks/apple')
    def apple(body: AppleNotification):
        eid,stamp,proof = service.providers['apple'].notification(body.signedPayload)
        service.notification('apple',eid,stamp,proof)
        return {'accepted':True}

    @app.get('/callbacks/admob')
    def admob(request: Request):
        data = service.admob.verify(request.scope['query_string'])
        ledger.confirm_reward(**data)
        return {'accepted':True}

    return app

def configured_app():
    return create_app(Settings.from_env())
