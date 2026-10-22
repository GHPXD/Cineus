"""Immutable, bounded content package. Requests never select filesystem paths."""
from pathlib import Path
import hashlib
import json
import re
from .security import CommerceError
from .config import PRODUCT_ITEMS,NIGHT,CITY

class ContentRelease:
    def __init__(self,directory):
        self.payload=None;self.files={}
        if not directory:return
        root=Path(directory).resolve()
        raw=(root/'release.json').read_bytes()
        if len(raw)>262144:raise ValueError('Oversized release')
        value=json.loads(raw)
        if (value['schema']!=1 or type(value['revision']) is not int or value['revision']<1
            or type(value['min_catalog']) is not int or value['min_catalog'] not in {3,4,5,6}):
            raise ValueError('Invalid content release')
        if len(value['assets'])>100:raise ValueError('Oversized release')
        total=0;items=set()
        for a in value['assets']:
            digest=a['sha256']
            if not re.fullmatch('[a-f0-9]{64}',digest) or a['format'] not in {'svg','png'} or a['item'] in items:raise ValueError('Invalid asset')
            items.add(a['item']);file=(root/'assets'/digest).resolve()
            if not file.is_relative_to(root) or file.is_symlink():raise ValueError('Invalid asset path')
            data=file.read_bytes();total+=len(data)
            if len(data)!=a['bytes'] or len(data)>5*1024*1024 or hashlib.sha256(data).hexdigest()!=digest:raise ValueError('Corrupt asset')
            self.files[digest]=(file,'image/svg+xml' if a['format']=='svg' else 'image/png')
        if total>30*1024*1024:raise ValueError('Oversized release')
        for c in value['collections']:
            if c['product'] not in {NIGHT,CITY} or set(c['items'])!=set(PRODUCT_ITEMS[c['product']]):raise ValueError('Invalid collection')
        for e in value['events']:
            if e.get('authorized') is not True or e['reward'] not in items:raise ValueError('Unauthorized event')
        self.payload=value
    def envelope(self,ledger):
        if self.payload is None:raise CommerceError('content_not_configured',503)
        return ledger.secrets.snapshot({**self.payload,'issued_at':ledger.now(),'environment':ledger.settings.environment,'audience':'cineus.content.v1'})
    def asset(self,digest):
        if digest not in self.files:raise CommerceError('content_not_found',404)
        return self.files[digest]
