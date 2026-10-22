"""Operational entrypoint. Never prints secret values or raw provider errors."""
import argparse
import base64
import json
import logging
import os
from pathlib import Path
import time
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from .config import Settings
from .ledger import Ledger
from .service import CommerceService

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--config',type=Path,help='Optional server-only JSON configuration')
    commands=parser.add_subparsers(dest='command',required=True)
    local=commands.add_parser('init-local'); local.add_argument('--out',type=Path,required=True)
    serve=commands.add_parser('serve'); serve.add_argument('--host',default='127.0.0.1'); serve.add_argument('--port',type=int,default=8000)
    commands.add_parser('check')
    commands.add_parser('public-key')
    backup=commands.add_parser('backup'); backup.add_argument('--out',type=Path,required=True)
    commands.add_parser('reconcile')
    report=commands.add_parser('report');report.add_argument('--from-epoch',type=int,default=0);report.add_argument('--until-epoch',type=int,default=253402300799)
    history=commands.add_parser('reconcile-order');history.add_argument('--proof-file',type=Path,required=True);history.add_argument('--order-id',required=True)
    worker=commands.add_parser('worker'); worker.add_argument('--interval',type=int,default=60)
    args=parser.parse_args()
    logging.basicConfig(level=logging.INFO,format='%(asctime)s %(levelname)s %(message)s')
    if args.command=='init-local':
        if args.out.exists(): parser.error('Configuration already exists; choose a new path')
        args.out.parent.mkdir(parents=True,exist_ok=True)
        config={'CINEUS_ENV':'sandbox','COMMERCE_DATABASE':str((args.out.parent.parent/'var/sandbox.sqlite').resolve())}
        for name in ('SIGNING','ENCRYPTION','HASH'):
            config['COMMERCE_'+name+'_KEY']=base64.b64encode(os.urandom(32)).decode()
        args.out.write_text(json.dumps(config,indent=2)+'\n',encoding='utf-8')
        args.out.chmod(0o600)
        print('Local sandbox configuration saved. No store or ad provider is enabled.')
        return
    if args.config:
        config=json.loads(args.config.read_text(encoding='utf-8'))
        allowed=('COMMERCE_','GOOGLE_','APPLE_','ADMOB_')
        for key,value in config.items():
            if key!='CINEUS_ENV' and not key.startswith(allowed): parser.error('Unexpected server configuration field')
            if not isinstance(value,str): parser.error('Configuration values must be strings')
            os.environ[key]=value
    settings=Settings.from_env()
    if args.command=='public-key':
        key=Ed25519PrivateKey.from_private_bytes(settings.signing_key).public_key()
        print(base64.b64encode(key.public_bytes(serialization.Encoding.Raw,serialization.PublicFormat.Raw)).decode())
    elif args.command=='serve':
        import uvicorn
        from .app import create_app
        # Do not log request URLs: AdMob SSV URLs contain signed identity data.
        uvicorn.run(create_app(settings),host=args.host,port=args.port,access_log=False,proxy_headers=False)
    elif args.command=='backup':
        Ledger(settings).db.backup(args.out)
        print('Consistent SQLite backup created and checked.')
    elif args.command=='check':
        ledger=Ledger(settings)
        with ledger.db.connection() as db:
            assert db.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
            for row in db.execute('SELECT proof FROM purchases'):
                ledger.secrets.decrypt(row[0])
            for row in db.execute('SELECT order_proof FROM cycle_grants'):
                ledger.secrets.decrypt(row[0])
            missing=db.execute('SELECT COUNT(*) FROM cycle_grants WHERE product IS NULL AND revoked=0').fetchone()[0]
            pending=db.execute('SELECT COUNT(*) FROM provider_events WHERE completed=0').fetchone()[0]
            unacked=db.execute('SELECT COUNT(*) FROM rewards WHERE acknowledged=0').fetchone()[0]
        print(json.dumps({'integrity':'ok','pending_provider_events':pending,'unacknowledged_rewards':unacked,'missing_cycle_content':missing}))
    elif args.command=='report':
        from .reporting import report
        print(json.dumps(report(Ledger(settings),args.from_epoch,args.until_epoch),ensure_ascii=False,indent=2))
    elif args.command=='reconcile-order':
        from .config import CLUB
        service=CommerceService(settings)
        proof=args.proof_file.read_text(encoding='utf-8').strip()
        service.verify_purchase('google',proof)
        cycle,revenue=service.providers['google'].verify_order(proof,args.order_id,CLUB)
        if not cycle:raise ValueError('Order does not contain a confirmed subscription cycle')
        service.ledger.apply_historical_cycle('google',proof,cycle,revenue)
        print('Historical cycle verified and reconciled; no proof printed.')
    else:
        service=CommerceService(settings)
        from .growth import Growth
        growth=Growth(service.ledger)
        while True:
            growth.prune()
            print(json.dumps(service.reconcile(limit=20)))
            if args.command!='worker': break
            if args.interval<30: parser.error('Minimum worker interval is 30 seconds')
            time.sleep(args.interval)

if __name__=='__main__':
    main()
