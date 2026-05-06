select
    b.budget_id,
    b_count.unpivot_rows,
    10 as expected_metrics
from {{ ref('int_budget_deduplicated') }} b
left join (
    select budget_id, count(*) as unpivot_rows
    from {{ ref('int_budget_unpivoted') }}
    group by budget_id
) b_count on b.budget_id = b_count.budget_id
where b_count.unpivot_rows != 10
   or b_count.unpivot_rows is null
