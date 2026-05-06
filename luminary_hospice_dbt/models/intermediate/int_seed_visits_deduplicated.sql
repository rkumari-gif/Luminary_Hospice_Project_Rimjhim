with visits as (
    select * from {{ ref('stg_seed_visits') }}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by visit_id
            order by modified_date desc nulls last, _loaded_at desc
        ) as _rn
    from visits
)

select
    visit_id,
    patient_id,
    episode_id,
    staff_id,
    facility_id,
    visit_date,
    visit_start_time,
    visit_end_time,
    datediff('minute', visit_start_time, visit_end_time) as visit_duration_minutes,
    discipline,
    visit_type,
    visit_status,
    mileage,
    _loaded_at,
    _row_hash as _source_hash,
    {{ hash_key_generator(['visit_id', 'patient_id', 'episode_id', 'staff_id', 'visit_date', 'discipline', 'visit_type', 'visit_status']) }} as _hash_key
from deduplicated
where _rn = 1
