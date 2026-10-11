with sources as (

    select * from {{ source('bronze', 'bronze_customers')}}

),

cleaned as (

    select
        customer_id,
        customer_unique_id,
        -- use lpad since autoloader recognized the zipcode as number, removing the initial 0 prefix
        lpad(cast(customer_zip_code_prefix as string), 5, '0')  as customer_zip_code_prefix, 
        lower(trim(customer_city))                              as customer_city,
        upper(trim(customer_state))                             as customer_state
    from sources

)

select * from cleaned