{{ config(materialized='table') }}

with date_spine as (
    select
        dateadd('day', seq4(), '2000-01-01'::date) as date_day
    from table(generator(rowcount => 13149))
),

dates as (
    select
        date_day,
        dayofweek(date_day) as day_of_week,
        dayname(date_day) as day_name,
        day(date_day) as day_of_month,
        dayofyear(date_day) as day_of_year,
        weekofyear(date_day) as week_of_year,
        last_day(date_day, 'week') as week_end_date,
        month(date_day) as month_number,
        monthname(date_day) as month_name,
        left(monthname(date_day), 3) as month_short,
        date_trunc('month', date_day)::date as month_start_date,
        last_day(date_day, 'month') as month_end_date,
        quarter(date_day) as quarter_number,
        'Q' || quarter(date_day) as quarter_name,
        date_trunc('quarter', date_day)::date as quarter_start_date,
        last_day(date_day, 'quarter') as quarter_end_date,
        year(date_day) as year_number,
        date_trunc('year', date_day)::date as year_start_date,
        last_day(date_day, 'year') as year_end_date,
        dateadd('year', -1, date_day) as prior_year_date_day,
        dateadd('year', -1, date_trunc('month', date_day))::date as prior_year_month_start_date,
        case
            when month(date_day) >= 10 then year(date_day) + 1
            else year(date_day)
        end as fiscal_year,
        case
            when month(date_day) >= 10 then month(date_day) - 9
            when month(date_day) >= 7 then 4
            when month(date_day) >= 4 then 3
            else ceil(month(date_day) / 3.0)
        end as fiscal_quarter,
        case when dayofweek(date_day) in (0, 6) then true else false end as is_weekend,
        false as is_holiday,
        null::varchar(100) as holiday_name
    from date_spine
    where date_day <= '2035-12-31'::date
),

final as (
    select
        {{ hash_key_generator(['date_day', "'calendar'"]) }} as pk_date,
        dates.*
    from dates
)

select * from final
