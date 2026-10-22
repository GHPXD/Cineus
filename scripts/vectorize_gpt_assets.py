"""Trace GPT Image originals into actual SVG paths; never invent icon geometry.

Requires project .venv: Pillow, vtracer. Source PNGs are immutable. Intermediate
palette reduction is part of the raster-to-vector conversion, not drawn artwork.
"""
import hashlib
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path
from PIL import Image
import vtracer

ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / 'docs/artwork/interface'
WORK = AUDIT / 'working'
WORK.mkdir(exist_ok=True)
NS = 'http://www.w3.org/2000/svg'
ET.register_namespace('', NS)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def convert(record):
    source = ROOT / record['source']
    image = Image.open(source).convert('RGBA')
    assert image.getchannel('A').getextrema()[0] == 0, source
    # Stable decode size and modest palette preserve shapes while avoiding
    # thousands of paths for imperceptible colour variations and alpha noise.
    image.thumbnail((512, 512) if record['kind'] in {'icon', 'platform'} else (896, 448),
                    Image.Resampling.LANCZOS)
    alpha = image.getchannel('A').point(lambda x: 255 if x >= 128 else 0)
    # Use the palette chosen by the user. Median-cut can spend six entries on
    # tiny ivory variations and merge gold with a blue shadow into muddy grey.
    # Fixed colour quantization changes no silhouettes or interior geometry.
    palette = Image.new('P', (1, 1))
    palette.putpalette([239,192,38, 87,144,255, 244,243,232, 45,84,170] * 64)
    rgb = image.convert('RGB').quantize(palette=palette,
                dither=Image.Dither.NONE).convert('RGBA')
    rgb.putalpha(alpha)
    intermediate = WORK / f"{record['id']}.png"
    rgb.save(intermediate)
    group = 'icons' if record['kind'] in {'icon', 'platform'} else 'illustrations'
    target = ROOT / 'assets/generated' / group / f"{record['id']}.svg"
    vtracer.convert_image_to_svg_py(str(intermediate), str(target),
        colormode='color', hierarchical='stacked', mode='spline',
        filter_speckle=128 if record['kind'] == 'platform' else 12,
        color_precision=6, layer_difference=24,
        corner_threshold=60, length_threshold=4.0, max_iterations=10,
        splice_threshold=45, path_precision=2)
    tree = ET.parse(target)
    svg = tree.getroot()
    svg.set('viewBox', f"0 0 {image.width} {image.height}")
    svg.insert(0, ET.Comment(f"GPT Image source: {record['source']}; SHA256 {sha(source)}; automatic VTracer conversion"))
    paths = list(svg.iter(f'{{{NS}}}path'))
    assert paths and not list(svg.iter(f'{{{NS}}}image')), target
    tree.write(target, encoding='utf-8', xml_declaration=True)
    ink = None
    if record['kind'] in {'icon', 'platform'}:
        # Trace a high-contrast version from the same generated raster. Ivory
        # regions become negative space; this keeps internal detail on gold UI.
        mask = Image.new('RGB', rgb.size, 'white')
        mask.putdata([(0, 0, 0) if a >= 128 and
            (0.2126*r + 0.7152*g + 0.0722*b) < 215 else (255, 255, 255)
            for r, g, b, a in rgb.get_flattened_data()])
        mask_path = WORK / f"{record['id']}_ink.png"
        mask.save(mask_path)
        ink = target.with_name(f"{record['id']}_ink.svg")
        vtracer.convert_image_to_svg_py(str(mask_path), str(ink),
            colormode='binary', mode='spline',
            filter_speckle=128 if record['kind'] == 'platform' else 12,
            corner_threshold=60, length_threshold=4.0, max_iterations=10,
            splice_threshold=45, path_precision=2)
        ink_tree = ET.parse(ink)
        ink_svg = ink_tree.getroot()
        ink_svg.set('viewBox', f"0 0 {image.width} {image.height}")
        ink_svg.insert(0, ET.Comment(f"High-contrast trace of GPT Image source {record['source']}; SHA256 {sha(source)}"))
        assert list(ink_svg.iter(f'{{{NS}}}path'))
        ink_tree.write(ink, encoding='utf-8', xml_declaration=True)
    record.update(svg=target.relative_to(ROOT).as_posix(), source_sha256=sha(source),
                  svg_sha256=sha(target), paths=len(paths),
                  source_size=list(Image.open(source).size),
                  trace_size=[image.width, image.height],
                  converter='vtracer 0.6.15; selected gold/blue/ivory palette plus blue overlap; alpha threshold 128',
                  conversion_version=5, status='converted',
                  ink_svg=ink.relative_to(ROOT).as_posix() if ink else None,
                  ink_sha256=sha(ink) if ink else None)
    return record


def main():
    records = []
    for path in sorted((AUDIT / 'records').glob('*.json')):
        record = json.loads(path.read_text(encoding='utf-8'))
        if record.get('conversion_version') != 5 or not (ROOT / record['svg']).is_file():
            record = convert(record)
            path.write_text(json.dumps(record, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
        assert sha(ROOT / record['source']) == record['source_sha256']
        assert sha(ROOT / record['svg']) == record['svg_sha256']
        records.append(record)
    (AUDIT / 'MANIFEST.json').write_text(json.dumps(records, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    ids = re.search(r'enum CineusAssetId \{([^}]+)', (ROOT/'lib/presentation/visuals/cineus_assets.dart').read_text(encoding='utf-8')).group(1)
    required = {x.strip() for x in ids.split(',') if x.strip()}
    complete = {r['id'] for r in records if r['kind'] == 'icon'}
    print(f'{len(records)} originals traced; icon coverage {len(complete)}/{len(required)}; remaining: {sorted(required-complete)}')


if __name__ == '__main__':
    main()
