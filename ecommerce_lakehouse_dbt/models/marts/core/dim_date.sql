with date_part as (
    {{ dbt_utils.date_spine(
        datepart = "day",
        start_date="(select cast(min(ordered_at) as date) from " ~ ref('stg_orders') ~ ")",
        end_date="date_add(current_date(), 365)"
    ) }}
),

final as (
    select 
        cast(date_day as date) as date_id,
        year(date_day) as calender_year,
        quarter(date_day) as calender_quarter,
        month(date_day) as month_number,
        date_format(date_day, 'MMMM') as month_name,
        dayofweek(date_day) as day_of_week_number,
        date_format(date_day, 'EEEE') as day_of_week_name,
        case
            when dayofweek(date_day) in (1,7) then 'Weekend'
            else 'Weekday'
        end as is_weekend

    from date_part

)

select * from final