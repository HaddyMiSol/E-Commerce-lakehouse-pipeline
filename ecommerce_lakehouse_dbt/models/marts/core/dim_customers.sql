with customers as (
    select * from {{ ref('stg_customers') }}
),

order_metrics as (
    select
        customer_id,
        count(distinct order_id) as total_orders,
        min(ordered_at) as first_order_date,
        max(ordered_at) as most_recent_order_date,
        sum(calculated_line_total_usd) as lifetime_value
    from {{ ref('facts_orders') }}
    group by customer_id
),

acquisition_channels as (
    select 
        customer_id,
        channel_name,
        channel_type,
        acquired_at
    from {{ ref('dim_channels') }}
),

final as (
    select
        c.customer_id,
        c.full_name,

        case
            when c.age <15 then '<15'
            when c.age between 15 and 24 then '15-14'
            when c.age between 25 and 39 then '24-39'
            when c.age between 40 and 49 then '40-49'
            when c.age >=50 then '50+'
            else 'others'
        end as age_group,

        c.email,
        c.country,
        c.signup_date,
        coalesce(om.total_orders, 0) as total_orders,
        coalesce(om.lifetime_value, 0.00) as lifetime_value,
        om.first_order_date,
        om.most_recent_order_date,
        datediff(om.first_order_date, c.signup_date) as days_to_first_purchase,
        
        case 
            when om.total_orders >= 5 then 'VIP'
            when om.total_orders between 2 and 4 then 'Repeat'
            when om.total_orders = 1 then 'One-Time'
            else 'Prospect'
        end as customer_segment,

        case
            when c.signup_date > om.most_recent_order_date then 'signedup_after_last_order'
            when c.signup_date < om.first_order_date then 'signedup_before_order'
            when c.signup_date > om.first_order_date and c.signup_date < om.most_recent_order_date then 'signedup_after_first_order'
            else 'No order'
        end as signup_order_period,

        ac.channel_type


    from customers c
    left join order_metrics om on c.customer_id = om.customer_id
    left join acquisition_channels ac on c.customer_id = ac.customer_id
)

select * from final