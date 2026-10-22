"""Trace generated sprites / authorized existing raster origins; no authored geometry."""
import colorsys
import hashlib
import os
import json
import shutil
import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path
from PIL import Image
import vtracer
from vectorize_color_characters import trace
from sample_official_color_targets import BANDS

ROOT=Path(__file__).resolve().parents[1]
AUDIT=ROOT/'docs/artwork/characters/expanded'
SOURCES=ROOT/'assets/colors/sources'
OUT=ROOT/'assets/colors/art'
WORK=AUDIT/'working'
WORK.mkdir(exist_ok=True)
FLAT_FALLBACKS={'mickey_mouse','homer_simpson','donald_duck','kim_possible','winnie_pooh','lois_griffin','shaggy_rogers','goofy','peter_griffin'}

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def trace_detail(source,dest,size):
    vtracer.convert_image_to_svg_py(str(source),str(dest),colormode='color',hierarchical='cutout',mode='spline',
        filter_speckle=0,color_precision=8,layer_difference=4,corner_threshold=45,length_threshold=.8,
        max_iterations=10,splice_threshold=45,path_precision=3)
    tree=ET.parse(dest);svg=tree.getroot();svg.set('viewBox',f'0 0 {size[0]} {size[1]}')
    tree.write(dest,encoding='utf-8',xml_declaration=True)

def source_region(id,rgb,x,y):
    h,s,v=colorsys.rgb_to_hsv(*(c/255 for c in rgb));h*=360
    if id in BANDS:
        lo,hi,min_s,min_v,max_v=BANDS[id]
        if id=='bowser' and x<.5:return False
        if id=='knuckles' and y>.7:return False
        return (lo<=h<=hi if lo<hi else h>=lo or h<=hi) and s>=min_s and v>=max(.2,min_v-.2)
    if id=='mickey_mouse':return (h<20 or h>345) and s>.5 and v>.3
    if id=='homer_simpson':return 40<h<70 and s>.5 and v>.5
    if id=='donald_duck':return 185<h<250 and s>.35 and v>.25 and y<.4
    if id=='kim_possible':return 40<h<105 and s>.12 and .15<v<.85 and y>.45
    if id=='winnie_pooh':return 25<h<65 and s>.4 and v>.45
    if id=='lois_griffin':return 125<h<190 and s>.3 and v>.35
    if id=='shaggy_rogers':return 55<h<140 and s>.3 and v>.3
    if id=='goofy':return 185<h<240 and s>.4 and v>.3 and y>.5
    if id=='peter_griffin':return 65<h<160 and s>.3 and v>.15 and y>.45
    raise ValueError(id)

