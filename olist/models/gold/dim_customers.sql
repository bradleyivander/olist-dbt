with customers as (
    select * from {{ref('silver_customers')}}
),

orders as (
    select * from {{ref('silver_orders')}}
),

items as (
    select * from {{ref('fct_order_items')}}
),

-- link each order to the real person, with the address used for that order
customer_orders as (
    select
        c.customer_unique_id,
        c.customer_id,
        c.customer_zip_code_prefix,
        c.customer_city,
        c.customer_state,
        o.order_id,
        o.order_purchase_ts
    from customers c
    join orders o
        on c.customer_id = o.customer_id
),

-- number each person's orders, newest first
ranked as (
    select
        *,
        row_number() over (
            partition by customer_unique_id
            order by order_purchase_ts desc, customer_id
        ) as rn
    from customer_orders
),

-- keep the address from the newest order
latest_address as (
    select
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state
    from ranked
    where rn = 1
),

-- order history per person
order_stats as (
    select
        customer_unique_id,
        count(distinct order_id)    as lifetime_orders,
        min(order_purchase_ts)      as first_order_ts,
        max(order_purchase_ts)      as last_order_ts
    from customer_orders
    group by customer_unique_id
),

-- spending per person
spend as (
    select
        customer_unique_id,
        count(*)            as lifetime_items,
        sum(item_total)     as lifetime_spend
    from items
    group by customer_unique_id
)

select
    a.customer_unique_id,
    a.customer_zip_code_prefix,
    coalesce(a.customer_city, 'unknown')      as customer_city,
    a.customer_state,

    s.lifetime_orders,
    coalesce(p.lifetime_items, 0)             as lifetime_items,
    coalesce(p.lifetime_spend, 0)             as lifetime_spend,
    s.first_order_ts,
    s.last_order_ts,
    (s.lifetime_orders > 1)                   as is_repeat_customer

from latest_address a
join order_stats s
    on a.customer_unique_id = s.customer_unique_id
left join spend p
    on a.customer_unique_id = p.customer_unique_id