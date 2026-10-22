import os
from pathlib import Path
import sys
import uuid
import secrets
import pytest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from cineus_commerce.config import Settings, PREMIERE, PLUS
from cineus_commerce.ledger import Ledger

@pytest.fixture
def settings(tmp_path):
    return Settings(environment='sandbox',database=tmp_path/'commerce.sqlite',
        signing_key=os.urandom(32),encryption_key=os.urandom(32),hash_key=os.urandom(32),
        google_products={'premiere':PREMIERE,'plus':PLUS},
        apple_products={'premiere':PREMIERE,'plus':PLUS},
        admob_units=('test-unit',))

@pytest.fixture
def clock():
    return [1791979200]

@pytest.fixture
def ledger(settings,clock):
    return Ledger(settings,now=lambda:clock[0])

def identity():
    return {'owner':str(uuid.uuid4()),'device':str(uuid.uuid4()),
            'token':secrets.token_urlsafe(32),'recovery':secrets.token_urlsafe(32)}

@pytest.fixture
def credentials():
    return identity()

@pytest.fixture
def principal(ledger,credentials):
    return ledger.register(**credentials)
