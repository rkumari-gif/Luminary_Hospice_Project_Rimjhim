select
    r.referral_id,
    r.funnel_stage
from {{ ref('int_referral_to_admission_funnel') }} r
left join {{ ref('int_referrals_deduplicated') }} rd
    on r.referral_id = rd.referral_id
where rd.referral_id is null
