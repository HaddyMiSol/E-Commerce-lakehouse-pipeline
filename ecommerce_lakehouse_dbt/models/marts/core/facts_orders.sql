with orders as (
    select * from {{ref("stg_orders")}}
),

order_items as (
    select * FROM {{ref("stg_order_items")}}
),

final as (
    select
            o.order_id,
            o.customer_id,
            oi.product_id,
            o.ordered_at,
            oi.quantity,
            oi.unit_price_usd,
            cast(oi.quantity * oi.unit_price_usd as decimal(10,2)) as calculated_line_total_usd,
            o.amount_before_discount_usd,
            o.amount_after_discount_usd,
            o.discount_percentage
    from
        orders o
        left join order_items oi on o.order_id = oi.order_id
)

select * from final