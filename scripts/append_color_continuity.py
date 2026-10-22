"""Extract additional colour masks from the existing image origins.

No authored character geometry or new generated target colours. Each target is
an exact pixel of a pinned official/existing reference. Existing questions,
traces and stage order remain byte-for-byte unchanged.
"""
import colorsys,hashlib,json,sys
from collections import Counter,deque
from pathlib import Path
from PIL import Image
from vectorize_color_characters import trace

ROOT=Path(__file__).resolve().parents[1]
SPECS=[
 ('mario','overalls',('Jardineira','Overalls','Peto'),(190,255,.3,.15,1,.35,1)),
 ('luigi','overalls',('Jardineira','Overalls','Peto'),(190,255,.3,.15,1,.35,1)),
 ('peach','hair',('Cabelo','Hair','Cabello'),(30,65,.35,.5,1,.07,.48)),
 ('yoshi','shoes',('Calçados','Shoes','Zapatos'),(10,45,.5,.4,1,.72,1)),
 ('bowser','skin',('Pele','Skin','Piel'),(20,65,.4,.4,1,0,1)),
 ('toad','vest',('Colete','Vest','Chaleco'),(185,255,.35,.2,1,.2,.85)),
 ('donkey_kong','tie',('Gravata','Tie','Corbata'),(350,8,.7,.3,1,.15,.85)),
 ('wario','overalls',('Jardineira','Overalls','Peto'),(260,320,.35,.25,1,.3,1)),
 ('waluigi','overalls',('Jardineira','Overalls','Peto'),(195,265,.25,.08,.6,.4,1)),
 ('daisy','hair',('Cabelo','Hair','Cabello'),(5,45,.35,.18,.7,.04,.29)),
 ('rosalina','hair',('Cabelo','Hair','Cabello'),(25,65,.15,.55,1,0,.55)),
 ('sonic','shoes',('Calçados','Shoes','Zapatos'),(345,20,.5,.4,1,.5,1)),
 ('tails','shoes',('Calçados','Shoes','Zapatos'),(345,20,.5,.4,1,.5,1)),
 ('knuckles','gloves',('Luvas','Gloves','Guantes'),(0,360,0,.83,1,.35,.78)),
 ('amy','dress',('Vestido','Dress','Vestido'),(350,12,.65,.35,1,.25,.63)),
 ('homer_simpson','pants',('Calça','Pants','Pantalón'),(185,260,.3,.2,1,.45,1)),
 ('mickey_mouse','shoes',('Calçados','Shoes','Zapatos'),(15,40,.4,.2,.8,.75,1)),
 ('donald_duck','bow_tie',('Gravata-borboleta','Bow tie','Pajarita'),(345,20,.45,.35,1,.15,.65)),
 ('goofy','boots',('Botas','Boots','Botas'),(15,45,.2,.2,.85,.72,1)),
 ('peter_griffin','shirt',('Camisa','Shirt','Camisa'),(0,360,0,.86,1,.2,.7)),
]

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def selected(pixel,y,height,spec):
 r,g,b,a=pixel
 if a<200:return False
 h,s,v=colorsys.rgb_to_hsv(r/255,g/255,b/255);h*=360
 lo,hi,minimum_s,minimum_v,maximum_v,y0,y1=spec
 if minimum_s==0 and s>.14:return False
 return (lo<=h<=hi if lo<hi else h>=lo or h<=hi) and s>=minimum_s and minimum_v<=v<=maximum_v and y0<=y/height<=y1

