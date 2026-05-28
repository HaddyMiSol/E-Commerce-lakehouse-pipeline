with sessions as (
    select * from {{ref('stg_sessions')}}
),

first_customer_contact as (
    select 
        customer_id,
        session_id,
        session_started_at,
        traffic_source,
        session_country,
        row_number() over (partition by customer_id order by session_started_at asc) as row_number

    from sessions
    where traffic_source is not null
),

acquisition_channels as (
    select 
        customer_id,
        session_id as acquisition_session_id,
        session_started_at as acquired_at,
        traffic_source
    from first_customer_contact
    where row_number = 1
),


final as (
    select 
        {{ dbt_utils.generate_surrogate_key(['traffic_source']) }} as channel_key,
        customer_id,
        acquisition_session_id,
        traffic_source as channel_name,

        case 
            -- add more channel to capture other kind of channel as the data grows
            when lower(traffic_source) in ('facebook', 'instagram', 'tiktok', 'twitter', 'social') then 'Paid Social'
            when lower(traffic_source) in ('google', 'bing', 'cpc', 'paid') then 'Paid Search'
            when lower(traffic_source) in ('newsletter', 'email', 'promo_email') then 'Email Marketing'
            when lower(traffic_source) in ('organic', 'direct', 'search') then 'Organic/Inbound'
            else 'Referral/Other'
        end as channel_type,

        acquired_at

    from acquisition_channels

)

select * from final
