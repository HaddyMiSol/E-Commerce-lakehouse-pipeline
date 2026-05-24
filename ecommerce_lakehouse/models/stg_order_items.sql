{{ config(
    materialized='table',
    file_format='delta'
) }}

with raw_order_items as (
    select * from {{ source('bronze_layer', 'order_items') }}
),

cleaned_order_items as (
    select
        -- cast to integers
        cast(order_id as int) as event_id,
        cast(product_id as int) as product_id,
        
        -- convert decimal counts to integers
        cast(quantity as int) as quantity,
        
        -- unit_price_usd & line_total_usd to decimal
        cast(unit_price_usd as decimal(10, 2)) as unit_price_usd,
        cast(line_total_usd as decimal(10, 2)) as line_total_usd

    from raw_order_items
    -- filtering out blank order id
    where order_id is not null
)

-- deduplication based on unique order id
select distinct * from cleaned_order_items