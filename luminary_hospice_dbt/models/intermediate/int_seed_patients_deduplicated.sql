with patients as (
    select * from {{ ref('stg_seed_patients') }}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by patient_id
            order by modified_date desc nulls last, _loaded_at desc
        ) as _rn
    from patients
)

select
    patient_id,
    first_name,
    last_name,
    first_name || ' ' || last_name as full_name,
    date_of_birth,
    datediff('year', date_of_birth, current_date()) as age,
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
    coalesce(created_date, _loaded_at) as effective_from,
    _loaded_at,
    _row_hash as _source_hash,
    {{ hash_key_generator(['patient_id', 'first_name', 'last_name', 'date_of_birth', 'gender', 'primary_diagnosis_code', 'payer_type', 'city', 'state', 'attending_physician_npi', 'status']) }} as _hash_key
from deduplicated
where _rn = 1
