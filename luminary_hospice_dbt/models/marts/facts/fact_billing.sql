{{
    config(
        materialized='incremental',
        unique_key='claim_id',
        incremental_strategy='merge'
    )
}}

with billing as (
    select * from {{ ref('int_billing_deduplicated') }}
    {% if is_incremental() %}
    where _loaded_at > (select max(_loaded_at) from {{ this }})
    {% endif %}
)

select
    {{ hash_key_generator(['claim_id']) }} as pk_billing,
    claim_id,
    patient_id,
    episode_id,
    facility_id,
    claim_type,
    claim_status,
    service_from_date,
    service_to_date,
    level_of_care,
    revenue_code,
    hcpcs_code,
    billed_amount,
    allowed_amount,
    paid_amount,
    adjustment_amount,
    payer_type,
    payer_name,
    submission_date,
    payment_date,
    days_to_payment,
    denial_reason_code,
    is_denied,
    _loaded_at,
    current_timestamp() as _updated_at,
    _row_hash
from billing
