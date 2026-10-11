with sources as (
    select * from {{source('bronze', 'bronze_order_items')}}
),

cleaned as (

    select
        order_id,
        cast(order_item_id as int) as order_item_id,
        product_id,
        seller_id,
        cast(shipping_limit_date as timestamp) as shipping_limit_ts,
        cast(price as decimal(10,2)) as price,
        cast(freight_value as decimal(10,2)) as freight_value
    from sources

)

select
    *,
    price + freight_value as item_total
from cleaned