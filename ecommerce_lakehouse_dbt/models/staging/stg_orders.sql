{{ config(
    materialized='table',
    file_format='delta'
) }}

with raw_orders as (
    select * from {{ source('bronze_layer', 'orders') }}
),

cleaned_orders as (
    select
        -- primary & foreign keys
        cast(order_id as int) as order_id,
        cast(customer_id as int) as customer_id,
        
        -- timestamp
        cast(order_time as timestamp) as ordered_at,
        
        -- text
        lower(trim(payment_method)) as payment_method,
        lower(trim(country)) as purchase_country,
        lower(trim(device)) as device_type,
        lower(trim(source)) as acquisition_channel,
        
        -- double to decimal
        cast(subtotal_usd as decimal(10, 2)) as amount_before_discount_usd,
        cast(total_usd as decimal(10, 2)) as amount_after_discount_usd,
        
        -- convert whole number percentages (e.g. 5) to fractions (0.0500)
        cast(discount_pct / 100.0 as decimal(5, 4)) as discount_percentage

    from raw_orders
    where order_id is not null
)

-- uniqueness on primary keys
select distinct * from cleaned_orders