-- dim_date: one row per day of 2026. This one is FREE: we built it for you.
-- It uses dbt_utils.date_spine, a macro from the dbt_utils package (see packages.yml).
-- Join to it on a DATE column to get things like day_name and is_weekend.

with spine as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2026-01-01' as date)",
        end_date="cast('2027-01-01' as date)"
    ) }}

),

days as (

    select cast(date_day as date) as date_day
    from spine

)

select
    date_day,
    extract(year from date_day)                as year,
    extract(month from date_day)               as month_num,
    format_date('%B', date_day)                as month_name,
    format_date('%A', date_day)                as day_name,
    extract(dayofweek from date_day) in (1, 7) as is_weekend   -- 1 = Sunday, 7 = Saturday
from days
