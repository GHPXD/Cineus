"""Check production Dart reachability and published asset/origin coverage."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sources = {p.resolve(): p.read_text(encoding='utf-8')
           for p in (ROOT / 'lib').rglob('*.dart')}
reachable = set()
pending = [(ROOT / 'lib/main.dart').resolve()]
while pending:
    path = pending.pop()
    if path in reachable:
        continue
    reachable.add(path)
    for directive in re.findall(r'\b(?:import|export|part)\s+[^;]+;', sources[path]):
        for ref in re.findall(r"['\"]([^'\"]+)['\"]", directive):
            candidate = (ROOT / 'lib' / ref[len('package:cineus/'):]
                         if ref.startswith('package:cineus/') else path.parent / ref)
            resolved = candidate.resolve()
            if resolved in sources:
                pending.append(resolved)
unused_code = sorted(p.relative_to(ROOT).as_posix() for p in sources.keys() - reachable)
assert not unused_code, f'Unreachable production files: {unused_code}'

expected = {
    'assets/cineus_v1.db', 'assets/cineus_v1_seed.json',
    'assets/colors/training_v1.json', 'assets/colors/stages_v1.json',
    'assets/brand/cineus_mark.png', 'assets/credits/colors_sources.json',
}
for source in sources.values():
    for value in re.findall(r"['\"](assets/[^'\"]+)['\"]", source):
        if '$' not in value:
            expected.add(value)
seed = json.loads((ROOT / 'assets/cineus_v1_seed.json').read_text(encoding='utf-8'))
expected.update(f"assets/posters/{m['id']}.jpg" for m in seed['movies'])
expected.update(re.findall(r'- asset:\s*(assets/\S+)',
                          (ROOT / 'pubspec.yaml').read_text(encoding='utf-8')))
expected.update(p.relative_to(ROOT).as_posix() for p in (ROOT / 'assets/licenses').glob('*'))
for filename in [
    'interface/MANIFEST.json', 'characters/base/MANIFEST.json',
    'characters/expanded/MANIFEST.json', 'characters/continuity/MANIFEST.json', 'home/MANIFEST.json',
    'films.json', 'posters.json', 'colors.json', 'match-cards.json', 'collection.json',
]:
    for record in json.loads((ROOT / 'docs/artwork' / filename).read_text(encoding='utf-8')):
        for key in ['svg', 'ink_svg', 'source', 'file']:
            value = record.get(key)
            if isinstance(value, str) and value.startswith('assets/'):
                expected.add(value)
        expected.update(item['file'] for item in record.get('files', []))
actual = {p.relative_to(ROOT).as_posix() for p in (ROOT / 'assets').rglob('*') if p.is_file()}
assert not expected - actual, f'Missing assets: {sorted(expected - actual)}'
assert not actual - expected, f'Unregistered assets: {sorted(actual - expected)}'
print(f'{len(reachable)} production Dart files reachable; {len(actual)} assets/origins registered.')
