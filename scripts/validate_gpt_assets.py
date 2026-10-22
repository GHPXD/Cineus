"""Verify every replacement has a GPT raster original and real traced SVGs."""
import hashlib
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
AUDIT=ROOT/'docs/artwork/interface'
records=json.loads((AUDIT/'MANIFEST.json').read_text(encoding='utf-8'))
required=re.search(r'enum CineusAssetId \{([^}]+)',
    (ROOT/'lib/presentation/visuals/cineus_assets.dart').read_text(encoding='utf-8')).group(1)
ids={x.strip() for x in required.split(',') if x.strip()}
actual={r['id'] for r in records if r['kind']=='icon'}
assert actual==ids, f'Incomplete icon coverage: {sorted(ids-actual)}'
assert len(records)==len(ids)+6 and len({r['id'] for r in records})==len(records)
illustrations={f'learning_{x}' for x in ['tickets','daily']}
illustrations|={f'state_{x}' for x in ['empty','error','recovery']}
assert {r['id'] for r in records if r['kind']=='illustration'}==illustrations
assert {r['id'] for r in records if r['kind']=='platform'}=={'platformMark'}
svg_count=0
for r in records:
    assert 'GPT Image' in r['generator'] and r['prompt']
    original=ROOT/r['source']
    assert original.read_bytes().startswith(b'\x89PNG\r\n\x1a\n')
    assert hashlib.sha256(original.read_bytes()).hexdigest()==r['source_sha256']
    cached=Path(r['generated_original'])
    if cached.exists():
        assert cached.read_bytes()==original.read_bytes(), r['id']
    for field,hash_field in [('svg','svg_sha256'),('ink_svg','ink_sha256')]:
        if not r.get(field):continue
        file=ROOT/r[field]
        assert hashlib.sha256(file.read_bytes()).hexdigest()==r[hash_field]
        svg=ET.parse(file).getroot()
        assert svg.tag=='{http://www.w3.org/2000/svg}svg'
        assert list(svg.iter('{http://www.w3.org/2000/svg}path'))
        assert not list(svg.iter('{http://www.w3.org/2000/svg}image'))
        assert not list(svg.iter('{http://www.w3.org/2000/svg}script'))
        svg_count+=1
    if r['kind'] in {'icon','platform'}: assert r['ink_svg']
for filename in ['cineus_icon.dart','learning_art.dart','cineus_state_art.dart']:
    text=(ROOT/'lib/presentation/widgets'/filename).read_text(encoding='utf-8')
    assert 'SvgPicture.asset' in text and 'CustomPainter' not in text
assert svg_count==2*(len(ids)+1)+5
native=json.loads((AUDIT/'ANDROID_ICONS.json').read_text(encoding='utf-8'))
assert len(native)==10 and len({r['file'] for r in native})==10
for r in native:
    assert hashlib.sha256((ROOT/r['file']).read_bytes()).hexdigest()==r['sha256']
assert not (ROOT/'android/app/src/main/res/drawable/cineus_monochrome.xml').exists()
print(f'All {len(ids)} icon IDs, 5 illustrations and native brand verified; {svg_count} real SVGs with immutable GPT originals.')
