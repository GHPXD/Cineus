"""Name the editable region without announcing the hue being guessed."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
path=ROOT/'docs/artwork/characters/expanded/ROSTER.json'
rows=json.loads(path.read_text(encoding='utf8'))
fur={'pt':'Pelagem','en':'Fur','es':'Pelaje'}
parts={id:fur for id in ['tom_cat','gumball_watterson','sonic','tails','knuckles','amy']}
parts['yoshi']={'pt':'Pele','en':'Skin','es':'Piel'}
parts['all_might']={'pt':'Painéis principais do traje','en':'Main suit panels','es':'Paneles principales del traje'}
for row in rows:
    if row['id'] in parts:row['parts']=parts[row['id']]
path.write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print('Eight region labels now identify the part without revealing its hue.')
