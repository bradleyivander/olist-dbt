with order_items as (
    select * from {{ ref('silver_order_items')}}
),

orders as (
    select * from {{ ref('silver_orders')}}
),

customers as (
    select * from {{ ref('silver_customers')}}
)

select
    -- keys
    oi.order_id,
    oi.order_item_id,
    o.customer_id,
    c.customer_unique_id,
    oi.product_id,
    oi.seller_id,

    -- order context
    o.order_status,
    o.order_purchase_ts,
    cast(o.order_purchase_ts as date) as order_purchase_date,
    o.order_delivered_customer_ts,
    o.order_estimated_delivery_ts,

    -- money (item level)
    oi.price,
    oi.freight_value,
    oi.item_total,

    -- money (order level, repeated on each item row)
    sum(oi.item_total) over (partition by oi.order_id) as order_total,
    count(*)           over (partition by oi.order_id) as items_in_order,

    -- delivery performance
    o.delivery_delay_days,
    case
        when o.delivery_delay_days > 0  then 1
        when o.delivery_delay_days <= 0 then 0
        else null -- not delivered
    end as is_delayed

from order_items oi
join orders o
    on oi.order_id = o.order_id
left join customers c
    on o.customer_id = c.customer_id