with referrals as (
    select * from {{ ref('stg_referrals') }}
    qualify row_number() over (partition by referral_id order by modified_date desc nulls last, _loaded_at desc) = 1
),

admissions as (
    select
        admission_id,
        referral_id,
        patient_id as adm_patient_id,
        episode_id,
        facility_id as adm_facility_id,
        admission_date,
        admission_type,
        admission_source,
        level_of_care,
        status as admission_status
    from {{ ref('stg_admissions') }}
    qualify row_number() over (partition by referral_id order by modified_date desc nulls last) = 1
),

funnel as (
    select
        r.referral_id,
        r.patient_id,
        to_date(r.referral_date) as referral_date,
        r.referral_source,
        r.referral_source_type,
        r.referring_physician_npi,
        r.referring_physician_name,
        r.referring_facility_name,
        r.referral_status,
        r.referral_outcome,
        r.facility_id,
        r.primary_diagnosis_code,
        r.payer_type,
        to_date(r.contact_date) as contact_date,
        to_date(r.evaluation_date) as evaluation_date,
        to_date(r.conversion_date) as conversion_date,
        r.decline_reason,
        r.pending_reason,
        a.admission_id,
        a.episode_id,
        to_date(a.admission_date) as admission_date,
        a.admission_type,
        a.level_of_care,
        a.admission_status,
        case
            when r.contact_date is not null
            then datediff('day', r.referral_date, r.contact_date)
            else null
        end as days_to_contact,
        case
            when r.evaluation_date is not null
            then datediff('day', r.referral_date, r.evaluation_date)
            else null
        end as days_to_evaluation,
        case
            when r.conversion_date is not null
            then datediff('day', r.referral_date, r.conversion_date)
            else null
        end as days_to_conversion,
        case
            when a.admission_date is not null
            then datediff('day', r.referral_date, a.admission_date)
            else null
        end as days_referral_to_admission,
        iff(r.contact_date is not null, true, false) as is_contacted,
        iff(r.evaluation_date is not null, true, false) as is_evaluated,
        iff(a.admission_id is not null, true, false) as is_converted,
        iff(r.referral_status = 'PENDING', true, false) as is_pending,
        iff(r.referral_outcome = 'DECLINED', true, false) as is_declined,
        case
            when a.admission_id is not null then 'CONVERTED'
            when r.referral_outcome = 'DECLINED' then 'DECLINED'
            when r.referral_status = 'PENDING' then 'PENDING'
            else r.referral_status
        end as funnel_stage,
        r._loaded_at,
        r._row_hash
    from referrals r
    left join admissions a
        on r.referral_id = a.referral_id
)

select * from funnel
