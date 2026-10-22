"""Illustrative in-game monetization, Brazil / Android + iOS combined.

No acquisition spend, campaign, external services or player data. These are
assumptions, not market benchmarks. One-time sales require NEW buyers each month.
Unquoted rights, tax, store enrollment and development setup costs are excluded.
"""
import csv
import json
from pathlib import Path

OUT = Path(__file__).resolve().parent
COMMON = dict(
    days=30, store_fee=.15, refunds=.02, cosmetic_price=14.90, plus_price=19.90,
    platform_scope='Android + iOS combined; no automatic doubling by store',
    fee_condition='15% requires applicable eligibility/enrollment; revalidate at launch',
    sales='New buyers of non-consumables / MAU per modeled month, not active subscribers',
    plus_stock='Average fraction of DAU owning Plus; excludes these users from interstitials only',
    ad_units='Publisher eCPM; no second deduction of ad network or store commission',
    stage='Initial = rewarded + cosmetics. Expanded = initial + interstitial + new Plus sales.',
    excludes='Tax, unquoted licenses/rights, store accounts, historic development, '
             'initial setup and contingencies. Not net profit or a bank cash-flow forecast.')
SCENARIOS = [
    dict(name='Conservador', dau=200, dau_mau=.15, rewarded_opt_in=.05,
         requests_per_optant=1, fill=.75, rewarded_completion=.90,
         rewarded_ecpm=8, interstitial_ecpm=4, eligible_slots_per_day=.15,
         plus_active_share=.01, new_cosmetic_buyers_mau=.003,
         new_plus_buyers_mau=.001, fixed_cash=100, content_cash=100, owner_work=1500),
    dict(name='Base', dau=1000, dau_mau=.25, rewarded_opt_in=.10,
         requests_per_optant=1.2, fill=.85, rewarded_completion=.95,
         rewarded_ecpm=15, interstitial_ecpm=6, eligible_slots_per_day=.30,
         plus_active_share=.03, new_cosmetic_buyers_mau=.0075,
         new_plus_buyers_mau=.0025, fixed_cash=350, content_cash=200, owner_work=1800),
    dict(name='Expansao', dau=5000, dau_mau=.30, rewarded_opt_in=.20,
         requests_per_optant=1.5, fill=.90, rewarded_completion=.95,
         rewarded_ecpm=20, interstitial_ecpm=8, eligible_slots_per_day=.50,
         plus_active_share=.08, new_cosmetic_buyers_mau=.01,
         new_plus_buyers_mau=.005, fixed_cash=700, content_cash=500, owner_work=3000),
]


def evaluate(s):
    mau = s['dau']/s['dau_mau']
    rewarded_impressions = (s['dau'] * COMMON['days'] * s['rewarded_opt_in'] *
                            s['requests_per_optant'] * s['fill'] * s['rewarded_completion'])
    # Slots already discount onboarding, short sessions and placement/cooldown caps.
    interstitial_impressions = (s['dau'] * (1-s['plus_active_share']) *
                               COMMON['days'] * s['eligible_slots_per_day'] * s['fill'])
    rewarded = rewarded_impressions*s['rewarded_ecpm']/1000
    interstitial = interstitial_impressions*s['interstitial_ecpm']/1000
    factor = (1-COMMON['store_fee'])*(1-COMMON['refunds'])
    cosmetic_buyers = mau*s['new_cosmetic_buyers_mau']
    plus_buyers = mau*s['new_plus_buyers_mau']
    cosmetics = cosmetic_buyers*COMMON['cosmetic_price']*factor
    plus = plus_buyers*COMMON['plus_price']*factor
    initial = rewarded+cosmetics
    expanded = initial+interstitial+plus
    cash_cost = s['fixed_cash']+s['content_cash']
    return dict(**s, mau=mau, new_cosmetic_buyers=cosmetic_buyers,
                new_plus_buyers=plus_buyers, rewarded_impressions=rewarded_impressions,
                interstitial_impressions=interstitial_impressions,
                rewarded_receipts=rewarded, cosmetic_receipts=cosmetics,
                interstitial_receipts=interstitial, plus_receipts=plus,
                initial_receipts=initial, expanded_receipts=expanded,
                modeled_cash_cost=cash_cost,
                initial_after_cash=initial-cash_cost,
                expanded_after_cash=expanded-cash_cost,
                initial_after_cash_and_work=initial-cash_cost-s['owner_work'],
                expanded_after_cash_and_work=expanded-cash_cost-s['owner_work'],
                ads_only_receipts=rewarded+interstitial,
                no_new_buyer_balance=rewarded+interstitial-cash_cost-s['owner_work'])


if __name__ == '__main__':
    rows = [evaluate(s) for s in SCENARIOS]
    (OUT/'monetizacao_produto.json').write_text(json.dumps(
        dict(assumptions=COMMON, scenarios=rows), ensure_ascii=False, indent=2)+'\n',
        encoding='utf-8')
    with (OUT/'monetizacao_produto.csv').open('w', encoding='utf-8-sig', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    for r in rows:
        print(f"{r['name']}: MAU={r['mau']:.2f}, rewarded={r['rewarded_receipts']:.4f}, "
              f"cosmetics={r['cosmetic_receipts']:.4f}, interstitial={r['interstitial_receipts']:.4f}, "
              f"Plus={r['plus_receipts']:.4f}, initial={r['initial_receipts']:.4f}, "
              f"expanded={r['expanded_receipts']:.4f}, after cash/work="
              f"{r['expanded_after_cash_and_work']:.4f}, no new buyers="
              f"{r['no_new_buyer_balance']:.4f}")
