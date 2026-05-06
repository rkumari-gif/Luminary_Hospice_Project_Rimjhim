with source as (
    select * from {{ source('bronze', 'RAW_PATIENTS') }}
),

renamed as (
    select
        patient_id,
        trim(upper(first_name)) as first_name,
        trim(upper(last_name)) as last_name,
        date_of_birth,
        trim(upper(gender)) as gender,
        ssn_last_four,
        trim(upper(primary_diagnosis_code)) as primary_diagnosis_code,
        trim(primary_diagnosis_desc) as primary_diagnosis_desc,
        trim(upper(payer_type)) as payer_type,
        trim(payer_name) as payer_name,
        medicare_id,
        medicaid_id,
        insurance_id,
        trim(address_line_1) as address_line_1,
        trim(address_line_2) as address_line_2,
        trim(upper(city)) as city,
        trim(upper(state)) as state,
        trim(zip_code) as zip_code,
        trim(upper(county)) as county,
        phone_primary,
        phone_secondary,
        emergency_contact_name,
        emergency_contact_phone,
        attending_physician_npi,
        trim(attending_physician_name) as attending_physician_name,
        trim(upper(status)) as status,
        created_date,
        modified_date,
        _loaded_at,
        _source_file,
        _row_hash
    from source
)

select * from renamed
