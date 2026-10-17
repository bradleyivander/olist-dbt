with sellers as (
    select * from {{ ref('silver_sellers') }}
),

items as (
    select * from {{ ref('fct_order_items') }}
),

-- sales totals per seller (item level is correct here)
seller_sales as (
    select
        seller_id,
        count(*)                    as items_sold,
        count(distinct order_id)    as orders_fulfilled,
        sum(price)                  as total_revenue,
        sum(freight_value)          as total_freight
    from items
    group by seller_id
),

-- one row per seller per order, so each order's delay counts once
seller_orders as (
    select distinct
        seller_id,
        order_id,
        delivery_delay_days,
        is_delayed
    from items
),

-- delivery performance per seller
seller_delivery as (
    select
        seller_id,
        round(avg(delivery_delay_days), 2)   as avg_delivery_delay_days,
        round(avg(is_delayed), 4)            as late_delivery_rate,
        count(is_delayed)                    as delivered_orders
    from seller_orders
    group by seller_id
)

select
    s.seller_id,
    s.seller_zip_code_prefix,
    coalesce(s.seller_city, 'unknown')            as seller_city,
    s.seller_state,
    s.seller_latitude,
    s.seller_longitude,
    s.city_source,

    coalesce(ss.items_sold,       0)              as items_sold,
    coalesce(ss.orders_fulfilled, 0)              as orders_fulfilled,
    coalesce(ss.total_revenue,    0)              as total_revenue,
    coalesce(ss.total_freight,    0)              as total_freight,

    sd.avg_delivery_delay_days,
    sd.late_delivery_rate,
    sd.delivered_orders

from sellers s
left join seller_sales    ss on s.seller_id = ss.seller_id
left join seller_delivery sd on s.seller_id = sd.seller_id