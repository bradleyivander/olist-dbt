with sources as (
    select * from {{ source('bronze', 'bronze_order_reviews') }}
),

cleaned as (
    select 
        review_id,
        order_id,
        cast(review_score as int)                       as review_score,
        nullif(trim(review_comment_title),   '')        as review_comment_title,
        nullif(trim(review_comment_message), '')        as review_comment_message,
        cast(review_creation_date    as timestamp)      as review_creation_ts,
        cast(review_answer_timestamp as timestamp)      as review_answer_ts
    from sources
)

select *,
    (review_comment_message is not null) as has_comment,
    (count(*) over (partition by review_id) > 1) is_shared_reviews
from cleaned    

