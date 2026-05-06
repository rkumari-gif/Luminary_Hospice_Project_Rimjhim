with staff as (
    select * from {{ ref('stg_seed_staff') }}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by staff_id
            order by modified_date desc nulls last, _loaded_at desc
        ) as _rn
    from staff
)

select
    staff_id,
    first_name,
    last_name,
    first_name || ' ' || last_name as full_name,
    discipline,
    role,
    npi,
    facility_id,
    hire_date,
    termination_date,
    status,
    coalesce(created_date, _loaded_at) as effective_from,
    _loaded_at,
    _row_hash as _source_hash,
    {{ hash_key_generator(['staff_id', 'first_name', 'last_name', 'discipline', 'role', 'npi', 'facility_id', 'status']) }} as _hash_key
from deduplicated
where _rn = 1
