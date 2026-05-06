with source as (
    select * from {{ source('bronze', 'RAW_MEDICATIONS') }}
),

renamed as (
    select
        medication_id,
        patient_id,
        episode_id,
        ndc_code,
        trim(medication_name) as medication_name,
        trim(dosage) as dosage,
        trim(frequency) as frequency,
        trim(upper(route)) as route,
        prescriber_npi,
        start_date,
        end_date,
        hospice_related,
        trim(upper(status)) as status,
        created_date,
        modified_date,
        _loaded_at,
        _source_file,
        _row_hash
    from source
)

select * from renamed
