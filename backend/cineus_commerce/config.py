"""Validated server configuration. Secrets are required, never defaulted."""
from dataclasses import dataclass, field
from pathlib import Path
import base64
import json
import os
import re
from datetime import date

PREMIERE = 'cineus.collection.premiere.v1'
PLUS = 'cineus.plus.permanent.v1'
CLUB = 'cineus.club.monthly.v1'
NIGHT = 'cineus.collection.night.v1'
CITY = 'cineus.collection.city.v1'
TICKET_PRODUCTS = {'cineus.tickets.20.v1':20, 'cineus.tickets.60.v1':60}
PRODUCT_ITEMS = {
    **{product:() for product in TICKET_PRODUCTS},
    PREMIERE: tuple('premiere_' + i + '_v1' for i in (
        'avatar_cat', 'avatar_hare', 'frame_marquee', 'frame_deco',
        'frame_spotlight', 'appearance_velvet')),
    PLUS: ('plus_frame_crown_v1','plus_appearance_premiere_v1'),
    NIGHT: tuple('night_'+i+'_v1' for i in ('avatar_raccoon','avatar_otter','frame_orbit','frame_comet','frame_observatory','appearance_sky')),
    CITY: tuple('city_'+i+'_v1' for i in ('avatar_panda','avatar_hummingbird','frame_skyline','frame_bridge','frame_rain','appearance_night')),
    CLUB: (),
}

def decode_key(value: str) -> bytes:
    try:
        result = base64.b64decode(value, validate=True)
        if len(result) != 32:
            raise ValueError()
        return result
    except (ValueError, TypeError):
        raise ValueError('Expected a base64-encoded 32-byte key') from None

@dataclass(frozen=True)
class Settings:
    environment: str
    database: Path
    signing_key: bytes = field(repr=False)
    encryption_key: bytes = field(repr=False)
    hash_key: bytes = field(repr=False)
    key_id: str = 'v1'
    audience: str = 'cineus.commerce.v1'
    google_package: str = 'dev.cineus.cineus'
    apple_bundle: str = 'dev.cineus.cineus'
    google_products: dict[str, str] = field(default_factory=dict)
    apple_products: dict[str, str] = field(default_factory=dict)
    google_credentials: str = ''
    google_push_audience: str = ''
    google_push_email: str = ''
    google_subscription: str = ''
    google_club_base_plan: str = ''
    apple_key_path: str = ''
    apple_key_id: str = ''
    apple_issuer: str = ''
    apple_app_id: int | None = None
    apple_roots: tuple[str, ...] = ()
    admob_units: tuple[str, ...] = ()
    club_calendar: dict[str,str] = field(default_factory=dict)
    content_directory: str = ''
    economy_rollout_percent: int = 0

    def __post_init__(self):
        if type(self.economy_rollout_percent) is not int or not 0<=self.economy_rollout_percent<=100:
            raise ValueError('Economy rollout must be 0..100')
        if self.environment not in {'development', 'sandbox', 'production'}:
            raise ValueError('Explicit environment required')
        if any(len(k) != 32 for k in (self.signing_key, self.encryption_key, self.hash_key)):
            raise ValueError('Three separate 32-byte server keys are required')
        if len({self.signing_key, self.encryption_key, self.hash_key}) != 3:
            raise ValueError('Signing, encryption and hashing keys must differ')
        for products in (self.google_products, self.apple_products):
            if any(p not in PRODUCT_ITEMS for p in products.values()):
                raise ValueError('Unknown commercial product')
            if len(products.values()) != len(set(products.values())):
                raise ValueError('One store ID per internal product required')
        for month,product in self.club_calendar.items():
            if not re.fullmatch(r'[0-9]{4}-[0-9]{2}',month) or product not in {NIGHT,CITY}:
                raise ValueError('Invalid editorial cycle')
            date.fromisoformat(month+'-01')
        if len(set(self.club_calendar.values())) != len(self.club_calendar):
            raise ValueError('Cycles must deliver distinct collections')
        if CLUB in {*self.google_products.values(),*self.apple_products.values()} and len(self.club_calendar)<2:
            raise ValueError('Club requires at least two prepared editorial cycles')
        if CLUB in self.google_products.values() and not self.google_club_base_plan:
            raise ValueError('Explicit monthly Google base plan required')

    @classmethod
    def from_env(cls):
        e = os.environ
        required = ('CINEUS_ENV', 'COMMERCE_DATABASE', 'COMMERCE_SIGNING_KEY',
                    'COMMERCE_ENCRYPTION_KEY', 'COMMERCE_HASH_KEY')
        if any(not e.get(k) for k in required):
            raise ValueError('Missing required commercial server configuration')
        return cls(
            environment=e['CINEUS_ENV'], database=Path(e['COMMERCE_DATABASE']),
            signing_key=decode_key(e['COMMERCE_SIGNING_KEY']),
            encryption_key=decode_key(e['COMMERCE_ENCRYPTION_KEY']),
            hash_key=decode_key(e['COMMERCE_HASH_KEY']),
            key_id=e.get('COMMERCE_KEY_ID', 'v1'),
            google_package=e.get('GOOGLE_PACKAGE', 'dev.cineus.cineus'),
            apple_bundle=e.get('APPLE_BUNDLE_ID', 'dev.cineus.cineus'),
            google_products=json.loads(e.get('GOOGLE_PRODUCTS', '{}')),
            apple_products=json.loads(e.get('APPLE_PRODUCTS', '{}')),
            google_credentials=e.get('GOOGLE_APPLICATION_CREDENTIALS', ''),
            google_push_audience=e.get('GOOGLE_PUSH_AUDIENCE', ''),
            google_push_email=e.get('GOOGLE_PUSH_EMAIL', ''),
            google_subscription=e.get('GOOGLE_PUBSUB_SUBSCRIPTION', ''),
            google_club_base_plan=e.get('GOOGLE_CLUB_BASE_PLAN',''),
            apple_key_path=e.get('APPLE_KEY_PATH', ''),
            apple_key_id=e.get('APPLE_KEY_ID', ''),
            apple_issuer=e.get('APPLE_ISSUER_ID', ''),
            apple_app_id=int(e['APPLE_APP_ID']) if e.get('APPLE_APP_ID') else None,
            apple_roots=tuple(filter(None, e.get('APPLE_ROOT_CERTIFICATES', '').split(','))),
            admob_units=tuple(filter(None, e.get('ADMOB_SSV_UNITS', '').split(','))),
            club_calendar=json.loads(e.get('COMMERCE_CLUB_CALENDAR','{}')),
            content_directory=e.get('COMMERCE_CONTENT_DIRECTORY',''),
            economy_rollout_percent=int(e.get('CINEUS_ECONOMY_ROLLOUT_PERCENT','0')),
        )
