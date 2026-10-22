"""Verify collection artwork provenance, true frame transparency and catalog use."""
import hashlib
import json
import xml.etree.ElementTree as ET
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
records = json.loads((ROOT/'docs/artwork/collection.json').read_text(encoding='utf-8'))
catalog = (ROOT/'lib/domain/entities/player_collection.dart').read_text(encoding='utf-8')
assert len(records) >= 16 and len({r['id'] for r in records}) == len(records)
assert sum(r.get('collection') == 'premiere_v1' for r in records) == 6
for r in records:
    source, runtime = ROOT/r['source'], ROOT/r['file']
    assert 'GPT Image' in r['generator'] and r['prompt']
    assert hashlib.sha256(source.read_bytes()).hexdigest() == r['source_sha256']
    assert hashlib.sha256(runtime.read_bytes()).hexdigest() == r['file_sha256']
    assert r['file'] in catalog
    generated = Path(r['generated_original'])
    if generated.exists():
        assert source.read_bytes() == generated.read_bytes()
    if runtime.suffix == '.svg':
        svg = ET.parse(runtime).getroot()
        assert list(svg.iter('{http://www.w3.org/2000/svg}path'))
        assert not list(svg.iter('{http://www.w3.org/2000/svg}image'))
        assert not list(svg.iter('{http://www.w3.org/2000/svg}script'))
    elif r['transparent']:
        image = Image.open(runtime).convert('RGBA')
        if r.get('kind') == 'avatar':
            assert image.getpixel((0, 0))[3] == 0
        else:
            assert image.getpixel((image.width//2,image.height//2))[3] == 0
        low,high = image.getchannel('A').getextrema()
        assert low == 0 and high >= 240
print(f'{len(records)} GPT Image collection sources verified, including real traced avatars and transparent frame apertures; 6 distinct Premiere items.')
