with budget as (
    select * from {{ ref('stg_budget') }}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by budget_id
            order by modified_date desc nulls last, _loaded_at desc
        ) as _rn
    from budget
),

base as (
    select
        budget_id,
        facility_id,
        budget_year,
        budget_month,
        to_date(budget_date) as budget_date,
        case when adc_budget < 0 then 0.0 else round(adc_budget, 2)::float end as adc_budget,
        case when admissions_budget < 0 then 0.0 else admissions_budget::float end as admissions_budget,
        case when discharges_budget < 0 then 0.0 else discharges_budget::float end as discharges_budget,
        case when referrals_budget < 0 then 0.0 else referrals_budget::float end as referrals_budget,
        case when revenue_budget < 0 then 0.0 else round(revenue_budget, 2)::float end as revenue_budget,
        case when expense_budget < 0 then 0.0 else round(expense_budget, 2)::float end as expense_budget,
        case when fte_budget < 0 then 0.0 else round(fte_budget, 2)::float end as fte_budget,
        round(revenue_budget - expense_budget, 2)::float as net_margin_budget,
        round(
            case
                when revenue_budget > 0
                then (revenue_budget - expense_budget) / revenue_budget
                else 0
            end, 2
        )::float as margin_pct,
        round(
            case
                when adc_budget > 0
                then revenue_budget / (adc_budget * day(last_day(budget_date)))
                else 0
            end, 2
        )::float as revenue_per_patient_day,
        _loaded_at,
        _row_hash
    from deduplicated
    where _rn = 1
),

unpivoted as (
    select
        budget_id,
        facility_id,
        budget_year,
        budget_month,
        budget_date,
        metric_name,
        metric_value,
        _loaded_at,
        _row_hash
    from base
    unpivot(
        metric_value for metric_name in (
            adc_budget,
            admissions_budget,
            discharges_budget,
            referrals_budget,
            revenue_budget,
            expense_budget,
            fte_budget,
            net_margin_budget,
            margin_pct,
            revenue_per_patient_day
        )
    )
)

select * from unpivoted
