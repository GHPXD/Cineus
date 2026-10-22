"""Extract generated raster regions, then trace them. No authored SVG geometry."""
import copy
import colorsys
import hashlib
import json
import xml.etree.ElementTree as ET
from pathlib import Path
from PIL import Image, ImageFilter
import vtracer

ROOT=Path(__file__).resolve().parents[1]
AUDIT=ROOT/'docs/artwork/characters/base'
WORK=AUDIT/'working'; WORK.mkdir(parents=True,exist_ok=True)
OUT=ROOT/'assets/colors/art'; OUT.mkdir(parents=True,exist_ok=True)
NS='http://www.w3.org/2000/svg'; ET.register_namespace('',NS)
MARKERS=[(255,0,255),(0,255,255),(0,255,0),(255,165,0),(128,0,255)]
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()

def existing_slot(id,rgb,x,y):
    h,s,v=colorsys.rgb_to_hsv(*(c/255 for c in rgb)); h*=360
    if id=='spongebob':
      if 40<h<95 and s>.35 and v>.25: return 0
      if s<.2 and v>.75 and .35<y<.64: return 1
      if (h<15 or h>350) and s>.6 and v>.4 and .57<y<.69: return 2
      if 15<h<40 and s>.35 and .58<y<.82: return 3
      if y>.82 and v<.75: return 4
    if id=='pikachu':
      if s<.12 and v>.8 and y<.33: return 4
      if v<.32 and y<.18 and (x<.23 or x>.77): return 2
      if 10<h<40 and s>.3 and v<.7 and x<.55 and y>.5: return 3
      if (h<25 or h>350) and s>.65 and v>.5 and .31<y<.65: return 1
      if 35<h<65 and s>.45 and v>.5 and not (.3<x<.85 and y<.3): return 0
    if id=='stitch':
      if 265<h<330 and .1<s<.65 and v>.25: return 1
      if 175<h<205 and s>.25 and v>.5 and .22<y<.52: return 2
      if 200<h<240 and s>.5 and v<.45 and .3<x<.7 and .2<y<.47: return 3
      if 325<h<360 and s>.4 and v>.6 and .43<y<.68: return 4
      if 205<h<235 and s>.3 and v>.4: return 0
    if id=='patrick':
      if 55<h<100 and s>.4: return 0
      if 240<h<310 and s>.15: return 2
      if s<.2 and v>.75 and .15<y<.4: return 3
      if (h>325 or h<20) and v<.6 and s>.3 and .31<y<.51: return 4
      if (h>335 or h<20) and s>.15 and v>.6: return 1
    if id=='bugs':
      if s<.15 and .65<v<.88: return 0
      if s<.15 and v>.9 and y<.28: return 2
      if s<.15 and v>.9 and .32<y<.79 and .27<x<.7: return 1
      if 20<h<55 and s>.6 and v>.5: return 3
      if 65<h<140 and s>.45 and v>.25: return 4
    return None

def refine_regions(id,masks,base,original):
    """Retain semantic connected components, preserving original raster contours."""
    for slot in range(5):
      mask=masks[slot]; pixels=mask.load(); bp=base.load()
      if (id,slot) in {('pikachu',1),('bugs',1),('patrick',1)}:
        points={(x,y) for y in range(mask.height) for x in range(mask.width) if pixels[x,y]==(0,0,0)}
        groups=[]
        while points:
          stack=[points.pop()]; group=[]
          while stack:
            x,y=stack.pop();group.append((x,y))
            for adjacent in [(x+1,y),(x-1,y),(x,y+1),(x,y-1)]:
              if adjacent in points: points.remove(adjacent);stack.append(adjacent)
          groups.append(group)
        largest=max((len(g) for g in groups),default=0)
        for group in groups:
          cx=sum(x for x,y in group)/len(group)/mask.width
          cy=sum(y for x,y in group)/len(group)/mask.height
          keep=(not .46<cx<.63) if id=='pikachu' else (not (cx<.44 and cy>.48) and cy>.34) if id=='bugs' else (len(group)==largest or cy>.85)
          if not keep:
            for x,y in group: pixels[x,y]=(255,255,255);bp[x,y]=original.getpixel((x,y))
      if id=='spongebob' and slot==4:
        # Black shoes share pigment with narrow sock contours: retain those
        # original contour pixels instead of tinting them as footwear.
        shrunk=mask.filter(ImageFilter.MaxFilter(5)).load()
        for y in range(mask.height):
          for x in range(mask.width):
            if pixels[x,y]==(0,0,0) and shrunk[x,y]!=(0,0,0):
              pixels[x,y]=(255,255,255);bp[x,y]=original.getpixel((x,y))

