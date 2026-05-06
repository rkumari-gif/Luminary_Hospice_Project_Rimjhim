with source as (
    select * from {{ source('bronze', 'RAW_CLINICAL_ASSESSMENTS') }}
),

renamed as (
    select
        assessment_id,
        patient_id,
        episode_id,
        trim(upper(assessment_type)) as assessment_type,
        assessment_date,
        assessor_staff_id,
        pps_score,
        pain_level,
        trim(upper(functional_status)) as functional_status,
        oasis_assessment_flag,
        trim(upper(status)) as status,
        created_date,
        modified_date,
        _loaded_at,
        _source_file,
        _row_hash
    from source
)

select * from renamed
