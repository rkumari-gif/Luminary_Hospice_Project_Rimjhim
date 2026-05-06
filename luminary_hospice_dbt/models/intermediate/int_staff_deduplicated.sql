with staff as (
    select * from {{ ref('stg_staff') }}
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
    _row_hash
from deduplicated
where _rn = 1
