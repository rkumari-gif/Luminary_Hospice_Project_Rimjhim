with source as (
    select * from {{ source('bronze', 'RAW_DIAGNOSES') }}
),

renamed as (
    select
        diagnosis_id,
        patient_id,
        episode_id,
        trim(upper(icd10_code)) as icd10_code,
        trim(diagnosis_description) as diagnosis_description,
        trim(upper(diagnosis_type)) as diagnosis_type,
        diagnosis_rank,
        onset_date,
        resolved_date,
        trim(upper(status)) as status,
        created_date,
        modified_date,
        _loaded_at,
        _source_file,
        _row_hash
    from source
)

select * from renamed
