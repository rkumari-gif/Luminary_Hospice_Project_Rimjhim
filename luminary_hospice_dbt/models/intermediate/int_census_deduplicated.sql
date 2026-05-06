with census as (
    select * from {{ ref('stg_census') }}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by census_id
            order by modified_date desc nulls last, _loaded_at desc
        ) as _rn
    from census
),

base as (
    select
        census_id,
        to_date(census_date) as census_date,
        patient_id,
        episode_id,
        facility_id,
        level_of_care,
        service_type,
        payer_type,
        payer_name,
        attending_physician_npi,
        primary_nurse_id,
        status,
        _loaded_at,
        _row_hash
    from deduplicated
    where _rn = 1
),

pivoted_loc as (
    select
        census_date,
        facility_id,
        count(*) as total_census,
        count_if(level_of_care = 'ROUTINE') as routine_count,
        count_if(level_of_care = 'CONTINUOUS') as continuous_count,
        count_if(level_of_care = 'RESPITE') as respite_count,
        count_if(level_of_care = 'GIP') as gip_count,
        round(routine_count / nullif(total_census, 0), 2) as routine_pct,
        round(continuous_count / nullif(total_census, 0), 2) as continuous_pct,
        round(respite_count / nullif(total_census, 0), 2) as respite_pct,
        round(gip_count / nullif(total_census, 0), 2) as gip_pct
    from base
    group by census_date, facility_id
)

select
    b.*,
    p.total_census as facility_daily_census,
    p.routine_count as facility_routine_count,
    p.continuous_count as facility_continuous_count,
    p.respite_count as facility_respite_count,
    p.gip_count as facility_gip_count,
    p.routine_pct as facility_routine_pct,
    p.continuous_pct as facility_continuous_pct,
    p.respite_pct as facility_respite_pct,
    p.gip_pct as facility_gip_pct
from base b
left join pivoted_loc p
    on b.census_date = p.census_date
    and b.facility_id = p.facility_id
