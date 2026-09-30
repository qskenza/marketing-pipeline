-- One row per GA4 event, flattened and cleaned.

with source as (

    select *
    from {{ source('ga4', 'events') }}
    where _table_suffix between '{{ var("ga4_start_date") }}' and '{{ var("ga4_end_date") }}'

),

flattened as (

    select
        parse_date('%Y%m%d', event_date) as event_date,
        timestamp_micros(event_timestamp) as event_timestamp,
        event_name,
        user_pseudo_id,
        (
            select value.int_value
            from unnest(event_params)
            where key = 'ga_session_id'
        ) as ga_session_id,
        (
            select value.string_value
            from unnest(event_params)
            where key = 'page_location'
        ) as page_location,
        traffic_source.source as traffic_source,
        traffic_source.medium as traffic_medium,
        traffic_source.name as traffic_campaign,
        device.category as device_category,
        geo.country as country,
        ecommerce.transaction_id as transaction_id,
        ecommerce.purchase_revenue_in_usd as purchase_revenue_usd
    from source

)

select
    *,
    -- ga_session_id is only unique per user, so we build a global session key
    concat(user_pseudo_id, '-', cast(ga_session_id as string)) as session_key
from flattened
