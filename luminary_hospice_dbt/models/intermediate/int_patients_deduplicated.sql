with patients as (
    select * from {{ ref('stg_patients') }}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by patient_id
            order by modified_date desc nulls last, _loaded_at desc
        ) as _rn
    from patients
),

current_record as (
    select * from deduplicated where _rn = 1
),

history as (
    select
        patient_id,
        first_name,
        last_name,
        first_name || ' ' || last_name as full_name,
        date_of_birth,
        gender,
        primary_diagnosis_code,
        primary_diagnosis_desc,
        payer_type,
        payer_name,
        medicare_id,
        medicaid_id,
        city,
        state,
        zip_code,
        county,
        attending_physician_npi,
        attending_physician_name,
        status,
        coalesce(created_date, _loaded_at) as effective_from,
        lead(coalesce(created_date, _loaded_at)) over (
            partition by patient_id order by modified_date asc nulls first, _loaded_at asc
        ) as effective_to,
        _rn,
        _loaded_at,
        _row_hash
    from deduplicated
),

final as (
    select
        patient_id,
        first_name,
        last_name,
        full_name,
        to_date(date_of_birth) as date_of_birth,
        datediff('year', date_of_birth, current_date())
            - case
                when month(current_date()) < month(date_of_birth)
                    or (month(current_date()) = month(date_of_birth) and day(current_date()) < day(date_of_birth))
                then 1 else 0
              end as age,
        case
            when age < 0 or age > 120 then null
            else age
        end as age_validated,
        gender,
        primary_diagnosis_code,
        primary_diagnosis_desc,
        payer_type,
        payer_name,
        medicare_id,
        medicaid_id,
        city,
        state,
        case
            when regexp_like(zip_code, '^[0-9]{5}(-[0-9]{4})?$') then zip_code
            else lpad(regexp_replace(zip_code, '[^0-9]', ''), 5, '0')
        end as zip_code,
        county,
        attending_physician_npi,
        attending_physician_name,
        status,
        to_timestamp_ntz(effective_from) as effective_from,
        to_timestamp_ntz(effective_to) as effective_to,
        case when _rn = 1 then true else false end as is_current,
        _rn as version_number,
        _loaded_at,
        _row_hash
    from history
)

select * from final
