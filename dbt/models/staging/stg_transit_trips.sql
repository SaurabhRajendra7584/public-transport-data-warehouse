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
valid as (
    select *
    from source
    where trip_id is not null
      and service_date is not null
      and route_id is not null
      and route_id != ''
      and scheduled_departure is not null
      and actual_departure is not null
      and scheduled_arrival is not null
      and actual_arrival is not null
      and passenger_count >= 0
      and fare_amount >= 0
    qualify row_number() over (partition by trip_id order by service_date desc) = 1
),
with_delay as (
    select
        *,
        time_diff(actual_arrival, scheduled_arrival, minute)
        + 1440 * (
            if(actual_arrival < actual_departure, 1, 0)
            - if(scheduled_arrival < scheduled_departure, 1, 0)
        ) as arrival_delay_minutes
    from valid
)
select
    *,
    arrival_delay_minutes <= 5 as on_time
from with_delay
