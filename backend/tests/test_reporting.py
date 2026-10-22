from pathlib import Path
import runpy
import sqlite3

def test_local_event_report_counts_completion_separately_from_reward_claim(tmp_path):
    dbfile=tmp_path/'app.sqlite'
    with sqlite3.connect(dbfile) as db:
        db.executescript('''CREATE TABLE event_enrollment(event_id TEXT PRIMARY KEY,joined_at TEXT);
            CREATE TABLE event_claims(event_id TEXT PRIMARY KEY,claimed_at TEXT);
            CREATE TABLE journey_completions(game_key TEXT PRIMARY KEY,completed_at TEXT);
            INSERT INTO event_enrollment VALUES('aurora_demo_v1','2026-10-15T10:00:00.000Z');''')
        for i in range(3):db.execute('INSERT INTO journey_completions VALUES(?,?)',(str(i),'2026-10-15T12:00:00.000Z'))
    script=Path(__file__).resolve().parents[2]/'scripts/report_local_monetization.py'
    result=runpy.run_path(str(script))['summarize'](dbfile)
    assert result['events_participation']==[{'event_id':'aurora_demo_v1','joined':1,'goal_completed':1,'reward_claimed':0}]
    assert result['ad_value_estimates']==[]
