{{
    config(
        materialized='incremental',
        unique_key='visit_id',
        incremental_strategy='merge'
    )
}}

with visits as (
    select * from {{ ref('int_visits_deduplicated') }}
    {% if is_incremental() %}
    where _loaded_at > (select max(_loaded_at) from {{ this }})
    {% endif %}
)

select
    {{ hash_key_generator(['visit_id']) }} as pk_visit,
    visit_id,
    patient_id,
    episode_id,
    staff_id,
    facility_id,
    visit_date,
    visit_start_time,
    visit_end_time,
    visit_duration_minutes,
    discipline,
    visit_type,
    visit_status,
    mileage,
    _loaded_at,
    current_timestamp() as _updated_at,
    _row_hash
from visits
