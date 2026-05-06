{{
    config(
        materialized='incremental',
        unique_key='discharge_id',
        incremental_strategy='merge'
    )
}}

with discharges as (
    select * from {{ ref('int_discharges_deduplicated') }}
    {% if is_incremental() %}
    where _loaded_at > (select max(_loaded_at) from {{ this }})
    {% endif %}
)

select
    {{ hash_key_generator(['discharge_id']) }} as pk_discharge,
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
    current_timestamp() as _updated_at,
    _row_hash
from discharges
