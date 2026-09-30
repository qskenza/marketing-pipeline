-- One row per calendar day. Weekends/holidays reuse the last known rate (forward fill).

with rates as (

    select *
    from {{ ref('stg_exchange_rates') }}

),

calendar as (

    select rate_date
    from unnest(
        generate_date_array(
            (select min(rate_date) from rates),
            greatest(
                (select max(rate_date) from rates),
                parse_date('%Y%m%d', '{{ var("ga4_end_date") }}')
            )
        )
    ) as rate_date

),

joined as (

    select
        calendar.rate_date,
        rates.usd_to_eur,
        rates.usd_to_gbp,
        rates.rate_date is null as is_forward_filled
    from calendar
    left join rates
        on calendar.rate_date = rates.rate_date

)

select
    rate_date,
    last_value(usd_to_eur ignore nulls) over w as usd_to_eur,
    last_value(usd_to_gbp ignore nulls) over w as usd_to_gbp,
    is_forward_filled
from joined
window w as (order by rate_date rows between unbounded preceding and current row)
