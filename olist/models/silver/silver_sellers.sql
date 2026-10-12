with sellers as (
    select * from {{source('bronze', 'bronze_sellers')}}
),

geolocation as (
    select * from {{ ref('silver_geolocations')}}
),

-- 1. standard cleaning, plus a text-cleaned city as the fallback
base as (
    select
        seller_id,
        lpad(cast(seller_zip_code_prefix as string), 5, '0')   as seller_zip_code_prefix,
        seller_city                                             as seller_city_raw,
        upper(trim(seller_state))                               as seller_state_raw,

        -- remove accents, keep the part before a separator (/ \ , or " - ")
        nullif(trim(split(
            translate(
                lower(trim(seller_city)),
                'áàâãäéèêëíìîïóòôõöúùûüçñ',
                'aaaaaeeeeiiiiooooouuuucn'
            ),
            '\\s*[/\\\\,]\\s*|\\s+-\\s+'
        )[0]), '')                                              as city_text
    from sellers
),

-- 2. junk text (digits, @, symbols) becomes null
base_validated as (
    select
        *,
        case
            when city_text rlike '[^a-z \\x27-]' then null
            else city_text
        end as city_text_clean
    from base
)

-- 3. prefer the zip lookup, fall back to the cleaned text
select
    b.seller_id,
    b.seller_zip_code_prefix,
    b.seller_city_raw,
    coalesce(g.city,  b.city_text_clean)     as seller_city,
    coalesce(g.state, b.seller_state_raw)    as seller_state,
    g.latitude                               as seller_latitude,
    g.longitude                              as seller_longitude,
    -- where the city came from, for auditing
    case
        when g.city            is not null then 'zip_lookup'
        when b.city_text_clean is not null then 'text_cleaned'
        else 'unresolved'
    end                                      as city_source
from base_validated b  
left join geolocation g
    on b.seller_zip_code_prefix = g.zip_code_prefix


