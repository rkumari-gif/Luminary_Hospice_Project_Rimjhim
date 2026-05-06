with discharges as (
    select * from {{ ref('stg_discharges') }}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by discharge_id
            order by modified_date desc nulls last, _loaded_at desc
        ) as _rn
    from discharges
)

select
    discharge_id,
    patient_id,
    episode_id,
    admission_id,
    facility_id,
    discharge_date,
    discharge_reason,
    discharge_disposition,
    length_of_stay,
    final_level_of_care,
    death_date,
    death_location,
    status,
    _loaded_at,
    _row_hash
from deduplicated
where _rn = 1
