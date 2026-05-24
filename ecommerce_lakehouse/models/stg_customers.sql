{{ config(
    materialized='table',
    file_format='delta'
) }}

with raw_customers as (
    
    select * from {{ source('bronze_layer', 'customers') }}
),

cleaned_customers as (
    select
        -- cast IDs to integers
        cast(customer_id as int) as customer_id,
        
        -- clean up text names 
        trim(name) as full_name,
        trim(marketing_opt_in) as marketing_opt_in,
        
        -- standardize email strings to lowercase
        lower(trim(email)) as email,
        
        -- cast dates from raw text to Date data types
        cast(signup_date as date) as signup_date,
        
        -- handle nulls or blanks in country data
        coalesce(trim(country), 'Unknown') as country,

        -- cast age to integers
        cast(age as int) as age

    from raw_customers
)

-- Select the final cleaned dataset and deduplicate based on primary key
select distinct * from cleaned_customers