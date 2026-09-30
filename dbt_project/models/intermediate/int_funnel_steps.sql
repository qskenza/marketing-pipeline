-- One row per session with a flag (0/1) for each funnel step reached.

select
    session_key,
    max(if(event_name = 'view_item', 1, 0)) as reached_view_item,
    max(if(event_name = 'add_to_cart', 1, 0)) as reached_add_to_cart,
    max(if(event_name = 'begin_checkout', 1, 0)) as reached_begin_checkout,
    max(if(event_name = 'purchase', 1, 0)) as reached_purchase
from {{ ref('stg_ga4__events') }}
where session_key is not null
group by session_key
