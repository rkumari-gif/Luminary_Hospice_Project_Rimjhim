with source as (
    select * from {{ ref('raw_admissions_seed') }}
),

renamed as (
    select
        ADMID as admission_id,
        PAT_ID as patient_id,
        EPISODEID as episode_id,
        FACID as facility_id,
        ADMDATE as admission_date,
        trim(upper(ADMTYPE)) as admission_type,
        trim(upper(ADM_SOURCE)) as admission_source,
        REFID as referral_id,
        trim(upper(LOC)) as level_of_care,
        trim(upper(SVCTYPE)) as service_type,
        trim(upper(PRIMDXCD)) as primary_diagnosis_code,
        cast(ATTENDPHYSNPI as varchar) as attending_physician_npi,
        NURSEID as nurse_id,
        AIDEID as aide_id,
        SWID as social_worker_id,
        CHAPID as chaplain_id,
        trim(upper(RECORD_STATUS)) as status,
        CREATEDT as created_date,
        MODIFYDT as modified_date,
        current_timestamp() as _loaded_at,
        'raw_admissions_seed' as _source_file
    from source
)

select
    *,
    {{ hash_key_generator(['admission_id', 'patient_id', 'episode_id', 'facility_id', 'admission_date', 'admission_type', 'status']) }} as _row_hash
from renamed
