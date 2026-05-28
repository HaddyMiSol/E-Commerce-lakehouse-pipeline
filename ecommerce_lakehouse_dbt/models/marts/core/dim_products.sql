with products as (
    select * from {{ ref('stg_products') }}
),

aggregated_reviews as (
    select
        product_id,
        avg(review_rating) as avg_rating
    from {{ ref('stg_reviews') }}
    group by product_id
),

final as (
    select
        p.product_id,
        p.product_name,
        p.product_category,
        p.price_usd as unit_price,
        
        
        case
            when ar.avg_rating >= 4.5 then 'great'
            when ar.avg_rating between 3.0 and 4.49 then 'good'
            when ar.avg_rating < 3.0 then 'poor'
            else 'no review'
        end as rating_tier,
        
        
        coalesce(ar.avg_rating, 0.0) as average_review_rating
        
    from products p
    left join aggregated_reviews ar on p.product_id = ar.product_id
)

select * from final