with products as (
    select * from {{ source('bronze', 'bronze_products')}}
),

translation as (
    select * from {{ source('bronze', 'bronze_category_translation')}}
),

joined as (
    select
        p.product_id,
        p.product_category_name                         as product_category_name_pt,
        t.product_category_name_english                 as product_category_name_en,
        cast(p.product_name_lenght        as int)       as product_name_length,
        cast(p.product_description_lenght as int)       as product_description_length,
        cast(p.product_photos_qty         as int)       as product_photos_qty,
        cast(p.product_weight_g           as int)       as product_weight_g,
        cast(p.product_length_cm          as int)       as product_length_cm,
        cast(p.product_height_cm          as int)       as product_height_cm,
        cast(p.product_width_cm           as int)       as product_width_cm
    from products p
    left join translation t
        on p.product_category_name = t.product_category_name
)

select * from joined