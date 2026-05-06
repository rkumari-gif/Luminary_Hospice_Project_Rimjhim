with source as (
    select * from {{ source('bronze', 'RAW_STAFF') }}
),

renamed as (
    select
        staff_id,
        trim(upper(first_name)) as first_name,
        trim(upper(last_name)) as last_name,
        trim(upper(discipline)) as discipline,
        trim(upper(role)) as role,
        npi,
        license_number,
        facility_id,
        team_id,
        hire_date,
        termination_date,
        lower(trim(email)) as email,
        phone,
        trim(upper(status)) as status,
        created_date,
        modified_date,
        _loaded_at,
        _source_file,
        _row_hash
    from source
)

select * from renamed
