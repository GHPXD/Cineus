import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
questions=json.loads((root/'assets/colors/training_v1.json').read_text(encoding='utf8'))['questions']
art=json.loads((root/'docs/artwork/characters/base/MANIFEST.json').read_text(encoding='utf8'))
expanded=root/'docs/artwork/characters/expanded/MANIFEST.json'
if expanded.exists():art+=json.loads(expanded.read_text(encoding='utf8'))
rows=[]
for item in art:
 q=next(q for q in questions if q['character_id']==item['id'])
 generated=item.get('generator','').startswith('built-in image_gen')
 urls=[v for k,v in item.items() if isinstance(v,str) and v.startswith('https://') and k in ('external_source','source_page')]
 rows.append({'id':item['id'],'copy':{locale:{'character':q['copy'][locale]['character'],'work':q['copy'][locale]['work']} for locale in ['pt','en','es']},
 'study_url':q['source_url'],'art_origin':'generated' if generated else 'reference','art_urls':sorted(set(urls)) if not generated else []})
assert len(rows)==len({q['character_id'] for q in questions})
(root/'assets/credits/colors_sources.json').write_text(json.dumps({'schema':1,'characters':rows},ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print(f'{len(rows)} character credits prepared without targets or private paths.')
