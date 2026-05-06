with source as (
    select * from {{ ref('raw_patients_seed') }}
),

renamed as (
    select
        PATID as patient_id,
        trim(upper(FNAME)) as first_name,
        trim(upper(LNAME)) as last_name,
        DOB as date_of_birth,
        trim(upper(GNDR)) as gender,
        SSN4 as ssn_last_four,
        trim(upper(PRIMARYDXCODE)) as primary_diagnosis_code,
        trim(PRIMARYDXDESC) as primary_diagnosis_desc,
        trim(upper(PAYERTYP)) as payer_type,
        trim(PAYER_NAME) as payer_name,
        MEDICARE_NBR as medicare_id,
        MEDICAID_NBR as medicaid_id,
        INS_ID as insurance_id,
        trim(ADDR1) as address_line_1,
        trim(ADDR2) as address_line_2,
        trim(upper(PATCITY)) as city,
        trim(upper(ST)) as state,
        trim(cast(ZIPCD as varchar)) as zip_code,
        trim(upper(CNTY)) as county,
        cast(PRIMARYPH as varchar) as phone_primary,
        cast(SECONDARYPH as varchar) as phone_secondary,
        EMRGCONTACTNM as emergency_contact_name,
        cast(EMRGCONTACTPH as varchar) as emergency_contact_phone,
        cast(ATTPHYSNPI as varchar) as attending_physician_npi,
        trim(ATTPHYSNAME) as attending_physician_name,
        trim(upper(PAT_STATUS)) as status,
        CREATE_DT as created_date,
        MODIFY_DT as modified_date,
        current_timestamp() as _loaded_at,
        'raw_patients_seed' as _source_file
    from source
)

select
    *,
    {{ hash_key_generator(['patient_id', 'first_name', 'last_name', 'date_of_birth', 'gender', 'primary_diagnosis_code', 'payer_type', 'status']) }} as _row_hash
from renamed
