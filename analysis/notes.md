# Exploration & results notes

## Dataset overview (query 1 in exploration.sql)
- Total events: XXX   <- replace with your result from query 1
- Total users: XXX    <- replace with your result from query 1
- Period: 2020-11-01 to 2021-01-31 (Google Merchandise Store, GA4 sample)

## Channel performance (mkt_dev.mart_channel_performance)

| Channel | Sessions | Orders | Revenue (EUR) | Conversion | Avg order (EUR) |
|---|---|---|---|---|---|
| Organic Search | 122,841 | 1,244 | 74,862 | 1.01% | 60.18 |
| Referral | 63,524 | 990 | 58,677 | 1.56% | 59.27 |
| Unknown | 74,687 | 1,120 | 58,588 | 1.50% | 52.31 |
| Direct | 83,459 | 966 | 56,476 | 1.16% | 58.46 |
| Paid Search | 15,618 | 131 | 6,223 | 0.84% | 47.50 |

## Insights
1. Organic Search brings the most revenue (~29%) and the highest average order value,
   but through volume: its conversion rate is only 1.01%.
2. Referral converts best (1.56%, ~1.5x Organic Search): referral visitors have
   stronger purchase intent.
3. Paid Search is the weakest channel: lowest conversion (0.84%), lowest average
   order value (EUR 47.50), ~2% of revenue.
4. ~23% of revenue comes from "Unknown" sources because the dataset is anonymized.

## Business recommendation
Review paid search spend efficiency and test reallocating part of the budget
toward referral partnerships.