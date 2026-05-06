with referrals as (
    select * from {{ ref('stg_referrals') }}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by referral_id
            order by modified_date desc nulls last, _loaded_at desc
        ) as _rn
    from referrals
)

select
    referral_id,
    patient_id,
    referral_date,
    referral_source,
    referral_source_type,
    referring_physician_npi,
    referring_physician_name,
    referring_facility_name,
    referral_status,
    referral_outcome,
    converted_to_admission_id,
    conversion_date,
    decline_reason,
    pending_reason,
    contact_date,
    evaluation_date,
    facility_id,
    primary_diagnosis_code,
    payer_type,
    datediff('day', referral_date, contact_date) as days_to_contact,
    datediff('day', referral_date, evaluation_date) as days_to_evaluation,
    datediff('day', referral_date, conversion_date) as days_to_conversion,
    iff(converted_to_admission_id is not null, true, false) as is_converted,
    iff(referral_status = 'PENDING', true, false) as is_pending,
    referral_status as status,
    _loaded_at,
    _row_hash
from deduplicated
where _rn = 1
