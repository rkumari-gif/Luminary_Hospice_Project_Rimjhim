select
    e.episode_id
from {{ ref('int_episodes_deduplicated') }} e
where e.episode_id not in (
    select episode_id from {{ ref('fact_episodes') }}
)
