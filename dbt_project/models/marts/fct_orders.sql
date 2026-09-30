-- One row per order, with revenue converted to EUR and GBP.

with purchases as (

    select *
    from {{ ref('stg_ga4__events') }}
    where event_name = 'purchase'
        and transaction_id is not null
        and transaction_id != '(not set)'
    -- keep only the first purchase event per transaction (dedupe)
    qualify row_number() over (partition by transaction_id order by event_timestamp) = 1

),

sessions as (

    select session_key, channel
    from {{ ref('int_sessions') }}

),

fx as (

    select *
    from {{ ref('int_daily_exchange_rates') }}

)

select
    purchases.transaction_id,
    purchases.event_date as order_date,
    purchases.event_timestamp as ordered_at,
    purchases.user_pseudo_id,
    purchases.session_key,
    coalesce(sessions.channel, 'Unknown') as channel,
    purchases.device_category,
    purchases.country,
    purchases.purchase_revenue_usd as revenue_usd,
    round(purchases.purchase_revenue_usd * fx.usd_to_eur, 2) as revenue_eur,
    round(purchases.purchase_revenue_usd * fx.usd_to_gbp, 2) as revenue_gbp
from purchases
left join sessions
    on purchases.session_key = sessions.session_key
left join fx
    on purchases.event_date = fx.rate_date
