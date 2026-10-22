"""Reviewable sRGB samples from fixed official images, never generated targets."""
import colorsys,hashlib,json
from collections import Counter
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/artwork/characters/expanded'
# Reviewed semantic hue bands; the selected source pixel/coordinates are retained.
BANDS={
 'mario':(345,20,.45,.3,1), 'luigi':(70,165,.4,.3,1),
 'peach':(310,355,.25,.55,1), 'yoshi':(70,165,.4,.3,1),
 'bowser':(75,155,.35,.3,.85), 'toad':(345,20,.5,.35,1),
 'donkey_kong':(15,45,.35,.2,.7), 'wario':(42,70,.5,.6,1),
 'waluigi':(250,305,.35,.5,1), 'daisy':(40,70,.5,.6,1),
 'rosalina':(165,205,.25,.5,1), 'sonic':(200,245,.5,.25,1),
 'tails':(25,65,.5,.4,1), 'knuckles':(345,20,.5,.6,1),
 'amy':(315,350,.25,.45,1),
}

def main():
    refs=json.loads((OUT/'OFFICIAL_REFS.json').read_text(encoding='utf8'))
    roster=json.loads((OUT/'ROSTER.json').read_text(encoding='utf8'))
    by_id={r['id']:r for r in roster}
    for row in refs:
        path=ROOT/row['file'];im=Image.open(path).convert('RGBA')
        lo,hi,min_s,min_v,max_v=BANDS[row['id']]
        candidates=[]
        for y in range(im.height):
            for x in range(im.width):
                red,green,blue,alpha=im.getpixel((x,y))
                if alpha<250:continue
                if row['id']=='bowser' and not (x/im.width>.63 and .15<y/im.height<.65):continue
                if row['id']=='knuckles' and y/im.height>.65:continue
                h,s,v=colorsys.rgb_to_hsv(red/255,green/255,blue/255);h*=360
                if (lo<=h<=hi if lo<hi else h>=lo or h<=hi) and s>=min_s and min_v<=v<=max_v:
                    candidates.append(((red//16,green//16,blue//16),(x,y),(red,green,blue)))
        assert len(candidates)>50,row['id']
        dominant=Counter(c[0] for c in candidates).most_common(1)[0][0]
        region=[c for c in candidates if c[0]==dominant]
        median=tuple(sorted(c[2][i] for c in region)[len(region)//2] for i in range(3))
        chosen=min(region,key=lambda c:sum((a-b)**2 for a,b in zip(c[2],median)))
        value='#%02X%02X%02X'%chosen[2]
        by_id[row['id']].update(target_hex=value,source_url=row['source_url'],reference_image=row['image'],reference_file=row['file'],reference_sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
            sampling={'method':'reviewed dominant semantic hue bin; exact fixed official sRGB pixel, not generated artwork','xy':list(chosen[1]),'image_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'hsv_band':list(BANDS[row['id']])})
        print(row['id'],im.size,value,chosen[1],len(region))
    (OUT/'ROSTER.json').write_text(json.dumps(roster,ensure_ascii=False,indent=2)+'\n',encoding='utf8')

if __name__=='__main__':main()
