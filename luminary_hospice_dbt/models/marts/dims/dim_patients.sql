{{ config(materialized='table') }}

with patients as (
    select * from {{ ref('int_patients_deduplicated') }}
    where is_current = true
)

select
    {{ hash_key_generator(['patient_id']) }} as pk_patient,
    patient_id,
    first_name,
    last_name,
    full_name,
    date_of_birth,
    age_validated as age,
    gender,
    primary_diagnosis_code,
    primary_diagnosis_desc,
    payer_type,
    payer_name,
    medicare_id,
    medicaid_id,
    city,
    state,
    zip_code,
    county,
    attending_physician_npi,
    attending_physician_name,
    status,
    is_current,
    effective_from,
    effective_to,
    _loaded_at,
    current_timestamp() as _updated_at,
    _row_hash
from patients
