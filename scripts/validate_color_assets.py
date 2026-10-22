"""Validate all 50 regions and their original image/trace provenance."""
import hashlib,json,xml.etree.ElementTree as ET
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
AUDIT=ROOT/'docs/artwork/characters/base'
records=json.loads((AUDIT/'MANIFEST.json').read_text(encoding='utf-8'))
catalog=json.loads((ROOT/'assets/colors/training_v1.json').read_text(encoding='utf-8'))
assert len(records)==10
expanded=ROOT/'docs/artwork/characters/expanded/MANIFEST.json'
if expanded.exists():records+=json.loads(expanded.read_text(encoding='utf-8'))
ids={r['id'] for r in records};assert ids=={q['character_id'] for q in catalog['questions']}
assert sum(r['palette_mode']=='markers' for r in records)==5
files=set()
for r in records:
 source=ROOT/r['source'];assert source.read_bytes().startswith(b'\x89PNG')
 assert hashlib.sha256(source.read_bytes()).hexdigest()==r['source_sha256']
 assert Image.open(source).convert('RGBA').getchannel('A').getextrema()[0]==0
 if r['palette_mode'] in {'markers','single-marker'}:
  assert 'GPT Image' in r['generator'] and r['prompt']
  cached=Path(r['generated_original'])
  if cached.is_file(): assert source.read_bytes()==cached.read_bytes()
 else: assert r['external_source'].startswith('https://') and r['authorization']
 assert len(r['files'])==(6 if r['conversion_version']==2 else 2) and all(c>40 for c in r['region_pixels'])
 for entry in r['files']:
  p=ROOT/entry['file'];assert hashlib.sha256(p.read_bytes()).hexdigest()==entry['sha256']
  svg=ET.parse(p).getroot();assert list(svg.iter('{http://www.w3.org/2000/svg}path'))
  assert not list(svg.iter('{http://www.w3.org/2000/svg}image'))
  assert not list(svg.iter('{http://www.w3.org/2000/svg}script'))
  files.add(entry['file'])
assert len(files)==sum(len(r['files']) for r in records)
continuity=ROOT/'docs/artwork/characters/continuity/MANIFEST.json'
if continuity.exists():
 for region in json.loads(continuity.read_text(encoding='utf-8')):
  source=ROOT/region['source'];target=ROOT/region['file'];reference=ROOT/region['reference_file']
  assert hashlib.sha256(source.read_bytes()).hexdigest()==region['source_sha256']
  assert hashlib.sha256(target.read_bytes()).hexdigest()==region['file_sha256']
  assert hashlib.sha256(reference.read_bytes()).hexdigest()==region['reference_sha256']
  im=Image.open(reference).convert('RGBA');pixel=im.getpixel(tuple(region['sample_xy']))[:3]
  assert '#%02X%02X%02X'%pixel==region['target_hex']
  assert region['region_pixels']>80
  svg=ET.parse(target).getroot();assert list(svg.iter('{http://www.w3.org/2000/svg}path'))
  assert not list(svg.iter('{http://www.w3.org/2000/svg}image'))
  files.add(region['file'])
widget=(ROOT/'lib/presentation/widgets/color_character_art.dart').read_text(encoding='utf-8')
assert 'SvgPicture.asset' in widget and 'CustomPainter' not in widget
for q in catalog['questions']:
 assert f"assets/colors/art/{q['character_id']}_{q['art_part']}.svg" in files
print(f"{len(records)} sprites / {len(catalog['questions'])} live regions / {len(files)} traced SVGs validated.")
