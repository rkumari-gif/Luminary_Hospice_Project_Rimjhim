with source as (
    select * from {{ source('bronze', 'RAW_CARE_PLANS') }}
),

renamed as (
    select
        care_plan_id,
        patient_id,
        episode_id,
        trim(upper(plan_type)) as plan_type,
        effective_date,
        review_date,
        trim(upper(discipline)) as discipline,
        trim(visit_frequency) as visit_frequency,
        trim(goals) as goals,
        trim(upper(status)) as status,
        created_date,
        modified_date,
        _loaded_at,
        _source_file,
        _row_hash
    from source
)

select * from renamed
