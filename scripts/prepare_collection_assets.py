"""Copy immutable GPT Image sources and prepare collection runtime assets.

Only raster-to-vector tracing / size optimization; no authored icon geometry.
Run with the project's Pillow/vtracer environment. Provenance is preserved.
"""
import hashlib
import json
import shutil
import xml.etree.ElementTree as ET
from pathlib import Path
from PIL import Image
import vtracer
ET.register_namespace('', 'http://www.w3.org/2000/svg')

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT/'docs/artwork/collection.json'
WORK = ROOT/'docs/artwork/collection/working'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    WORK.mkdir(parents=True, exist_ok=True)
    records = json.loads(MANIFEST.read_text(encoding='utf-8'))
    for record in records:
        source, target = ROOT/record['source'], ROOT/record['file']
        source.parent.mkdir(parents=True, exist_ok=True)
        target.parent.mkdir(parents=True, exist_ok=True)
        if not source.exists():
            shutil.copyfile(record['generated_original'], source)
        if record.get('source_sha256'):
            assert sha(source) == record['source_sha256'], source
        original = Image.open(source).convert('RGBA')
        if record['transparent']:
            assert original.getchannel('A').getextrema()[0] == 0, source
        if 'frame_' in record['id']:
            assert original.getpixel((original.width//2,original.height//2))[3] == 0
        if target.suffix == '.svg':
            image = original.copy()
            image.thumbnail((384,384), Image.Resampling.LANCZOS)
            alpha = image.getchannel('A').point(lambda a: 255 if a >= 128 else 0)
            image = image.convert('RGB').quantize(colors=64, method=Image.Quantize.MEDIANCUT,
                dither=Image.Dither.NONE).convert('RGBA')
            image.putalpha(alpha)
            raster = WORK/f"{record['id']}.png"
            image.save(raster)
            vtracer.convert_image_to_svg_py(str(raster),str(target),
                colormode='color', hierarchical='stacked', mode='spline',
                filter_speckle=8, color_precision=6, layer_difference=16,
                corner_threshold=60, length_threshold=4, max_iterations=10,
                splice_threshold=45, path_precision=2)
            tree = ET.parse(target)
            svg = tree.getroot()
            svg.set('viewBox', f'0 0 {image.width} {image.height}')
            svg.insert(0,ET.Comment(f"Traced from GPT Image source {record['source']}; SHA256 {sha(source)}"))
            assert list(svg.iter('{http://www.w3.org/2000/svg}path'))
            assert not list(svg.iter('{http://www.w3.org/2000/svg}image'))
            tree.write(target,encoding='utf-8',xml_declaration=True)
            record['conversion'] = 'VTracer; 384px / 64 colors / alpha threshold 128; actual paths'
        else:
            image = original.copy()
            image.thumbnail((640,800), Image.Resampling.LANCZOS)
            if not record['transparent']:
                image = image.convert('RGB')
            image.save(target,optimize=True)
            record['conversion'] = 'Pillow; maximum 640x800; original alpha preserved'
        record.update(source_sha256=sha(source), file_sha256=sha(target),
            source_size=list(original.size), runtime_size=list(image.size), status='ready')
    MANIFEST.write_text(json.dumps(records,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(f'{len(records)} generated collection assets prepared with provenance.')

if __name__ == '__main__':
    main()
