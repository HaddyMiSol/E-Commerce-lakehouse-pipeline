with events as (
    select * from {{ ref('stg_events') }}
),

sessions as (
    select * from {{ ref("stg_sessions") }}
), 

session_aggregation as (
    select
        s.session_id,
        s.customer_id,
        min(e.event_at) as session_started_at,
        max(e.event_at) as session_ended_at,
        count(e.event_id) as total_interactions,
        count(case when e.event_type = 'page_view' then 1 end) as page_views,
        count(case when e.event_type = 'add_to_cart' then 1 end) as cart_additions,    
        max(case when e.event_type = 'checkout' then 1 else 0 end) as converted_to_checkout

    from events e
    right join sessions s on e.session_id = s.session_id
    group by s.session_id, s.customer_id
)

select
    *,
    datediff(second, session_started_at, session_ended_at) as session_duration_seconds
from session_aggregation