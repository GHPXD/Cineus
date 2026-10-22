"""Read an explicitly supplied Cineus SQLite copy, never modify or upload it.

Only aggregates are printed; no guesses, receipt tokens or player identity.
This is local troubleshooting, not cross-device DAU/retention or real revenue.
"""
import argparse
import json
import sqlite3
from contextlib import closing
from datetime import datetime, timedelta, timezone
from pathlib import Path


def summarize(path: Path,manifest: Path | None = None):
    if not path.is_file():
        raise FileNotFoundError(path)
    with closing(sqlite3.connect(path.resolve().as_uri() + '?mode=ro', uri=True)) as db:
        db.row_factory = sqlite3.Row
        tables = {r[0] for r in db.execute("SELECT name FROM sqlite_master WHERE type='table'")}
        cutoff = (datetime.now(timezone.utc)-timedelta(days=60)).isoformat().replace('+00:00', 'Z')
        result = dict(scope='Local device only; retained sample, not unique users or revenue',
                      recent_window_days=60, events=[], ticket_movements=[], balance=None)
        if 'product_events' in tables:
            result['events'] = [dict(r) for r in db.execute(
                'SELECT event,COUNT(*) AS count FROM product_events '
                'WHERE occurred_at >= ? GROUP BY event ORDER BY event', (cutoff,))]
        if 'ticket_movements' in tables:
            result['ticket_movements'] = [dict(r) for r in db.execute(
                'SELECT reason,COUNT(*) AS count,SUM(daily_delta) AS daily_delta,'
                'SUM(extra_delta) AS extra_delta FROM ticket_movements '
                'WHERE occurred_at >= ? GROUP BY reason ORDER BY reason', (cutoff,))]
        if 'player_tickets' in tables:
            row = db.execute('SELECT daily_tickets,extra_tickets,last_reset_date '
                             'FROM player_tickets WHERE id=1').fetchone()
            result['balance'] = dict(row) if row else None
        result['events_participation']=[]
        config=manifest or Path(__file__).resolve().parents[1]/'assets/commerce/catalog_v1.json'
        events={e['id']:e for e in json.loads(config.read_text(encoding='utf-8')).get('events',[])} if config.is_file() else {}
        if 'event_enrollment' in tables:
            for row in db.execute('SELECT event_id,COUNT(*) joined FROM event_enrollment GROUP BY event_id'):
                claimed=db.execute('SELECT COUNT(*) FROM event_claims WHERE event_id=?',(row['event_id'],)).fetchone()[0] if 'event_claims' in tables else 0
                e=events.get(row['event_id']);completed=None
                if e and 'journey_completions' in tables:
                    joined=db.execute('SELECT joined_at FROM event_enrollment WHERE event_id=?',(row['event_id'],)).fetchone()[0]
                    iso=lambda value:datetime.fromisoformat(value.replace('Z','+00:00')).isoformat(timespec='milliseconds').replace('+00:00','Z')
                    count=db.execute('SELECT COUNT(*) FROM journey_completions WHERE completed_at>=? AND completed_at>=? AND completed_at<?',(joined,iso(e['from']),iso(e['until']))).fetchone()[0]
                    completed=int(count>=e['target'])
                result['events_participation'].append({'event_id':row['event_id'],'joined':row['joined'],'goal_completed':completed,'reward_claimed':claimed})
        result['ad_value_estimates']=[]
        if 'product_events' in tables:
            totals={}
            for row in db.execute("SELECT properties FROM product_events WHERE event='ad_value' AND occurred_at>=?",(cutoff,)):
                value=json.loads(row[0]);key=(value.get('placement'),value.get('currency'),value.get('precision'))
                if all(key) and type(value.get('value_micros')) is int:
                    totals[key]=totals.get(key,0)+value['value_micros']
            result['ad_value_estimates']=[dict(placement=k[0],currency=k[1],precision=k[2],micros=v) for k,v in totals.items()]
        return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--database', type=Path, required=True,
                        help='Path to a local SQLite database copy')
    parser.add_argument('--manifest',type=Path,help='Matching reviewed event manifest; defaults to the bundled catalog')
    args = parser.parse_args()
    print(json.dumps(summarize(args.database,args.manifest), ensure_ascii=False, indent=2))
