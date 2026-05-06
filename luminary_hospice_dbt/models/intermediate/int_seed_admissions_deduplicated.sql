with admissions as (
    select * from {{ ref('stg_seed_admissions') }}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by admission_id
            order by modified_date desc nulls last, _loaded_at desc
        ) as _rn
    from admissions
)

select
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
    _row_hash as _source_hash,
    {{ hash_key_generator(['admission_id', 'patient_id', 'episode_id', 'facility_id', 'admission_date', 'admission_type', 'admission_source', 'level_of_care', 'status']) }} as _hash_key
from deduplicated
where _rn = 1
