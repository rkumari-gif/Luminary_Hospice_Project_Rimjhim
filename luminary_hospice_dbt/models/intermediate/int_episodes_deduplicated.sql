with episodes as (
    select * from {{ ref('stg_episodes') }}
),

admissions as (
    select
        episode_id,
        admission_id,
        admission_date,
        admission_type,
        admission_source
    from {{ ref('stg_admissions') }}
    qualify row_number() over (partition by episode_id order by modified_date desc nulls last) = 1
),

discharges as (
    select
        episode_id,
        discharge_id,
        discharge_date,
        discharge_reason,
        discharge_disposition,
        length_of_stay as discharge_los
    from {{ ref('stg_discharges') }}
    qualify row_number() over (partition by episode_id order by modified_date desc nulls last) = 1
),

deduplicated as (
    select
        e.*,
        row_number() over (
            partition by e.episode_id
            order by e.modified_date desc nulls last, e._loaded_at desc
        ) as _rn
    from episodes e
),

joined as (
    select
        d.*,
        a.admission_id,
        a.admission_date,
        a.admission_type,
        a.admission_source,
        disc.discharge_id,
        disc.discharge_date,
        disc.discharge_reason,
        disc.discharge_disposition
    from deduplicated d
    left join admissions a on d.episode_id = a.episode_id
    left join discharges disc on d.episode_id = disc.episode_id
    where d._rn = 1
),

final as (
    select
        episode_id,
        patient_id,
        facility_id,
        to_date(episode_start_date) as episode_start_date,
        to_date(episode_end_date) as episode_end_date,
        episode_type,
        benefit_period,
        to_date(certification_start_date) as certification_start_date,
        to_date(certification_end_date) as certification_end_date,
        to_date(recertification_date) as recertification_date,
        level_of_care,
        primary_diagnosis_code,
        primary_diagnosis_desc,
        payer_type,
        payer_name,
        to_date(election_date) as election_date,
        to_date(revocation_date) as revocation_date,
        datediff('day', episode_start_date, coalesce(episode_end_date, current_date())) as length_of_stay,
        datediff('day', certification_start_date, certification_end_date) as certification_days,
        admission_id,
        to_date(admission_date) as admission_date,
        admission_type,
        admission_source,
        discharge_id,
        to_date(discharge_date) as discharge_date,
        discharge_reason,
        discharge_disposition,
        case
            when discharge_date is not null then 'DISCHARGED'
            when episode_end_date is null and status = 'ACTIVE' then 'ACTIVE'
            when revocation_date is not null then 'REVOKED'
            else status
        end as episode_lifecycle_status,
        iff(episode_end_date is null and status = 'ACTIVE', true, false) as is_active,
        iff(admission_id is not null, true, false) as has_admission,
        iff(discharge_id is not null, true, false) as has_discharge,
        status,
        _loaded_at,
        _row_hash
    from joined
)

select * from final
