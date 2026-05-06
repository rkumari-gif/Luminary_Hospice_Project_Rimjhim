with source as (
    select * from {{ source('bronze', 'RAW_ADMISSIONS') }}
),

renamed as (
    select
        admission_id,
        patient_id,
        episode_id,
        facility_id,
        admission_date,
        trim(upper(admission_type)) as admission_type,
        trim(upper(admission_source)) as admission_source,
        referral_id,
        trim(upper(level_of_care)) as level_of_care,
        trim(upper(service_type)) as service_type,
        trim(upper(primary_diagnosis_code)) as primary_diagnosis_code,
        attending_physician_npi,
        nurse_id,
        aide_id,
        social_worker_id,
        chaplain_id,
        trim(upper(status)) as status,
        created_date,
        modified_date,
        _loaded_at,
        _source_file,
        _row_hash
    from source
)

select * from renamed