def main():
    generations=json.loads((AUDIT/'GENERATIONS_FINAL.json').read_text(encoding='utf8')) if (AUDIT/'GENERATIONS_FINAL.json').exists() else json.loads((AUDIT/'GENERATIONS_28.json').read_text(encoding='utf8'))
    by_id={r['id']:r for r in generations}
    fallback={r['id']:r for r in json.loads((AUDIT/'FALLBACKS.json').read_text(encoding='utf8'))}
    records=[]
    for spec in json.loads((AUDIT/'ROSTER.json').read_text(encoding='utf8')):
        id=spec['id'];g=by_id.get(id)
        if not g:continue
        record_path=AUDIT/'records'/(id+'.json');record_path.parent.mkdir(exist_ok=True)
        source=SOURCES/(id+'.png')
        if g.get('original'):
            original=Path(g['original']);shutil.copyfile(original,source)
            origin=dict(generator='built-in image_gen / GPT Image',generated_original=str(original),prompt=g['prompt'],palette_mode='single-marker')
        else:
            if id not in fallback:print('Awaiting fallback:',id);continue
            f=fallback[id];external=ROOT/f['external_file']
            assert sha(external)==f['external_sha256'],id
            if external.suffix=='.svg':
                env=os.environ.copy()
                env['NODE_PATH']=str(Path.home()/'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules')
                subprocess.run(['node',str(ROOT/'scripts/rasterize_source_svg.cjs'),str(external),str(source)],env=env,check=True)
            else:
                Image.open(external).convert('RGBA').save(source)
            origin=dict(generator='existing image; user-authorized fallback after ImageGen refusal',palette_mode='existing-single',prompt=g['prompt'],generation_error=g['error'],authorization='User approved existing images for refused characters, 2026-10-13',**{k:v for k,v in f.items() if k!='id'})
        if record_path.exists():
            old=json.loads(record_path.read_text(encoding='utf8'))
            if old.get('conversion_version')==(7 if g.get('original') else 6 if id in FLAT_FALLBACKS else 5) and old.get('source_sha256')==sha(source) and all((ROOT/e['file']).exists() and sha(ROOT/e['file'])==e['sha256'] for e in old['files']):
                records.append(old);continue
        im=Image.open(source).convert('RGBA')
        assert im.getchannel('A').getextrema()[0]==0,('missing actual transparency',id)
        im=im.crop(im.getchannel('A').getbbox())
        if g.get('original'):im.thumbnail((640,640),Image.Resampling.LANCZOS)
        else:
            factor=960/max(im.size)
            im=im.resize((round(im.width*factor),round(im.height*factor)),Image.Resampling.LANCZOS)
        base=im.copy();bp=base.load();mask=Image.new('RGB',im.size,'white');mp=mask.load()
        count=0
        for y in range(im.height):
            for x in range(im.width):
                red,green,blue,alpha=im.getpixel((x,y))
                if alpha<128:bp[x,y]=(0,0,0,0);continue
                selected=(red-255)**2+green**2+(blue-255)**2<115**2 if g.get('original') else source_region(id,(red,green,blue),x/im.width,y/im.height)
                if selected:
                    mp[x,y]=(0,0,0);bp[x,y]=(0,0,0,0);count+=1
                else:bp[x,y]=(red,green,blue,255)
        assert count>40,('empty live region',id,count)
        alpha=base.getchannel('A');base=base.convert('RGB').quantize(colors=48 if g.get('original') else 128).convert('RGBA');base.putalpha(alpha)
        raster=WORK/(id+'_base.png');base.save(raster)
        dest=OUT/(id+'_base.svg');(trace if g.get('original') else trace_detail)(raster,dest,im.size)
        if g.get('original') or id in FLAT_FALLBACKS:
            ink=Image.new('RGB',im.size,'white');ip=ink.load()
            for y in range(im.height):
                for x in range(im.width):
                    red,green,blue,alpha=im.getpixel((x,y))
                    if alpha>=128 and max(red,green,blue)<64 and (not g.get('original') or max(red,green,blue)-min(red,green,blue)<12):ip[x,y]=(0,0,0)
            ink_png=WORK/(id+'_ink.png');ink.save(ink_png)
            ink_svg=WORK/(id+'_ink.svg');trace(ink_png,ink_svg,im.size,binary=True)
            base_tree=ET.parse(dest)
            for element in list(ET.parse(ink_svg).getroot()):base_tree.getroot().append(element)
            base_tree.write(dest,encoding='utf-8',xml_declaration=True)
        region=WORK/(id+'_p0.png');mask.save(region)
        region_svg=OUT/(id+'_p0.svg');trace(region,region_svg,im.size,binary=True)
        record=dict(id=id,kind='character',status='converted',source=source.relative_to(ROOT).as_posix(),source_sha256=sha(source),
            converter='VTracer 0.6.15; generated marker at 640px or detailed existing colour pixels at 960px; original flat ink traced separately to preserve pupils, mouths and contours; no authored shapes',conversion_version=7 if g.get('original') else 6 if id in FLAT_FALLBACKS else 5,
            source_size=list(Image.open(source).size),trace_size=list(im.size),region_pixels=[count],
            files=[dict(file=p.relative_to(ROOT).as_posix(),sha256=sha(p)) for p in [dest,region_svg]],**origin)
        record_path.write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
        records.append(record);print(id,count,record['generator'])
    (AUDIT/'MANIFEST.json').write_text(json.dumps(records,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    print(len(records),'new sprites traced; old ten sprites untouched.')

if __name__=='__main__':main()
