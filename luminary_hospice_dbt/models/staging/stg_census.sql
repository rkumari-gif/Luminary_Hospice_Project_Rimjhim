with source as (
    select * from {{ source('bronze', 'RAW_CENSUS') }}
),

renamed as (
    select
        census_id,
        census_date,
        patient_id,
        episode_id,
        facility_id,
        trim(upper(level_of_care)) as level_of_care,
        trim(upper(service_type)) as service_type,
        trim(upper(payer_type)) as payer_type,
        trim(payer_name) as payer_name,
        bed_id,
        room_id,
        unit_id,
        attending_physician_npi,
        primary_nurse_id,
        trim(upper(status)) as status,
        created_date,
        modified_date,
        _loaded_at,
        _source_file,
        _row_hash
    from source
)

select * from renamed
