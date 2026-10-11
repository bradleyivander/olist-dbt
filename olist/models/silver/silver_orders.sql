with sources as (
    select * 
    from {{ source('bronze', 'bronze_orders') }}
),

cleaned as (
    select 
        order_id,
        customer_id,
        lower(trim(order_status)) as order_status,
        order_purchase_timestamp as order_purchase_ts,
        order_approved_at as order_approved_ts,
        order_delivered_carrier_date as order_delivered_carrier_ts,
        order_delivered_customer_date as order_delivered_customer_ts,
        order_estimated_delivery_date as order_estimated_delivery_ts
    from sources
)


select *,
    -- positive shows delayed days, negative shows delivered early days, null = not delivered yet
    datediff(
        cast(order_delivered_customer_ts as date),
        cast(order_estimated_delivery_ts as date)
    ) as delivery_delay_days
from cleaned
