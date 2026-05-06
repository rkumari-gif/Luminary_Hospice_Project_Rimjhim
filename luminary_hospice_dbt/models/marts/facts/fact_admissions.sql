{{
    config(
        materialized='incremental',
        unique_key='admission_id',
        incremental_strategy='merge'
    )
}}

with admissions as (
    select * from {{ ref('int_admissions_deduplicated') }}
    {% if is_incremental() %}
    where _loaded_at > (select max(_loaded_at) from {{ this }})
    {% endif %}
)

select
    {{ hash_key_generator(['admission_id']) }} as pk_admission,
    admission_id,
    patient_id,
    episode_id,
    facility_id,
    referral_id,
    admission_date,
    admission_type,
    admission_source,
    level_of_care,
    service_type,
    primary_diagnosis_code,
    status,
    _loaded_at,
    current_timestamp() as _updated_at,
    _row_hash
from admissions
