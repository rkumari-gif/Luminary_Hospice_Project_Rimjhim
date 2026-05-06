{{
    config(
        materialized='incremental',
        unique_key='budget_id',
        incremental_strategy='merge'
    )
}}

with budget as (
    select * from {{ ref('int_budget_deduplicated') }}
    {% if is_incremental() %}
    where _loaded_at > (select max(_loaded_at) from {{ this }})
    {% endif %}
)

select
    {{ hash_key_generator(['budget_id']) }} as pk_budget,
    budget_id,
    facility_id,
    budget_year,
    budget_month,
    budget_date,
    adc_budget,
    admissions_budget,
    discharges_budget,
    referrals_budget,
    revenue_budget,
    expense_budget,
    fte_budget,
    _loaded_at,
    current_timestamp() as _updated_at,
    _row_hash
from budget
