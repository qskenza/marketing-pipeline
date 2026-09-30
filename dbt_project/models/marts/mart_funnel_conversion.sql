-- Business view: where do users drop off, by channel and device?

with funnel as (

    select
        sessions.channel,
        sessions.device_category,
        steps.reached_view_item,
        steps.reached_add_to_cart,
        steps.reached_begin_checkout,
        steps.reached_purchase
    from {{ ref('int_funnel_steps') }} as steps
    inner join {{ ref('int_sessions') }} as sessions
        on steps.session_key = sessions.session_key

)

select
    channel,
    device_category,
    count(*) as sessions,
    sum(reached_view_item) as view_item_sessions,
    sum(reached_add_to_cart) as add_to_cart_sessions,
    sum(reached_begin_checkout) as begin_checkout_sessions,
    sum(reached_purchase) as purchase_sessions,
    -- share of all sessions reaching each step (always between 0 and 1)
    safe_divide(sum(reached_view_item), count(*)) as view_item_rate,
    safe_divide(sum(reached_add_to_cart), count(*)) as add_to_cart_rate,
    safe_divide(sum(reached_begin_checkout), count(*)) as begin_checkout_rate,
    safe_divide(sum(reached_purchase), count(*)) as purchase_rate,
    -- step-to-step conversion (useful for the dashboard)
    safe_divide(sum(reached_purchase), sum(reached_begin_checkout)) as checkout_to_purchase_rate
from funnel
group by channel, device_category
