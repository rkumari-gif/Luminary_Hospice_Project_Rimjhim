with source as (
    select * from {{ source('bronze', 'RAW_DISCHARGES') }}
),

renamed as (
    select
        discharge_id,
        patient_id,
        episode_id,
        admission_id,
        facility_id,
        discharge_date,
        trim(upper(discharge_reason)) as discharge_reason,
        trim(upper(discharge_disposition)) as discharge_disposition,
        length_of_stay,
        trim(upper(final_level_of_care)) as final_level_of_care,
        death_date,
        trim(upper(death_location)) as death_location,
        trim(upper(status)) as status,
        created_date,
        modified_date,
        _loaded_at,
        _source_file,
        _row_hash
    from source
)

select * from renamed
