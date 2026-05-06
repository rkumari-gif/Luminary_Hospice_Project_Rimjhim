with source as (
    select * from {{ source('bronze', 'RAW_BILLING_CLAIMS') }}
),

renamed as (
    select
        claim_id,
        patient_id,
        episode_id,
        facility_id,
        trim(upper(claim_type)) as claim_type,
        trim(upper(claim_status)) as claim_status,
        service_from_date,
        service_to_date,
        trim(upper(level_of_care)) as level_of_care,
        revenue_code,
        hcpcs_code,
        billed_amount,
        allowed_amount,
        paid_amount,
        adjustment_amount,
        trim(upper(payer_type)) as payer_type,
        trim(payer_name) as payer_name,
        submission_date,
        payment_date,
        denial_reason_code,
        created_date,
        modified_date,
        _loaded_at,
        _source_file,
        _row_hash
    from source
)

select * from renamed
