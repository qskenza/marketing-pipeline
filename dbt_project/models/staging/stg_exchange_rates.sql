-- One row per date with the USD -> EUR and USD -> GBP rates as columns.

with source as (

    select *
    from {{ source('raw', 'exchange_rates') }}

)

select
    rate_date,
    max(if(currency = 'EUR', rate, null)) as usd_to_eur,
    max(if(currency = 'GBP', rate, null)) as usd_to_gbp
from source
where base_currency = 'USD'
group by rate_date
