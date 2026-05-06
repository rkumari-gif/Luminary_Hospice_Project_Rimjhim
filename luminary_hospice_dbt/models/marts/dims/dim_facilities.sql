{{ config(materialized='table') }}

with facilities as (
    select * from {{ ref('int_facilities_deduplicated') }}
)

select
    {{ hash_key_generator(['facility_id']) }} as pk_facility,
    facility_id,
    facility_name,
    facility_type,
    npi,
    ccn,
    city,
    state,
    zip_code,
    county,
    region,
    total_bed_capacity,
    ipu_bed_capacity,
    status,
    true as is_current,
    effective_from,
    null::timestamp_ntz as effective_to,
    _loaded_at,
    current_timestamp() as _updated_at,
    _row_hash
from facilities
