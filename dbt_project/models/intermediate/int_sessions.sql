-- One row per session, with its marketing channel.

with events as (

    select *
    from {{ ref('stg_ga4__events') }}
    where session_key is not null

),

sessions as (

    select
        session_key,
        any_value(user_pseudo_id) as user_pseudo_id,
        min(event_date) as session_date,
        min(event_timestamp) as session_started_at,
        any_value(traffic_source) as traffic_source,
        any_value(traffic_medium) as traffic_medium,
        any_value(device_category) as device_category,
        any_value(country) as country,
        countif(event_name = 'page_view') as page_views
    from events
    group by session_key

)

select
    *,
    case
        when traffic_medium = 'organic' then 'Organic Search'
        when traffic_medium in ('cpc', 'ppc', 'paid') then 'Paid Search'
        when traffic_medium = 'referral' then 'Referral'
        when traffic_source = '(direct)' or traffic_medium = '(none)' then 'Direct'
        when traffic_medium in ('(data deleted)', '<Other>') then 'Unknown'
        else 'Other'
    end as channel
from sessions
