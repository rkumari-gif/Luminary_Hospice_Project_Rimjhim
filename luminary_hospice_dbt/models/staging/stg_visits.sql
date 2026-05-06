with source as (
    select * from {{ source('bronze', 'RAW_VISITS') }}
),

renamed as (
    select
        visit_id,
        patient_id,
        episode_id,
        staff_id,
        facility_id,
        visit_date,
        visit_start_time,
        visit_end_time,
        trim(upper(discipline)) as discipline,
        trim(upper(visit_type)) as visit_type,
        trim(upper(visit_status)) as visit_status,
        mileage,
        created_date,
        modified_date,
        _loaded_at,
        _source_file,
        _row_hash
    from source
)

select * from renamed
