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
)

select
    budget_id,
    facility_id,
    budget_year,
    budget_month,
    to_date(budget_date) as budget_date,
    case when adc_budget < 0 then 0 else round(adc_budget, 2) end as adc_budget,
    case when admissions_budget < 0 then 0 else round(admissions_budget, 0) end as admissions_budget,
    case when discharges_budget < 0 then 0 else round(discharges_budget, 0) end as discharges_budget,
    case when referrals_budget < 0 then 0 else round(referrals_budget, 0) end as referrals_budget,
    case when revenue_budget < 0 then 0 else round(revenue_budget, 2) end as revenue_budget,
    case when expense_budget < 0 then 0 else round(expense_budget, 2) end as expense_budget,
    case when fte_budget < 0 then 0 else round(fte_budget, 2) end as fte_budget,
    round(revenue_budget - expense_budget, 2) as net_margin_budget,
    round(
        case
            when revenue_budget > 0
            then (revenue_budget - expense_budget) / revenue_budget
            else 0
        end, 2
    ) as margin_pct,
    _loaded_at,
    _row_hash
from deduplicated
where _rn = 1
