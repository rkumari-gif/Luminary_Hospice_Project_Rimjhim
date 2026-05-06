with source as (
    select * from {{ ref('raw_staff_seed') }}
),

renamed as (
    select
        STAFFID as staff_id,
        trim(upper(FNAME)) as first_name,
        trim(upper(LNAME)) as last_name,
        trim(upper(DISC)) as discipline,
        trim(upper(STAFFROLE)) as role,
        cast(STAFF_NPI as varchar) as npi,
        LICNO as license_number,
        FACID as facility_id,
        TEAMID as team_id,
        HIREDT as hire_date,
        TERMDT as termination_date,
        lower(trim(EMAIL)) as email,
        cast(STAFFPHONE as varchar) as phone,
        trim(upper(STAFF_STATUS)) as status,
        CREATEDT as created_date,
        MODIFYDT as modified_date,
        current_timestamp() as _loaded_at,
        'raw_staff_seed' as _source_file
    from source
)

select
    *,
    {{ hash_key_generator(['staff_id', 'first_name', 'last_name', 'discipline', 'role', 'facility_id', 'status']) }} as _row_hash
from renamed
