"""Read-only consented cohort report. Never exports identity tokens or raw guesses."""
import argparse
import json
import sqlite3
from datetime import datetime,timezone
from pathlib import Path

def report(path,now=None):
    now=now or int(datetime.now(timezone.utc).timestamp())
    with sqlite3.connect(f'file:{Path(path).resolve().as_posix()}?mode=ro',uri=True) as db:
        rows=db.execute("SELECT e.owner,e.event,e.occurred_at,e.properties FROM analytics_events e JOIN analytics_consent c ON c.owner=e.owner AND c.enabled=1 WHERE e.received_at>=?",(now-60*86400,)).fetchall()
    activity={};funnel={};micros={}
    for owner,event,stamp,props in rows:
        day=datetime.fromtimestamp(stamp,timezone.utc).date().isoformat()
        if event=='app_active':activity.setdefault(owner,set()).add(day)
        funnel.setdefault(event,set()).add(owner)
        if event=='ad_value':
            value=json.loads(props);currency=value.get('currency','unknown')
            micros[currency]=micros.get(currency,0)+value.get('value_micros',0)
    today=datetime.fromtimestamp(now,timezone.utc).date()
    active={owner for owner,days in activity.items() if today.isoformat() in days}
    monthly={owner for owner,days in activity.items() if any((today-datetime.fromisoformat(d).date()).days<30 for d in days)}
    retention={}
    for offset in [1,7,30]:
        eligible=returned=0
        for days in activity.values():
            first=datetime.fromisoformat(min(days)).date()
            if (today-first).days<offset:continue
            eligible+=1
            returned+=int(any((datetime.fromisoformat(d).date()-first).days==offset for d in days))
        retention[f'D{offset}']={'eligible':eligible,'returned':returned,'rate':returned/eligible if eligible else None}
    return {'as_of_utc':today.isoformat(),'consented_DAU':len(active),'consented_MAU':len(monthly),
      'observed_first_activity_retention':retention,'unique_accounts_by_event':{k:len(v) for k,v in funnel.items()},
      'ad_value_micros_unverified_estimate_by_currency':micros,
      'limits':['Opt-in population only; an account is not necessarily a person.',
        'Retention cohorts use first activity observed within the retained 60-day window.',
        'Ad values require filtering by currency before financial aggregation; never sum different currencies.']}

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--database',required=True);args=parser.parse_args()
    print(json.dumps(report(args.database),ensure_ascii=False,indent=2))
