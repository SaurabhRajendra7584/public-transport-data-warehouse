with source as (
    select
        cast(trip_id as string) as trip_id,
        safe_cast(service_date as date) as service_date,
        trim(cast(route_id as string)) as route_id,
        safe_cast(scheduled_departure as time) as scheduled_departure,
        safe_cast(actual_departure as time) as actual_departure,
        safe_cast(scheduled_arrival as time) as scheduled_arrival,
        safe_cast(actual_arrival as time) as actual_arrival,
        safe_cast(passenger_count as int64) as passenger_count,
        safe_cast(fare_amount as numeric) as fare_amount
    from {{ source('raw_transport', 'trips') }}
),
ranked as (
    select
        *,
        row_number() over (partition by trip_id order by service_date desc) as duplicate_rank
    from source
),
reasoned as (
    select
        *,
        case
            when trip_id is null or service_date is null or route_id is null or route_id = ''
              or scheduled_departure is null or actual_departure is null
              or scheduled_arrival is null or actual_arrival is null
              or passenger_count is null or fare_amount is null
                then 'required value missing or invalid'
            when passenger_count < 0 then 'passenger_count must be zero or greater'
            when fare_amount < 0 then 'fare_amount must be zero or greater'
            when duplicate_rank > 1 then 'duplicate trip_id'
        end as rejection_reason
    from ranked
)
select *
from reasoned
where rejection_reason is not null
