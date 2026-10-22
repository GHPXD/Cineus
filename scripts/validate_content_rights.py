"""Evidence inventory. Public-release validation never treats attribution as a license."""
import argparse
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--public-release',action='store_true')
args=parser.parse_args()
inventory=json.loads((ROOT/'docs/legal/content-rights.json').read_text(encoding='utf-8'))
missing=[]
for group in inventory['groups']:
    evidence=ROOT/group['evidence'] if group.get('evidence') else None
    if group['status']!='verified' or not evidence or not evidence.is_file() or not group.get('commercial_use'):
        missing.append(group['id'])
print(f"Rights inventory: {len(inventory['groups'])} groups; {len(missing)} awaiting evidence")
if args.public_release and missing:
    raise SystemExit('Public release requires documented evidence: '+', '.join(missing))
