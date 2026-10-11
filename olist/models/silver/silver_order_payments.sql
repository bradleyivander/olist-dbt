with source as (
    select * from {{ source('bronze', 'bronze_order_payments')}}
),

cleaned as (
    select
        order_id,
        cast(payment_sequential   as int)             as payment_sequential,
        lower(trim(payment_type))                     as payment_type,
        cast(payment_installments as int)             as payment_installments,
        cast(payment_value        as decimal(10, 2))  as payment_value
    from source
)

select
    *,
    -- data quality flag: 0 instalments is impossible (a payment is at least 1)
    case when payment_installments == 0 then 1 else 0 end as has_zero_installments
from cleaned