with source as (
    select * from {{ source('bronze', 'RAW_EPISODES') }}
),

renamed as (
    select
        episode_id,
        patient_id,
        facility_id,
        episode_start_date,
        episode_end_date,
        trim(upper(episode_type)) as episode_type,
        benefit_period,
        certification_start_date,
        certification_end_date,
        recertification_date,
        trim(upper(level_of_care)) as level_of_care,
        trim(upper(primary_diagnosis_code)) as primary_diagnosis_code,
        trim(primary_diagnosis_desc) as primary_diagnosis_desc,
        attending_physician_npi,
        trim(upper(payer_type)) as payer_type,
        trim(payer_name) as payer_name,
        election_date,
        revocation_date,
        trim(upper(status)) as status,
        created_date,
        modified_date,
        _loaded_at,
        _source_file,
        _row_hash
    from source
)

select * from renamed
