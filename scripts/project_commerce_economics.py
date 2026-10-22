"""Reproducible illustrative economics; no measured demand or tax advice."""
import argparse
import json
from math import ceil

def project(mau,fee=.15,cash_cost=80,hours=8,hour_value=15):
    collection_orders=round(mau*.01);new_plus_orders=round(mau*.005);paid_club_cycles=round(mau*.005)
    gross=collection_orders*14.9+new_plus_orders*19.9+paid_club_cycles*9.9
    refund_reserve=.03;after_store=gross*(1-refund_reserve)*(1-fee)
    dau=mau*.2;fill=.6
    rewarded=dau*30*.15*fill;interstitial=dau*30*.05*fill
    ads=rewarded/1000*20+interstitial/1000*8
    net=after_store+ads
    return {'mau_assumed':mau,'orders_assumed':{'collection':collection_orders,'new_permanent_plus':new_plus_orders,'paid_club_cycles':paid_club_cycles},
        'purchase_gross_brl':round(gross,2),'store_fee_assumed':fee,'refund_reserve_assumed':refund_reserve,
        'purchase_contribution_before_tax_brl':round(after_store,2),'ads_assumed_brl':round(ads,2),
        'cash_cost_assumed_brl':cash_cost,'creative_time_opportunity_cost_brl':hours*hour_value,
        'cash_balance_before_tax_brl':round(net-cash_cost,2),'economic_balance_before_tax_brl':round(net-cash_cost-hours*hour_value,2)}

def result():
    return {'scope':'Hypotheses for one month, Android+iOS Brazil combined; no acquisition plan or guaranteed revenue',
        'observed_revenue':None,'taxes_and_store_membership_costs':'Not measured; must be added, not implicitly zero',
        'assumptions':{'DAU_MAU':.2,'rewarded_attempts_per_DAU_day':.15,'interstitial_opportunities_per_DAU_day':.05,'ad_fill':.6,'rewarded_publisher_ecpm_brl':20,'interstitial_publisher_ecpm_brl':8,'collection_order_rate':.01,'new_plus_order_rate':.005,'paid_club_cycle_rate':.005},
        'scenarios':[project(mau,fee) for mau in [200,1000,3000] for fee in [.15,.30]],
        'break_even_orders_with_no_ads_before_tax':{name:{'cash_80':ceil(80/(price*.97*.85)),'including_time_200':ceil(200/(price*.97*.85))} for name,price in [('collection_14_90',14.9),('new_plus_19_90',19.9),('club_cycle_9_90',9.9)]},
        'limitations':['All conversion, ad and cost inputs are hypothetical','Plus counts NEW eligible buyers only; no repeat monthly billing','Club counts paid valid cycles, not cumulative lifetime subscribers','Cosmetics already owned through Club are not a second collection sale','Ad value is a publisher revenue estimate; do not deduct the store purchase fee from it again','No sponsor revenue without a contract','Exclude sandbox/test ad traffic from observed revenue']}

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.parse_args()
    print(json.dumps(result(),ensure_ascii=False,indent=2))
