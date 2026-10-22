"""Check that the delivered APK contains the exact current colour-mode assets."""
import argparse
import hashlib
import json
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('apk', type=Path)
parser.add_argument('--report', type=Path)
args = parser.parse_args()
apk = args.apk.resolve()
manifest_paths = [
    ROOT/'docs/artwork/characters/base/MANIFEST.json',
    ROOT/'docs/artwork/interface/MANIFEST.json',
]
expanded=ROOT/'docs/artwork/characters/expanded/MANIFEST.json'
if expanded.exists():manifest_paths.append(expanded)
expected = set()
for path in manifest_paths:
    for r in json.loads(path.read_text(encoding='utf-8')):
        for key in ['svg','ink_svg']:
            if r.get(key): expected.add(r[key])
        expected.update(entry['file'] for entry in r.get('files',[]))
with zipfile.ZipFile(apk) as archive:
    names=set(archive.namelist())
    for file in sorted(expected):
        embedded=archive.read('assets/flutter_assets/'+file)
        assert embedded==(ROOT/file).read_bytes(), file
    path='assets/colors/training_v1.json'
    content=archive.read('assets/flutter_assets/'+path)
    assert content==(ROOT/path).read_bytes()
    credits=ROOT/'assets/credits/colors_sources.json'
    if credits.exists(): assert archive.read('assets/flutter_assets/assets/credits/colors_sources.json')==credits.read_bytes()
    pack=json.loads(content)
    catalogue=json.loads((ROOT/path).read_text(encoding='utf-8'))
    assert pack==catalogue
    stages_path = ROOT/'assets/colors/stages_v1.json'
    if stages_path.exists():
        assert archive.read('assets/flutter_assets/assets/colors/stages_v1.json') == stages_path.read_bytes()
        stages = json.loads(stages_path.read_text(encoding='utf-8'))
        questions_by_id = {q['id']: q for q in pack['questions']}
        for stage in stages['stages']:
            assert len(stage['questions']) == 10
            assert len({questions_by_id[q]['character_id'] for q in stage['questions']}) == 10
    characters=len({q['character_id'] for q in pack['questions']})
    assert characters>=10
    assert not any('/assets/colors/sources/' in n or '/assets/generated/sources/' in n for n in names)
    architectures=sorted(n.split('/')[1] for n in names if n.startswith('lib/') and n.endswith('/libapp.so'))
    assert architectures==['arm64-v8a','armeabi-v7a','x86_64']
report=dict(apk=str(apk),bytes=apk.stat().st_size,
    sha256=hashlib.sha256(apk.read_bytes()).hexdigest(),
    bundled_svgs=len(expected),character_layers=len(list((ROOT/'assets/colors/art').glob('*.svg'))),questions=len(pack['questions']),characters=characters,
    architectures=architectures,original_sources_in_bundle=False)
dest=args.report or ROOT/'docs/maintenance/apk-contents.json'
dest.parent.mkdir(parents=True, exist_ok=True)
dest.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,indent=2))
