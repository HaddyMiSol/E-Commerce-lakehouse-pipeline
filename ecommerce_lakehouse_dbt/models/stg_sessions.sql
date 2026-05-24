{{ config(
    materialized='table',
    file_format='delta'
) }}

with raw_sessions as (
    select * from {{ source('bronze_layer', 'sessions') }}
),

cleaned_sessions as (
    select
        -- primary & foreign keys
        cast(session_id as int) as session_id,
        cast(customer_id as int) as customer_id,
        
        -- timestamp
        cast(start_time as timestamp) as session_started_at,
        
        -- trim text
        lower(trim(device)) as device_type,
        lower(trim(source)) as traffic_source,
        lower(trim(country)) as session_country

    from raw_sessions
    where session_id is not null
)

-- deduplicate tracking entries
select distinct * from cleaned_sessions