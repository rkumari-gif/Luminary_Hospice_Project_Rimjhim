with source as (
    select * from {{ source('bronze', 'RAW_FACILITIES') }}
),

renamed as (
    select
        facility_id,
        trim(facility_name) as facility_name,
        trim(upper(facility_type)) as facility_type,
        npi,
        ccn,
        license_number,
        trim(address_line_1) as address_line_1,
        trim(upper(city)) as city,
        trim(upper(state)) as state,
        trim(zip_code) as zip_code,
        trim(upper(county)) as county,
        phone,
        fax,
        total_bed_capacity,
        ipu_bed_capacity,
        trim(upper(region)) as region,
        trim(upper(status)) as status,
        created_date,
        modified_date,
        _loaded_at,
        _source_file,
        _row_hash
    from source
)

select * from renamed
