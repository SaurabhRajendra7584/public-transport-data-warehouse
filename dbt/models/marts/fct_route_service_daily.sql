{{
    config(
        materialized='incremental',
        unique_key=['service_date', 'route_id'],
        partition_by={
            'field': 'service_date',
            'data_type': 'date',
            'granularity': 'day'
        },
        cluster_by=['route_id']
    )
}}

select
    service_date,
    route_id,
    count(*) as trip_count,
    sum(passenger_count) as total_passengers,
    sum(fare_amount) as total_fare,
    round(avg(arrival_delay_minutes), 2) as average_arrival_delay_minutes,
    countif(on_time) as on_time_trip_count,
    round(100 * safe_divide(countif(on_time), count(*)), 2) as on_time_percentage
from {{ ref('stg_transit_trips') }}
{% if is_incremental() %}
where service_date >= date_sub((select max(service_date) from {{ this }}), interval 7 day)
{% endif %}
group by service_date, route_id
