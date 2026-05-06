{{
    config(
        materialized='incremental',
        unique_key='census_id',
        incremental_strategy='merge'
    )
}}

with census as (
    select * from {{ ref('int_census_deduplicated') }}
    {% if is_incremental() %}
    where _loaded_at > (select max(_loaded_at) from {{ this }})
    {% endif %}
)

select
    {{ hash_key_generator(['census_id']) }} as pk_census,
    census_id,
    census_date,
    patient_id,
    episode_id,
    facility_id,
    level_of_care,
    service_type,
    payer_type,
    payer_name,
    attending_physician_npi,
    primary_nurse_id,
    status,
    _loaded_at,
    current_timestamp() as _updated_at,
    _row_hash
from census
