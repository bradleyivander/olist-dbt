with products as (
    select * from {{ref('silver_products')}}
)

select
    product_id,
    -- English name if we have it, else Portuguese, else 'unknown'
    coalesce(
        product_category_name_en,
        product_category_name_pt,
        'unknown'
    ) as product_category,

    product_category_name_pt,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    product_length_cm * product_height_cm * product_width_cm   as product_volume_cm3,

    product_photos_qty,
    product_name_length,
    product_description_length
from products