with source as (
    select * from workspace.olist_bronze.bronze_geolocation
),

-- 1. standardise every row
cleaned as (

    select
        lpad(cast(geolocation_zip_code_prefix as string), 5, '0')   as zip_code_prefix,
        translate(
            lower(trim(geolocation_city)),
            'áàâãäéèêëíìîïóòôõöúùûüçñ',
            'aaaaaeeeeiiiiooooouuuucn'
        )                                                            as city_clean,
        upper(trim(geolocation_state))                               as state_clean,
        cast(geolocation_lat as double)                              as lat,
        cast(geolocation_lng as double)                              as lng
    from source

),

-- 2. invalidate junk values so they can't win the vote
validated as (

    select
        zip_code_prefix,

        -- a valid city has only letters, spaces, apostrophes and hyphens
        case
            when city_clean = '' or city_clean rlike '[^a-z \'-]' then null
            else city_clean
        end as city,

        -- a valid state is exactly two capital letters
        case
            when state_clean rlike '^[A-Z]{2}$' then state_clean
        end as state,

        -- keep coordinates only if they fall inside Brazil
        case
            when lat between -34 and 6 and lng between -74 and -34 then lat
        end as lat,
        case
            when lat between -34 and 6 and lng between -74 and -34 then lng
        end as lng

    from cleaned

),

-- 3. most frequent city per zip
city_ranked as (
    select
        zip_code_prefix,
        city,
        row_number() over (
            partition by zip_code_prefix
            order by count(*) desc, city
        ) as rn
    from validated
    where city is not null
    group by zip_code_prefix, city
),

-- 4. most frequent state per zip
state_ranked as (
    select
        zip_code_prefix,
        state,
        row_number() over (
            partition by zip_code_prefix
            order by count(*) desc, state
        ) as rn
    from validated
    where state is not null
    group by zip_code_prefix, state
),

-- 5. median coordinates and evidence counts per zip
coords as (
    select
        zip_code_prefix,
        count(*)                        as n_points,
        count(lat)                      as n_valid_coords,
        percentile_approx(lat, 0.5)     as latitude,
        percentile_approx(lng, 0.5)     as longitude
    from validated
    group by zip_code_prefix
)

-- 6. one row per zip prefix
select
    c.zip_code_prefix,
    cr.city,
    sr.state,
    c.latitude,
    c.longitude,
    c.n_points,
    c.n_valid_coords
from coords c
left join city_ranked  cr on c.zip_code_prefix = cr.zip_code_prefix and cr.rn = 1
left join state_ranked sr on c.zip_code_prefix = sr.zip_code_prefix and sr.rn = 1