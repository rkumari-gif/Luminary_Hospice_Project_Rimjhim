with source as (
    select * from {{ source('bronze', 'RAW_BUDGET') }}
),

renamed as (
    select
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
        created_date,
        modified_date,
        _loaded_at,
        _source_file,
        _row_hash
    from source
)

select * from renamed
