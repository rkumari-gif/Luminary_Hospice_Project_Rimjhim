{{
    config(
        materialized='incremental',
        unique_key='episode_id',
        incremental_strategy='merge'
    )
}}

with episodes as (
    select * from {{ ref('int_episodes_deduplicated') }}
    {% if is_incremental() %}
    where _loaded_at > (select max(_loaded_at) from {{ this }})
    {% endif %}
)

select
    {{ hash_key_generator(['episode_id']) }} as pk_episode,
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
    length_of_stay,
    is_active,
    status,
    _loaded_at,
    current_timestamp() as _updated_at,
    _row_hash
from episodes
