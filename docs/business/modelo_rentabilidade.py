"""Reproduce illustrative Cineus Brazil / Android + iOS scenarios in BRL.

No SDK credentials, real revenue, remote services, or player data are used.
Adjust assumptions below after observing production cohorts and store reports.
"""
from pathlib import Path
import csv
import json
import math

OUT = Path(__file__).resolve().parent
SCENARIOS = [
    dict(name='Conservador', dau=200, dau_mau=.15, opt_in=.10,
         views=1, availability=.70, completion=.90, publisher_ecpm_brl=8,
         active_payer_share=.003, price_brl=9.90, cash_opex=200, owner_pay=1500),
    dict(name='Base', dau=1000, dau_mau=.25, opt_in=.20,
         views=1.5, availability=.85, completion=.95, publisher_ecpm_brl=15,
         active_payer_share=.01, price_brl=9.90, cash_opex=350, owner_pay=1800),
    dict(name='Expansão', dau=5000, dau_mau=.30, opt_in=.30,
         views=2, availability=.90, completion=.95, publisher_ecpm_brl=25,
         active_payer_share=.02, price_brl=12.90, cash_opex=900, owner_pay=3000),
]
COMMON = dict(days=30, store_fee=.15, refunds=.02,
              licensing='Unquoted; excluded, not assumed free',
              tax='Not calculated; all results before tax',
              monthly_scope='Combined retained audience, excludes paid acquisition',
              platform_audience_split='70% Android / 30% iOS; hypothesis, not market share',
              store_fee_condition='15% assumes applicable enrollment/eligibility on both stores',
              prices='Hypotheses for a future subscription, not live offers',
              ecpm='Sensitivity assumptions, not observed market benchmarks')

# All values below are experiment assumptions, NOT Brazilian market quotes.
# Equal monetization avoids assuming iOS users are inherently more valuable.
# Days are averaged over ALL installs, including players who never activate.
PLATFORMS = [
    dict(platform='Android', audience_share=.70, cpi_brl=2.,
         store_fee=.15, lifetime_active_days=20, lifetime_payer_conversion=.01),
    dict(platform='iOS', audience_share=.30, cpi_brl=4.,
         store_fee=.15, lifetime_active_days=20, lifetime_payer_conversion=.01),
]
PAID_ASSUMPTIONS = dict(
    media_budgets_brl=[100], creative_cost_fraction_of_media=0.,
    target_ltv_to_acquisition_cost=1.3, cosmetic_price_brl=16.90,
    cosmetic_purchases_per_payer=1, future_subscription_price_brl=9.90,
    future_subscription_paid_months=3, refunds=.02,
    revenue_horizon='Lifetime cohort expectation, NOT first-month receipts',
    payer_definition='Lifetime converting installs / all installs; not active subscribers / MAU',
    excluded='Taxes, rights/licensing, variable service costs, store accounts, build setup, '
             'attribution tools, operations and owner pay; obtain quotes before profitability claims',
    incremental_installs='Assumes measured attributed installs are incremental; verify with holdouts',
    creative_scope='Reuse existing authorized assets, no external creative cash expense; owner work excluded',
    pricing='R$100 initial media cap supplied by user; CPI and split remain hypotheses, no campaign launched')
MEDIA_PLANS = [
    dict(name='Android primeiro', allocation={'Android': 1., 'iOS': 0.}),
    dict(name='Comparacao 70/30', allocation={'Android': .70, 'iOS': .30}),
]


def evaluate(s):
    mau = s['dau'] / s['dau_mau']
    paid_impressions = (s['dau'] * COMMON['days'] * s['opt_in'] *
                        s['views'] * s['availability'] * s['completion'])
    ads = paid_impressions * s['publisher_ecpm_brl'] / 1000
    payers = mau * s['active_payer_share']
    subscription_receipts = (payers * s['price_brl'] *
                             (1-COMMON['store_fee']) * (1-COMMON['refunds']))
    revenue = ads + subscription_receipts
    return dict(**s, mau=mau, expected_active_subscribers=payers,
                paid_impressions=paid_impressions, ads_receipts=ads,
                subscription_receipts=subscription_receipts,
                modeled_receipts=revenue,
                cash_contribution_before_tax_licenses=revenue-s['cash_opex'],
                economic_contribution_before_tax_licenses=revenue-s['cash_opex']-s['owner_pay'],
                cash_breakeven_dau=math.ceil(s['cash_opex']/(revenue/s['dau'])),
                economic_breakeven_dau=math.ceil((s['cash_opex']+s['owner_pay'])/(revenue/s['dau'])))


def cohort_unit_economics(platform):
    base = SCENARIOS[1]
    ad_per_active_day = (base['opt_in'] * base['views'] * base['availability'] *
                         base['completion'] * base['publisher_ecpm_brl'] / 1000)
    ads_ltv = platform['lifetime_active_days'] * ad_per_active_day
    net_purchase_factor = (1-platform['store_fee']) * (1-PAID_ASSUMPTIONS['refunds'])
    cosmetic_ltv = (platform['lifetime_payer_conversion'] *
                    PAID_ASSUMPTIONS['cosmetic_price_brl'] *
                    PAID_ASSUMPTIONS['cosmetic_purchases_per_payer'] * net_purchase_factor)
    pass_ltv = (platform['lifetime_payer_conversion'] *
                PAID_ASSUMPTIONS['future_subscription_price_brl'] *
                PAID_ASSUMPTIONS['future_subscription_paid_months'] * net_purchase_factor)
    ltv = ads_ltv + cosmetic_ltv
    target = PAID_ASSUMPTIONS['target_ltv_to_acquisition_cost']
    creative_rate = PAID_ASSUMPTIONS['creative_cost_fraction_of_media']
    return dict(**platform, ads_ltv=ads_ltv, cosmetic_purchase_ltv=cosmetic_ltv,
                initial_product_ltv=ltv, future_pass_product_ltv=ads_ltv+pass_ltv,
                initial_max_acquisition_cost_per_install=ltv/target,
                initial_max_media_cpi_with_creative=ltv/target/(1+creative_rate),
                future_max_media_cpi_with_creative=(ads_ltv+pass_ltv)/target/(1+creative_rate))


