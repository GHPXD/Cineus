"""Aggregates only. Amounts are grouped by currency; no inferred FX/tax/net."""
def report(ledger,start=0,end=253402300799):
    with ledger.db.connection() as db:
        financial=[dict(r) for r in db.execute('''SELECT platform,product,currency,state,COUNT(*) orders,
            SUM(gross_nanos) gross_before_refund_nanos,SUM(proceeds_nanos) known_proceeds_nanos,
            COUNT(proceeds_nanos) orders_with_known_proceeds FROM financial_orders
            WHERE purchased_at>=? AND purchased_at<? GROUP BY platform,product,currency,state ORDER BY platform,product,currency,state''',(start,end))]
        rights=[dict(r) for r in db.execute('''SELECT platform,product,COUNT(*) current_purchase_origins FROM purchases
            WHERE revoked=0 AND valid_from<=? AND (valid_until IS NULL OR valid_until>?) GROUP BY platform,product''',(ledger.now(),ledger.now()))]
        cycles=[dict(r) for r in db.execute('''SELECT platform,cycle_month,product,revoked,COUNT(*) cycles FROM cycle_grants
            WHERE valid_from>=? AND valid_from<? GROUP BY platform,cycle_month,product,revoked''',(start,end))]
        rewards=db.execute('SELECT COUNT(*),COALESCE(SUM(amount),0),COALESCE(SUM(acknowledged),0) FROM rewards WHERE occurred_at>=? AND occurred_at<?',(start,end)).fetchone()
        missing=db.execute('SELECT COUNT(*) FROM cycle_grants WHERE product IS NULL AND revoked=0').fetchone()[0]
    return {'environment':ledger.settings.environment,'window':{'from_inclusive':start,'until_exclusive':end},
        'scope':'Provider-verified orders observed by this ledger, not bank settlement or audience measurement',
        'financial_by_platform_product_currency_state':financial,'current_purchase_origins':rights,
        'cycle_deliveries':cycles,'missing_cycle_content':missing,
        'reward_receipts':{'confirmed':rewards[0],'tickets':rewards[1],'acknowledged':rewards[2]},
        'ad_revenue':None,'sponsorship_revenue':None,
        'limitations':['No cross-currency totals','Missing proceeds remain unknown','Partial refunds require provider proceeds or settlement reconciliation','Ad callbacks are in optional local diagnostics; reconcile with AdMob statements','No signed sponsor contract or invoice recorded here']}
