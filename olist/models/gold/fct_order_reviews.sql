with reviews as (
    select * from {{ ref('silver_order_reviews') }}
),

orders as (
    select * from {{ ref('silver_orders') }}
),

customers as (
    select * from {{ ref('silver_customers') }}
),

-- number each order's reviews, newest answer first
ranked as (
    select
        *,
        row_number() over (
            partition by order_id
            order by review_answer_ts desc, review_id
        ) as rn
    from reviews
),

-- keep one review per order
latest_review as (
    select *
    from ranked
    where rn = 1
)

select
    -- keys
    r.order_id,
    r.review_id,
    o.customer_id,
    c.customer_unique_id,

    -- review
    r.review_score,
    r.has_comment,
    r.review_comment_message,
    r.review_creation_ts,
    r.review_answer_ts,
    r.is_shared_reviews,

    -- order and delivery
    o.order_status,
    o.order_purchase_ts,
    cast(o.order_purchase_ts as date) as order_purchase_date,
    o.delivery_delay_days,
    case
        when o.delivery_delay_days > 0  then 1
        when o.delivery_delay_days <= 0 then 0
        else null -- not delivered
    end as is_delayed
from latest_review r
join orders o
    on r.order_id = o.order_id
left join customers c
    on o.customer_id = c.customer_id
