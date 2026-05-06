with source as (
    select * from {{ ref('raw_visits_seed') }}
),

renamed as (
    select
        VISITID as visit_id,
        PAT_ID as patient_id,
        EPISODEID as episode_id,
        STAFFID as staff_id,
        FACID as facility_id,
        VISITDT as visit_date,
        VISITSTARTTM as visit_start_time,
        VISITENDTM as visit_end_time,
        trim(upper(DISC)) as discipline,
        trim(upper(VSTTYPE)) as visit_type,
        trim(upper(VSTSTATUS)) as visit_status,
        MILES as mileage,
        CREATEDT as created_date,
        MODIFYDT as modified_date,
        current_timestamp() as _loaded_at,
        'raw_visits_seed' as _source_file
    from source
)

select
    *,
    {{ hash_key_generator(['visit_id', 'patient_id', 'episode_id', 'staff_id', 'visit_date', 'discipline', 'visit_status']) }} as _row_hash
from renamed
