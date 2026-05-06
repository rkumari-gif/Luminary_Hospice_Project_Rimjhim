with visits as (
    select * from {{ ref('stg_visits') }}
),

staff as (
    select
        staff_id,
        first_name || ' ' || last_name as staff_name,
        discipline as staff_discipline,
        role as staff_role,
        facility_id as staff_facility_id
    from {{ ref('stg_staff') }}
    qualify row_number() over (partition by staff_id order by modified_date desc nulls last) = 1
),

deduplicated as (
    select
        v.*,
        row_number() over (
            partition by v.visit_id
            order by v.modified_date desc nulls last, v._loaded_at desc
        ) as _rn
    from visits v
),

joined as (
    select
        d.*,
        s.staff_name,
        s.staff_discipline,
        s.staff_role
    from deduplicated d
    left join staff s on d.staff_id = s.staff_id
    where d._rn = 1
),

cleaned as (
    select
        visit_id,
        patient_id,
        episode_id,
        staff_id,
        staff_name,
        coalesce(discipline, staff_discipline) as discipline,
        staff_role,
        facility_id,
        to_date(visit_date) as visit_date,
        to_timestamp_ntz(visit_start_time) as visit_start_time,
        to_timestamp_ntz(visit_end_time) as visit_end_time,
        case
            when visit_start_time is not null and visit_end_time is not null
                and visit_end_time > visit_start_time
            then datediff('minute', visit_start_time, visit_end_time)
            else null
        end as visit_duration_minutes,
        case
            when visit_duration_minutes is not null
            then round(visit_duration_minutes / 60.0, 2)
            else null
        end as visit_duration_hours,
        case
            when visit_end_time < visit_start_time then true
            else false
        end as has_time_anomaly,
        visit_type,
        visit_status,
        case
            when mileage < 0 then null
            when mileage > 500 then null
            else round(mileage, 1)
        end as mileage,
        case
            when mileage < 0 or mileage > 500 then true
            else false
        end as has_mileage_anomaly,
        _loaded_at,
        _row_hash
    from joined
)

select * from cleaned
