with billing as (
    select * from {{ ref('stg_billing_claims') }}
),

episodes as (
    select
        episode_id,
        patient_id as ep_patient_id,
        level_of_care as episode_level_of_care,
        primary_diagnosis_code as episode_diagnosis_code,
        payer_type as episode_payer_type,
        episode_start_date,
        episode_end_date
    from {{ ref('stg_episodes') }}
),

deduplicated as (
    select
        b.*,
        row_number() over (
            partition by b.claim_id
            order by b.modified_date desc nulls last, b._loaded_at desc
        ) as _rn
    from billing b
),

joined as (
    select
        d.*,
        e.episode_level_of_care,
        e.episode_diagnosis_code,
        e.episode_payer_type,
        e.episode_start_date as episode_start_date,
        e.episode_end_date as episode_end_date
    from deduplicated d
    left join episodes e
        on d.episode_id = e.episode_id
    where d._rn = 1
),

cleaned as (
    select
        claim_id,
        patient_id,
        episode_id,
        facility_id,
        claim_type,
        claim_status,
        to_date(service_from_date) as service_from_date,
        to_date(service_to_date) as service_to_date,
        datediff('day', service_from_date, service_to_date) as service_days,
        coalesce(level_of_care, episode_level_of_care) as level_of_care,
        revenue_code,
        hcpcs_code,
        case when billed_amount < 0 then 0 else round(billed_amount, 2) end as billed_amount,
        case when allowed_amount < 0 then 0 else round(allowed_amount, 2) end as allowed_amount,
        case when paid_amount < 0 then 0 else round(paid_amount, 2) end as paid_amount,
        round(abs(adjustment_amount), 2) as adjustment_amount,
        round(
            case
                when billed_amount > 0
                then paid_amount / billed_amount
                else 0
            end, 2
        ) as payment_rate,
        round(
            case
                when billed_amount > 0
                then adjustment_amount / billed_amount
                else 0
            end, 2
        ) as adjustment_rate,
        coalesce(payer_type, episode_payer_type) as payer_type,
        payer_name,
        to_date(submission_date) as submission_date,
        to_date(payment_date) as payment_date,
        case
            when submission_date is not null and payment_date is not null
            then datediff('day', submission_date, payment_date)
            else null
        end as days_to_payment,
        case
            when days_to_payment < 0 then true
            else false
        end as has_date_anomaly,
        denial_reason_code,
        iff(denial_reason_code is not null, true, false) as is_denied,
        episode_start_date,
        episode_end_date,
        _loaded_at,
        _row_hash
    from joined
)

select * from cleaned
