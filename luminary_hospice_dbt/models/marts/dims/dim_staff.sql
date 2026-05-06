{{ config(materialized='table') }}

with staff as (
    select * from {{ ref('int_staff_deduplicated') }}
)

select
    {{ hash_key_generator(['staff_id']) }} as pk_staff,
    staff_id,
    first_name,
    last_name,
    full_name,
    discipline,
    role,
    npi,
    facility_id,
    hire_date,
    termination_date,
    status,
    true as is_current,
    effective_from,
    null::timestamp_ntz as effective_to,
    _loaded_at,
    current_timestamp() as _updated_at,
    _row_hash
from staff
