select
    claim_id,
    billed_amount,
    paid_amount,
    adjustment_amount
from {{ ref('int_billing_deduplicated') }}
where billed_amount < 0
   or paid_amount < 0
