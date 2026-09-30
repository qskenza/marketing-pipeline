-- Business view: how does each marketing channel perform?

with sessions as (

    select
        channel,
        count(*) as sessions,
        count(distinct user_pseudo_id) as users
    from {{ ref('int_sessions') }}
    group by channel

),

orders as (

    select
        channel,
        count(*) as orders,
        sum(revenue_usd) as revenue_usd,
        sum(revenue_eur) as revenue_eur
    from {{ ref('fct_orders') }}
    group by channel

)

select
    sessions.channel,
    sessions.sessions,
    sessions.users,
    coalesce(orders.orders, 0) as orders,
    round(coalesce(orders.revenue_usd, 0), 2) as revenue_usd,
    round(coalesce(orders.revenue_eur, 0), 2) as revenue_eur,
    safe_divide(coalesce(orders.orders, 0), sessions.sessions) as conversion_rate,
    round(safe_divide(orders.revenue_eur, orders.orders), 2) as avg_order_value_eur
from sessions
left join orders
    on sessions.channel = orders.channel
