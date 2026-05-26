with products as (
    select * from {{ ref('stg_products') }}
),

reviews as (
    select * from {{ ref("stg_reviews")}}
),

final as (
    select
        p.product_id,
        p.product_name,
        p.product_category,
        p.price_usd as unit_price,
        case
            when r.review_rating = 5 then 'great'
            when r.review_rating between 3 and 4 then 'good'
            when r.review_rating < 3 then 'poor'
            else 'no review'
        end as rating_tier
    from products p
    left join reviews r on p.product_id = r.product_id
)

select * from final