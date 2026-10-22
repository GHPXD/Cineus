"""Validate the immutable published schedule against bundled IDs and regions."""
import json
from datetime import date,timedelta
from pathlib import Path
root=Path(__file__).resolve().parents[1]
calendar=json.loads((root/'assets/daily/calendar_v1.json').read_text(encoding='utf-8'))
colors=json.loads((root/'assets/colors/training_v1.json').read_text(encoding='utf-8'))
questions={q['id']:q for q in colors['questions']}
days=calendar['days']
assert calendar['version']=='calendar-20261020-v1' and len(days)==1500
for n,day in enumerate(days):
    assert day['date']==(date(2026,10,20)+timedelta(days=n)).isoformat()
    assert 1<=day['clue']<=500 and 1<=day['poster']<=500 and day['clue']!=day['poster']
    assert len(day['colors'])==5 and len({questions[q]['character_id'] for q in day['colors']})==5
for start in range(len(days)-500+1):
    for mode in ['clue','poster']:assert len({d[mode] for d in days[start:start+500]})==500
for start in range(len(days)-10+1):
    assert len({questions[q]['character_id'] for d in days[start:start+10] for q in d['colors']})==50
print('1500 frozen days: movies unique across any 500-day window; 50 characters across any 10-day window.')
