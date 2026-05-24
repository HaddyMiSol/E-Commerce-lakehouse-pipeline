{{ config(
    materialized='incremental',
    unique_key = 'event_id',
    file_format='delta'
) }}

with raw_events as (
    select * from {{ source('bronze_layer', 'events') }}

    {% if is_incremental() %}
  -- runs on subsequent executions to find new data
  where timestamp > (select max(event_at) from {{ this }})
{% endif %}
),

cleaned_events as (
    select
        -- cast to integers
        cast(event_id as int) as event_id,
        cast(session_id as int) as session_id,
        cast(product_id as int) as product_id,
        
        -- timestamp handling
        cast(timestamp as timestamp) as event_at,
        
        -- cleaned string spaces
        lower(trim(event_type)) as event_type,
        lower(trim(payment)) as payment_method,
        
        -- convert decimal counts to standard integers
        cast(qty as int) as quantity,
        cast(cart_size as int) as cart_size,
        
        -- amount_usd to decimal
        cast(amount_usd as decimal(10, 2)) as amount_usd,
        
        -- normalize discount percent (e.g., converting 10.0% to 0.10)
        cast(discount_pct / 100.0 as decimal(5, 4)) as discount_percentage

    from raw_events
    -- filtering out incomplete event logs
    where event_id is not null
)


-- deduplication based on unique event id
select distinct * from cleaned_events