def evaluate_paid_budget(budget, unit_economics, plan):
    rows = []
    for p in unit_economics:
        spend = budget * plan['allocation'][p['platform']]
        if spend == 0:
            continue
        installs = spend / p['cpi_brl']
        creative = spend * PAID_ASSUMPTIONS['creative_cost_fraction_of_media']
        cost = spend + creative
        receipts = installs * p['initial_product_ltv']
        rows.append(dict(plan=plan['name'], media_budget_brl=budget, platform=p['platform'],
                         media_spend=spend, creative_cost=creative,
                         acquisition_cost=cost, expected_installs=installs,
                         media_cpi=p['cpi_brl'], acquisition_cost_per_install=cost/installs,
                         lifetime_initial_receipts=receipts,
                         lifetime_future_pass_receipts=installs*p['future_pass_product_ltv'],
                         lifetime_ads_only_receipts=installs*p['ads_ltv'],
                         initial_lifetime_receipts_to_media=receipts/spend,
                         initial_lifetime_receipts_to_acquisition=receipts/cost,
                         initial_lifetime_balance_before_exclusions=receipts-cost))
    totals = dict(plan=plan['name'], media_budget_brl=budget)
    for key in ('media_spend', 'creative_cost', 'acquisition_cost', 'expected_installs',
                'lifetime_initial_receipts', 'lifetime_future_pass_receipts',
                'lifetime_ads_only_receipts', 'initial_lifetime_balance_before_exclusions'):
        totals[key] = sum(r[key] for r in rows)
    totals['blended_media_cpi'] = budget/totals['expected_installs']
    totals['acquisition_cost_per_install'] = totals['acquisition_cost']/totals['expected_installs']
    totals['initial_lifetime_receipts_to_media'] = totals['lifetime_initial_receipts']/budget
    totals['initial_lifetime_receipts_to_acquisition'] = (
        totals['lifetime_initial_receipts']/totals['acquisition_cost'])
    return totals, rows


def write_csv(name, rows):
    with (OUT/name).open('w', encoding='utf-8-sig', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


if __name__ == '__main__':
    results = [evaluate(s) for s in SCENARIOS]
    platform_monthly = []
    for s in results:
        for p in PLATFORMS:
            # Shares divide a fixed total; adding a store does not double DAU/revenue.
            platform_monthly.append(dict(scenario=s['name'], platform=p['platform'],
                                         dau=s['dau']*p['audience_share'],
                                         mau=s['mau']*p['audience_share'],
                                         modeled_receipts=s['modeled_receipts']*p['audience_share']))
    (OUT/'cenarios.json').write_text(json.dumps(dict(assumptions=COMMON,
        scenarios=results, platform_breakdown=platform_monthly),
        ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    write_csv('cenarios.csv', results)
    write_csv('cenarios_plataformas.csv', platform_monthly)
    unit_economics = [cohort_unit_economics(p) for p in PLATFORMS]
    budgets, breakdown = [], []
    for budget in PAID_ASSUMPTIONS['media_budgets_brl']:
        for plan in MEDIA_PLANS:
            total, rows = evaluate_paid_budget(budget, unit_economics, plan)
            budgets.append(total)
            breakdown.extend(rows)
    (OUT/'aquisicao_paga.json').write_text(json.dumps(dict(
        assumptions=PAID_ASSUMPTIONS, media_plans=MEDIA_PLANS,
        platform_unit_economics=unit_economics,
        budgets=budgets, platform_breakdown=breakdown),
        ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    write_csv('aquisicao_paga.csv', budgets)
    write_csv('aquisicao_plataformas.csv', breakdown)
    for s in results:
        print(f"{s['name']}: MAU={s['mau']:.0f}, ads=R${s['ads_receipts']:.2f}, pass=R${s['subscription_receipts']:.2f}, modeled=R${s['modeled_receipts']:.2f}, cash=R${s['cash_contribution_before_tax_licenses']:.2f}, economic=R${s['economic_contribution_before_tax_licenses']:.2f}, break-even DAU={s['economic_breakeven_dau']}")
    for p in unit_economics:
        print(f"{p['platform']}: initial LTV={p['initial_product_ltv']:.6f}; "
              f"future Pass LTV={p['future_pass_product_ltv']:.6f}; "
              f"max initial media CPI={p['initial_max_media_cpi_with_creative']:.6f}")
    for b in budgets:
        print(f"{b['plan']}: media={b['media_budget_brl']:.0f}, all acquisition={b['acquisition_cost']:.0f}, "
              f"installs={b['expected_installs']:.0f}, lifetime initial receipts="
              f"{b['lifetime_initial_receipts']:.2f}, balance="
              f"{b['initial_lifetime_balance_before_exclusions']:.2f}")
    base=results[1]
    print(f"Base ads-only economic break-even: {math.ceil((350+1800)/(base['ads_receipts']/1000))} DAU")
