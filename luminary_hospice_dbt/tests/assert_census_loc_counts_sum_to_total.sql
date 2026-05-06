select
    census_date,
    facility_id,
    facility_routine_count + facility_continuous_count + facility_respite_count + facility_gip_count as loc_sum,
    facility_daily_census
from {{ ref('int_census_deduplicated') }}
where facility_routine_count + facility_continuous_count + facility_respite_count + facility_gip_count != facility_daily_census
