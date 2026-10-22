import base64
import hashlib
import hmac
import json
import logging
import os
import re
import uuid
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from .config import Settings

log = logging.getLogger('cineus.security')

class CommerceError(Exception):
    def __init__(self, code='invalid_request', status=400):
        self.code, self.status = code, status
        super().__init__(code)

def uuid_value(value):
    try:
        if str(uuid.UUID(value)) != value:
            raise ValueError()
        return value
    except (ValueError, TypeError, AttributeError):
        raise CommerceError() from None

def opaque(value):
    if not isinstance(value, str) or not re.fullmatch(r'[A-Za-z0-9_-]{43}', value):
        raise CommerceError()
    return value

def bounded(value, maximum=4096):
    if not isinstance(value, str) or not 1 <= len(value) <= maximum or any(ord(c) < 32 for c in value):
        raise CommerceError()
    return value

def b64(data):
    return base64.urlsafe_b64encode(data).decode().rstrip('=')

def unb64(text):
    if not isinstance(text, str) or not re.fullmatch(r'[A-Za-z0-9_-]+', text):
        raise CommerceError()
    try:
        return base64.b64decode(text + '=' * (-len(text) % 4), altchars=b'-_', validate=True)
    except ValueError:
        raise CommerceError() from None

class Secrets:
    def __init__(self, settings: Settings):
        self.settings = settings
        self.signer = Ed25519PrivateKey.from_private_bytes(settings.signing_key)
        self.cipher = AESGCM(settings.encryption_key)

    def digest(self, scope, value):
        return hmac.new(self.settings.hash_key, (scope + ':' + value).encode(), hashlib.sha256).hexdigest()

    def encrypt(self, value):
        nonce = os.urandom(12)
        return b64(nonce + self.cipher.encrypt(nonce, value.encode(), self.settings.environment.encode()))

    def decrypt(self, value):
        raw = unb64(value)
        return self.cipher.decrypt(raw[:12], raw[12:], self.settings.environment.encode()).decode()

    def snapshot(self, payload):
        raw = json.dumps(payload, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode()
        return {'key_id': self.settings.key_id, 'payload': b64(raw), 'signature': b64(self.signer.sign(raw))}

def security_event(code):
    # Never attach paths, query strings, bodies, bearer tokens or provider errors.
    log.warning('commerce_security_event=%s', code)
