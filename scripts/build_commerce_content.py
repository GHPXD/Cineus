"""Prepare a reviewable release; no signing, upload or activation."""
import hashlib
import json
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def build():
    from sys import path
    path.insert(0, str(ROOT/'backend'))
    from cineus_commerce.config import NIGHT,CITY,PRODUCT_ITEMS
    artwork=json.loads((ROOT/'docs/artwork/collection.json').read_text(encoding='utf-8'))
    assets=[]
    for row in artwork:
        file=ROOT/row['file'];raw=file.read_bytes()
        assets.append({'item':row['id']+'_v1','sha256':hashlib.sha256(raw).hexdigest(),
                       'bytes':len(raw),'format':file.suffix[1:]})
    value={'schema':1,'revision':5,'min_catalog':6,
        'collections':[
            {'id':'night_2026_10','product':NIGHT,'from':'2026-10-15T00:00:00Z','until':'2026-11-01T00:00:00Z',
             'name':{'pt':'Noite de estreia','en':'Premiere night','es':'Noche de estreno'},'items':list(PRODUCT_ITEMS[NIGHT])},
            {'id':'city_2026_11','product':CITY,'from':'2026-11-01T00:00:00Z','until':'2026-12-01T00:00:00Z',
             'name':{'pt':'Luzes da cidade','en':'City lights','es':'Luces de la ciudad'},'items':list(PRODUCT_ITEMS[CITY])}],
        'club_cycles':{'2026-10':NIGHT,'2026-11':CITY},
        'events':[{'id':'aurora_demo_v1','demo':True,'sponsor':{'pt':'Aurora — demonstração Cineus','en':'Aurora — Cineus demonstration','es':'Aurora — demostración Cineus'},
             'from':'2026-10-15T00:00:00Z','until':'2026-12-01T00:00:00Z',
             'target':3,'reward':'aurora_event_frame_v1','authorized':True}],
        'assets':assets}
    target=ROOT/'assets/commerce/catalog_v1.json';target.parent.mkdir(parents=True,exist_ok=True)
    target.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(f'Prepared revision {value["revision"]}: {len(assets)} assets, 2 collections, 1 explicit demo')

if __name__=='__main__':
    if '--initial' in sys.argv or not (ROOT/'assets/commerce/catalog_v1.json').exists():build()
    else:print('Using existing reviewed catalog; --initial explicitly regenerates the initial draft')
    if '--pack' in sys.argv:
        release=json.loads((ROOT/'assets/commerce/catalog_v1.json').read_text(encoding='utf-8'))
        directory=ROOT/'backend/content';(directory/'assets').mkdir(parents=True,exist_ok=True)
        originals={r['id']+'_v1':ROOT/r['file'] for r in json.loads((ROOT/'docs/artwork/collection.json').read_text(encoding='utf-8'))}
        for a in release['assets']:shutil.copyfile(originals[a['item']],directory/'assets'/a['sha256'])
        (directory/'release.json').write_text(json.dumps(release,ensure_ascii=False,indent=2),encoding='utf-8')
        print('Local package: backend/content (not deployed)')
