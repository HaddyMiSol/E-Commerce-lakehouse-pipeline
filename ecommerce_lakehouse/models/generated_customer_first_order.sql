{{ config(
    materialized='table',
    file_format='delta'
) }}

with customers as (
    select customer_id, signup_date from {{ ref("stg_customers") }}
),

first_orders as (
    select 
            customer_id,
            min(cast(ordered_at as date)) as first_order_date
    from {{ ref("stg_orders") }}
    group by customer_id
)

select
    c.customer_id,
    case 
        when c.signup_date > f.first_order_date then f.first_order_date
        else c.signup_date
    end as signup_date,
    f.first_order_date
from customers c
inner join first_orders f
where c.customer_id = f.customer_id
