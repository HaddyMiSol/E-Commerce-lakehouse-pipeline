{{ config(
    materialized='table',
    file_format='delta'
) }}

with raw_reviews as (
    select * from {{ source('bronze_layer', 'reviews') }}
),

cleaned_reviews as (
    select
        -- primary & foreign keys
        cast(review_id as int) as review_id,
        cast(order_id as int) as order_id,
        cast(product_id as int) as product_id,
        
        -- rating to int
        cast(rating as int) as review_rating,
        
        -- trim text
        trim(review_text) as review_text,
        
        -- timestamp
        cast(review_time as timestamp) as reviewed_at

    from raw_reviews
    where review_id is not null
)

-- remove duplicate review logs
select distinct * from cleaned_reviews