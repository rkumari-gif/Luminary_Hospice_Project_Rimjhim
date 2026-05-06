with source as (
    select * from {{ source('bronze', 'RAW_REFERRALS') }}
),

renamed as (
    select
        referral_id,
        patient_id,
        referral_date,
        trim(referral_source) as referral_source,
        trim(upper(referral_source_type)) as referral_source_type,
        referring_physician_npi,
        trim(referring_physician_name) as referring_physician_name,
        trim(referring_facility_name) as referring_facility_name,
        trim(upper(referral_status)) as referral_status,
        trim(upper(referral_outcome)) as referral_outcome,
        converted_to_admission_id,
        conversion_date,
        trim(decline_reason) as decline_reason,
        trim(pending_reason) as pending_reason,
        contact_date,
        evaluation_date,
        facility_id,
        trim(upper(primary_diagnosis_code)) as primary_diagnosis_code,
        trim(upper(payer_type)) as payer_type,
        created_date,
        modified_date,
        _loaded_at,
        _source_file,
        _row_hash
    from source
)

select * from renamed
