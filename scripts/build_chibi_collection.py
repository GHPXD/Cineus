"""Install approved ImageGen chibi collection; preserve all ownership IDs.

Only deterministic crop, scaling, padding and contact-sheet assembly happen here.
Raw originals and prompts remain in docs/artwork/chibi-collection-v4.
"""
import hashlib
import json
import re
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / 'docs/artwork/chibi-collection-v4'
BINDINGS = {
    'projectionist': ('avatar_owl', 'collectionAvatarOwl'),
    'detective': ('avatar_fox', 'collectionAvatarFox'),
    'robot': ('premiere_avatar_cat', 'collectionAvatarCat'),
    'knight': ('premiere_avatar_hare', 'collectionAvatarHare'),
    'cartographer': ('night_avatar_raccoon', 'itemNightRaccoon'),
    'creature': ('mission_avatar_penguin', 'itemMissionPenguin'),
    'pilot': ('mission_avatar_capybara', 'itemMissionCapybara'),
    'archaeologist': ('mission_avatar_axolotl', 'itemMissionAxolotl'),
    'courier': ('city_avatar_panda', 'itemCityPanda'),
    'archivist': ('night_avatar_otter', 'itemNightOtter'),
    'editor': ('mission_avatar_firefly', 'itemMissionFirefly'),
    'director': ('city_avatar_hummingbird', 'itemCityHummingbird'),
}


def read(path):
    return json.loads(path.read_text(encoding='utf8'))


def write(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf8')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def sheet(entries, kind):
    columns = 4
    rows = (len(entries) + columns - 1) // columns
    canvas = Image.new('RGB', (1200, rows * 360), '#081322')
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.truetype(str(ROOT / 'assets/fonts/Nunito-600.ttf'), 17)
    small = ImageFont.truetype(str(ROOT / 'assets/fonts/Nunito-400.ttf'), 13)
    for index, entry in enumerate(entries):
        tile = Image.open(ROOT / entry['asset']).convert('RGBA')
        tile.thumbnail((278, 285), Image.Resampling.LANCZOS)
        x, y = index % columns * 300, index // columns * 360
        canvas.paste(tile, (x + (300 - tile.width) // 2, y + 3), tile)
        draw.text((x + 10, y + 296), entry.get('name', entry['id']), font=font, fill='#F5CF70')
        draw.text((x + 10, y + 325), entry.get('inspiration', entry['kind']), font=small, fill='#B0BED7')
    canvas.save(AUDIT / f'{kind.upper()}.png')


def main():
    approved = read(AUDIT / 'approved.json')
    avatar_specs = read(AUDIT / 'ROSTER.json') + approved
    support_specs = read(AUDIT / 'SUPPORTS.json')
    specs = [{**a, 'kind': 'avatar'} for a in avatar_specs] + support_specs
    assert len(specs) == 32 and len({s['id'] for s in specs}) == 32
    ready = []
    for spec in specs:
        generation = spec if spec.get('approved') else read(AUDIT / 'generations' / f"{spec['id']}.json")
        merged = {**spec, **generation}
        assert (AUDIT / 'sources' / f"{spec['id']}.png").is_file() or Path(merged['original']).is_file(), merged['id']
        ready.append(merged)

    sources = AUDIT / 'sources'
    sources.mkdir(exist_ok=True)
    records = read(ROOT / 'docs/artwork/collection.json')
    retired_sources = []
    manifest = []
    locales = {lang: read(ROOT / f'lib/l10n/app_{lang}.arb') for lang in ('pt', 'en', 'es')}
    naming = dict(re.findall(r"'([^']+)'\s*=>\s*l\.(\w+)", (ROOT / 'lib/presentation/widgets/collection_artwork.dart').read_text(encoding='utf8')))
    for entry in ready:
        item_id, kind = entry['id'], entry['kind']
        legacy = BINDINGS[item_id][0] if kind == 'avatar' else item_id
        old = next(r for r in records if r['id'] == legacy)
        retired_sources.append(old['source'])
        source = sources / f'{item_id}.png'
        if not source.exists():
            shutil.copyfile(entry['original'], source)
        image = Image.open(source).convert('RGBA')
        source_size = list(image.size)
        if kind == 'avatar':
            assert image.getchannel('A').getextrema()[0] == 0, item_id
            image = image.crop(image.getchannel('A').getbbox())
            image.thumbnail((472, 472), Image.Resampling.LANCZOS)
            output = Image.new('RGBA', (512, 512))
            output.alpha_composite(image, ((512 - image.width) // 2, (512 - image.height) // 2))
            for locale in locales.values():
                locale[BINDINGS[item_id][1]] = entry['name']
        else:
            output = image.resize((entry['width'], entry['height']), Image.Resampling.LANCZOS)
            if kind == 'frame':
                assert output.getpixel((output.width // 2, output.height // 2))[3] == 0, item_id
            else:
                assert output.getchannel('A').getextrema()[0] == 255, item_id
        runtime = ROOT / old['file']
        output.save(runtime, optimize=True)
        old.update(
            generator='built-in image_gen / GPT Image', prompt=entry['prompt'],
            prompt_kind='approved_preview_summary' if entry.get('approved') else 'exact_generation_prompt',
            generated_original=entry['original'], source=source.relative_to(ROOT).as_posix(),
            transparent=kind != 'appearance', kind=kind,
            conversion='Alpha bounding-box crop, proportional resize and 512px transparent padding' if kind == 'avatar' else 'Resize to existing card dimensions; generated alpha preserved',
            source_sha256=sha(source), file_sha256=sha(runtime), source_size=source_size,
            runtime_size=list(output.size), status='ready',
        )
        manifest.append(dict(
            id=item_id, kind=kind, name=entry.get('name', locales['pt'][naming[legacy + '_v1']]), inspiration=entry.get('inspiration', ''),
            legacy_item=legacy + '_v1', asset=old['file'], source=old['source'], sha256=sha(runtime),
            prompt=entry['prompt'], prompt_kind=old['prompt_kind'], reused_approved_preview=bool(entry.get('approved')),
            legal_status='Creative provenance only; not licensed or legally cleared by generation',
        ))
    assert sum((ROOT / m['asset']).stat().st_size for m in manifest) < 30 * 1024 * 1024
    for lang, values in locales.items():
        write(ROOT / f'lib/l10n/app_{lang}.arb', values)
    write(ROOT / 'docs/artwork/collection.json', records)
    write(AUDIT / 'MANIFEST.json', manifest)
    if not (AUDIT / 'RETIRED_SOURCES.json').exists():
        write(AUDIT / 'RETIRED_SOURCES.json', sorted(set(retired_sources)))
    for kind in ('avatar', 'frame', 'appearance'):
        sheet([m for m in manifest if m['kind'] == kind], kind)
    catalog_path = ROOT / 'lib/domain/entities/player_collection.dart'
    catalog_path.write_text(re.sub(r'static const version = \d+;', 'static const version = 6;', catalog_path.read_text(encoding='utf8')), encoding='utf8')
    commerce_path = ROOT / 'assets/commerce/catalog_v1.json'
    commerce = read(commerce_path)
    commerce.update(revision=5, min_catalog=6)
    for asset in commerce['assets']:
        entry = next(m for m in manifest if m['legacy_item'] == asset['item'])
        runtime = ROOT / entry['asset']
        asset.update(format='png', bytes=runtime.stat().st_size, sha256=sha(runtime))
    write(commerce_path, commerce)
    print('32 chibi collection assets installed; ownership and Cores preserved.')


if __name__ == '__main__':
    main()
