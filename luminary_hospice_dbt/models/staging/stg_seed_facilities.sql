with source as (
    select * from {{ ref('raw_facilities_seed') }}
),

renamed as (
    select
        FACID as facility_id,
        trim(FACILITYNAME) as facility_name,
        trim(upper(FACTYP)) as facility_type,
        cast(FAC_NPI as varchar) as npi,
        cast(FAC_CCN as varchar) as ccn,
        LICENSENO as license_number,
        trim(ADDR1) as address_line_1,
        trim(upper(FACCITY)) as city,
        trim(upper(FACSTATE)) as state,
        trim(cast(FACZIP as varchar)) as zip_code,
        trim(upper(FACCOUNTY)) as county,
        cast(FACPHONE as varchar) as phone,
        cast(FACFAX as varchar) as fax,
        TOTALBEDS as total_bed_capacity,
        IPU_BEDS as ipu_bed_capacity,
        trim(upper(FACREGION)) as region,
        trim(upper(FAC_STATUS)) as status,
        CREATEDT as created_date,
        MODIFYDT as modified_date,
        current_timestamp() as _loaded_at,
        'raw_facilities_seed' as _source_file
    from source
)

select
    *,
    {{ hash_key_generator(['facility_id', 'facility_name', 'facility_type', 'npi', 'city', 'state', 'status']) }} as _row_hash
from renamed
