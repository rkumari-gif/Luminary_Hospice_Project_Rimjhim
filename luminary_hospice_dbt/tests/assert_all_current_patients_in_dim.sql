select
    s.patient_id
from {{ ref('int_patients_deduplicated') }} s
where s.is_current = true
  and s.patient_id not in (
    select patient_id from {{ ref('dim_patients') }}
  )
