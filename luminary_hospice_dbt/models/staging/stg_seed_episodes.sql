with source as (
    select * from {{ ref('raw_episodes_seed') }}
),

renamed as (
    select
        EPID as episode_id,
        PAT_ID as patient_id,
        FACID as facility_id,
        EPSTARTDT as episode_start_date,
        EPENDDT as episode_end_date,
        trim(upper(EPISODETYP)) as episode_type,
        BENEFITPD as benefit_period,
        CERTSTARTDT as certification_start_date,
        CERTENDDT as certification_end_date,
        RECERTDT as recertification_date,
        trim(upper(LOC)) as level_of_care,
        trim(upper(PRIMDXCD)) as primary_diagnosis_code,
        trim(PRIMDXDESC) as primary_diagnosis_desc,
        cast(ATTENDPHYSNPI as varchar) as attending_physician_npi,
        trim(upper(PAYERTYP)) as payer_type,
        trim(PAYER_NAME) as payer_name,
        ELECTIONDT as election_date,
        REVOCATIONDT as revocation_date,
        trim(upper(EP_STATUS)) as status,
        CREATEDT as created_date,
        MODIFYDT as modified_date,
        current_timestamp() as _loaded_at,
        'raw_episodes_seed' as _source_file
    from source
)

select
    *,
    {{ hash_key_generator(['episode_id', 'patient_id', 'facility_id', 'episode_start_date', 'episode_type', 'level_of_care', 'status']) }} as _row_hash
from renamed
