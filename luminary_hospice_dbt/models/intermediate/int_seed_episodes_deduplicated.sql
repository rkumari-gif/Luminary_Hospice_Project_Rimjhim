with episodes as (
    select * from {{ ref('stg_seed_episodes') }}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by episode_id
            order by modified_date desc nulls last, _loaded_at desc
        ) as _rn
    from episodes
)

select
    episode_id,
    patient_id,
    facility_id,
    episode_start_date,
    episode_end_date,
    episode_type,
    benefit_period,
    certification_start_date,
    certification_end_date,
    recertification_date,
    level_of_care,
    primary_diagnosis_code,
    primary_diagnosis_desc,
    payer_type,
    payer_name,
    election_date,
    revocation_date,
    datediff('day', episode_start_date, coalesce(episode_end_date, current_date())) as length_of_stay,
    iff(episode_end_date is null and status = 'ACTIVE', true, false) as is_active,
    status,
    _loaded_at,
    _row_hash as _source_hash,
    {{ hash_key_generator(['episode_id', 'patient_id', 'facility_id', 'episode_start_date', 'episode_end_date', 'episode_type', 'level_of_care', 'payer_type', 'status']) }} as _hash_key
from deduplicated
where _rn = 1
