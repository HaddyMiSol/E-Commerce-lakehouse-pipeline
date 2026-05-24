{{ config(
    materialized='table',
    file_format='delta'
) }}

with raw_products as (
    select * from {{ source('bronze_layer', 'products') }}
),

cleaned_products as (
    select
        -- primary key
        cast(product_id as int) as product_id,
        
        -- trim text
        trim(category) as product_category,
        trim(name) as product_name,
        
        -- double to decimal
        cast(price_usd as decimal(10, 2)) as price_usd,
        cast(cost_usd as decimal(10, 2)) as cost_usd,
        cast(margin_usd as decimal(10, 2)) as margin_usd

    from raw_products
    where product_id is not null
)

-- uniqueness on product records
select distinct * from cleaned_products