def remove_small_components(mask):
 # Keep the image-derived hair regions; disconnected jewellery/crown specks
 # selected by a similar hue must not be recoloured as hair.
 w,h=mask.size;pixels=mask.load();visited=bytearray(w*h);groups=[]
 for y in range(h):
  for x in range(w):
   i=y*w+x
   if visited[i] or pixels[x,y]!=(0,0,0):continue
   pending=deque([i]);visited[i]=1;group=[]
   while pending:
    current=pending.popleft();group.append(current);cx,cy=current%w,current//w
    for nx,ny in ((cx-1,cy),(cx+1,cy),(cx,cy-1),(cx,cy+1)):
     if 0<=nx<w and 0<=ny<h:
      n=ny*w+nx
      if not visited[n] and pixels[nx,ny]==(0,0,0):visited[n]=1;pending.append(n)
   groups.append(group)
 if groups:
  threshold=max(map(len,groups))*.03
  for group in groups:
   if len(group)<threshold:
    for i in group:pixels[i%w,i//w]=(255,255,255)
 return sum(1 for p in mask.getdata() if p==(0,0,0))

def main():
 directory=ROOT/'docs/artwork/characters/continuity';directory.mkdir(parents=True,exist_ok=True)
 working=directory/'working';working.mkdir(exist_ok=True)
 roster={r['id']:r for r in json.loads((ROOT/'docs/artwork/characters/expanded/ROSTER.json').read_text(encoding='utf-8'))}
 origins={r['id']:r for r in json.loads((ROOT/'docs/artwork/characters/expanded/MANIFEST.json').read_text(encoding='utf-8'))}
 catalog_file=ROOT/'assets/colors/training_v1.json';stage_file=ROOT/'assets/colors/stages_v1.json'
 catalog=json.loads(catalog_file.read_text(encoding='utf-8'));stages=json.loads(stage_file.read_text(encoding='utf-8'))
 if len(stages['stages'])>9:
  if '--review-unpublished' not in sys.argv:raise ValueError('Continuity already prepared; explicit unpublished review required')
  original=json.loads((ROOT/'test/fixtures/color_training_2.json').read_text(encoding='utf-8'))
  previous_stages=json.loads((ROOT/'test/fixtures/color_stages_1_original.json').read_text(encoding='utf-8'))
  assert catalog['questions'][:90]==original['questions'] and stages['stages'][:9]==previous_stages['stages']
  catalog,stages=original,previous_stages
 else:
  (ROOT/'test/fixtures/color_training_2.json').write_bytes(catalog_file.read_bytes())
  (ROOT/'test/fixtures/color_stages_1_original.json').write_bytes(stage_file.read_bytes())
 manifest=[];questions=[]
 for character,part,names,band in SPECS:
  origin=origins[character];row=roster[character]
  source=ROOT/origin['source'];assert sha(source)==origin['source_sha256']
  im=Image.open(source).convert('RGBA');im=im.crop(im.getchannel('A').getbbox())
  if 'GPT Image' in origin['generator']:im.thumbnail((640,640),Image.Resampling.LANCZOS)
  else:
   factor=960/max(im.size);im=im.resize((round(im.width*factor),round(im.height*factor)),Image.Resampling.LANCZOS)
  assert list(im.size)==origin['trace_size'],character
  mask=Image.new('RGB',im.size,'white');mp=mask.load();count=0
  for y in range(im.height):
   for x in range(im.width):
    pixel=im.getpixel((x,y))
    marker='GPT Image' in origin['generator'] and (pixel[0]-255)**2+pixel[1]**2+(pixel[2]-255)**2<115**2
    if not marker and selected(pixel,y,im.height,band):mp[x,y]=(0,0,0);count+=1
  if character in {'peach','daisy','rosalina'}:count=remove_small_components(mask)
  assert count>80,(character,'Empty source region',count)
  # A generated sprite is never a source of the answer: use an independent
  # published reference or the immutable external fallback origin.
  reference=ROOT/row['reference_file']
  if 'GPT Image' not in origin['generator']:
   reference=ROOT/origin['external_file'] if Path(origin['external_file']).suffix.lower()!='.svg' else source
  ref=Image.open(reference).convert('RGBA')
  sample_band={'peach':(35,65,.35,.9,1,.05,.2),'rosalina':(25,65,.15,.85,1,.05,.28),
    'daisy':(5,45,.35,.5,.9,.04,.29)}.get(character,band)
  pixels=[((r//16,g//16,b//16),(x,y),(r,g,b)) for y in range(ref.height) for x in range(ref.width)
    for r,g,b,a in [ref.getpixel((x,y))] if selected((r,g,b,a),y,ref.height,sample_band)]
  assert len(pixels)>10,(character,'Reference region missing')
  dominant=Counter(p[0] for p in pixels).most_common(1)[0][0]
  group=[p for p in pixels if p[0]==dominant];median=tuple(sorted(p[2][i] for p in group)[len(group)//2] for i in range(3))
  chosen=min(group,key=lambda p:sum((a-b)**2 for a,b in zip(p[2],median)))
  target='#%02X%02X%02X'%chosen[2]
  raster=working/(character+'_p1.png');mask.save(raster)
  dest=ROOT/f'assets/colors/art/{character}_p1.svg'
  trace(raster,dest,im.size,binary=True)
  previous=next(q for q in catalog['questions'] if q['character_id']==character)
  copy={lang:{**previous['copy'][lang],'part':names[i]} for i,lang in enumerate(['pt','en','es'])}
  q={**previous,'id':character+'_'+part+'_v1','art_part':'p1','target_hex':target,'copy':copy,
    'reference_edition':'Pinned official/existing reference, secondary region reviewed 2026-10-15',
    'reference_sha256':sha(reference),'validation':'Exact independent reference pixel; existing image-derived mask; no generated answer',
    'sampling':{'xy':list(chosen[1]),'image_sha256':sha(reference),'file':str(reference.relative_to(ROOT)).replace('\\','/'),'band':sample_band}}
  questions.append(q)
  manifest.append({'id':q['id'],'character_id':character,'source':origin['source'],'source_sha256':sha(source),
    'file':str(dest.relative_to(ROOT)).replace('\\','/'),'file_sha256':sha(dest),'region_pixels':count,'trace_size':list(im.size),
    'reference_file':str(reference.relative_to(ROOT)).replace('\\','/'),'reference_sha256':sha(reference),
    'target_hex':target,'sample_xy':list(chosen[1]),'part':dict(zip(['pt','en','es'],names)),
    'conversion':'Semantic colour extraction from immutable existing raster; VTracer paths; no authored geometry',
    'origin_manifest':'docs/artwork/characters/expanded/MANIFEST.json','publication_rights':'Existing catalogue rights review remains required before commercial publication'})
  print(character,part,target,count)
 catalog['questions'].extend(questions);catalog['pack_version']='training-3';catalog['checked_on']='2026-10-15'
 catalog['reference_policy']='50 distinct characters / 110 source-backed regions. Original 90 questions unchanged. Generated art never determines answers.'
 for offset in [0,10]:stages['stages'].append({'id':len(stages['stages'])+1,'questions':[q['id'] for q in questions[offset:offset+10]]})
 catalog_file.write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 stage_file.write_text(json.dumps(stages,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 (directory/'MANIFEST.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

if __name__=='__main__':main()