def trace(src,dest,size,binary=False):
    vtracer.convert_image_to_svg_py(str(src),str(dest),colormode='binary' if binary else 'color',
       hierarchical='cutout',mode='spline',filter_speckle=1,color_precision=6,
       layer_difference=16,corner_threshold=60,length_threshold=2.0,
       max_iterations=10,splice_threshold=45,path_precision=3)
    tree=ET.parse(dest); svg=tree.getroot()
    svg.set('viewBox',f'0 0 {size[0]} {size[1]}')
    assert list(svg.iter(f'{{{NS}}}path')), dest
    assert not list(svg.iter(f'{{{NS}}}image')), dest
    tree.write(dest,encoding='utf-8',xml_declaration=True)

def main():
    records=[]
    for file in sorted((AUDIT/'records').glob('*.json')):
      r=json.loads(file.read_text(encoding='utf-8'))
      if r.get('palette_mode') not in {'markers','existing'}:
        print('Awaiting segmented source:',r['id']); continue
      source=ROOT/r['source']; im=Image.open(source).convert('RGBA')
      assert im.getchannel('A').getextrema()[0]==0,source
      if r['palette_mode']=='existing':
        im=im.crop(im.getchannel('A').getbbox())
      if r['id']=='pikachu':
        factor=640/max(im.size)
        im=im.resize((round(im.width*factor),round(im.height*factor)),Image.Resampling.LANCZOS)
      else: im.thumbnail((640,640),Image.Resampling.LANCZOS)
      slots=[1,0,2,3,4] if r['id']=='patrick' else [0,1,2,3,4]
      masks=[Image.new('RGB',im.size,'white') for _ in range(5)]
      masks_pixels=[m.load() for m in masks]
      base=im.copy(); bp=base.load(); counts=[0]*5
      for y in range(im.height):
       for x in range(im.width):
        red,green,blue,alpha=im.getpixel((x,y))
        if alpha<128: bp[x,y]=(0,0,0,0); continue
        distances=[sum((a-b)**2 for a,b in zip((red,green,blue),m)) for m in MARKERS]
        nearest=min(range(5),key=distances.__getitem__)
        slot=(slots[nearest] if distances[nearest]<115**2 else None) if r['palette_mode']=='markers' else existing_slot(r['id'],(red,green,blue),x/im.width,y/im.height)
        if r['id']=='pink_panther':
          hue,saturation,value=colorsys.rgb_to_hsv(red/255,green/255,blue/255)
          if 65<hue*360<145 and saturation>.45 and value>.5: slot=2
        if slot is not None:
         masks_pixels[slot][x,y]=(0,0,0); counts[slot]+=1
         bp[x,y]=(0,0,0,0)
        else: bp[x,y]=(red,green,blue,255)
      if r['palette_mode']=='existing': refine_regions(r['id'],masks,base,im)
      counts=[sum(p==(0,0,0) for p in mask.get_flattened_data()) for mask in masks]
      assert all(c>40 for c in counts), (r['id'],counts)
      # Palette reduction and mask extraction transform existing pixels only.
      alpha=base.getchannel('A')
      base=base.convert('RGB').quantize(colors=32).convert('RGBA'); base.putalpha(alpha)
      png=WORK/(r['id']+'_base.png'); base.save(png)
      dest=OUT/(r['id']+'_base.svg'); trace(png,dest,im.size)
      files=[dest]
      for index,mask in enumerate(masks):
        png=WORK/(r['id']+f'_p{index}.png'); mask.save(png)
        dest=OUT/(r['id']+f'_p{index}.svg'); trace(png,dest,im.size,binary=True); files.append(dest)
      r.update(status='converted',source_sha256=sha(source),
         converter='VTracer 0.6.15; generated-marker or source-pixel semantic colour extraction; 640px; no authored shapes',
         conversion_version=2,source_size=list(Image.open(source).size),trace_size=list(im.size),
         region_pixels=counts,files=[{'file':p.relative_to(ROOT).as_posix(),'sha256':sha(p)} for p in files])
      file.write_text(json.dumps(r,ensure_ascii=False,indent=2)+'\n',encoding='utf-8'); records.append(r)
      print(r['id'],counts)
    (AUDIT/'MANIFEST.json').write_text(json.dumps(records,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(len(records),'sprites traced; target regions:',len(records)*5)

if __name__=='__main__': main()
