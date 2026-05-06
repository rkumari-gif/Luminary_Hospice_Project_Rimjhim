with facilities as (
    select * from {{ ref('stg_seed_facilities') }}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by facility_id
            order by modified_date desc nulls last, _loaded_at desc
        ) as _rn
    from facilities
)

select
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
    coalesce(created_date, _loaded_at) as effective_from,
    _loaded_at,
    _row_hash as _source_hash,
    {{ hash_key_generator(['facility_id', 'facility_name', 'facility_type', 'npi', 'city', 'state', 'region', 'status']) }} as _hash_key
from deduplicated
where _rn = 1
