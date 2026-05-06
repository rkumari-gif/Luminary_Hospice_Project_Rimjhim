{{
    config(
        materialized='incremental',
        unique_key='referral_id',
        incremental_strategy='merge'
    )
}}

with referrals as (
    select * from {{ ref('int_referrals_deduplicated') }}
    {% if is_incremental() %}
    where _loaded_at > (select max(_loaded_at) from {{ this }})
    {% endif %}
)

select
    {{ hash_key_generator(['referral_id']) }} as pk_referral,
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
    days_to_contact,
    days_to_evaluation,
    days_to_conversion,
    is_converted,
    is_pending,
    status,
    _loaded_at,
    current_timestamp() as _updated_at,
    _row_hash
from referrals
