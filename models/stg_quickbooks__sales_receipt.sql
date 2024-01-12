{{ config(enabled=var('using_sales_receipt', True)) }}

with base as (

    select * 
    from {{ ref('stg_quickbooks__sales_receipt_tmp') }}

),

fields as (

    select
        /*
        The below macro is used to generate the correct SQL for package staging models. It takes a list of columns 
        that are expected/needed (staging_columns from dbt_quickbooks_source/models/tmp/) and compares it with columns 
        in the source (source_columns from dbt_quickbooks_source/macros/).
        For more information refer to our dbt_fivetran_utils documentation (https://github.com/fivetran/dbt_fivetran_utils.git).
        */

        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_quickbooks__sales_receipt_tmp')),
                staging_columns=get_sales_receipt_columns()
            )
        }}
        
        {{ 
            fivetran_utils.source_relation(
                union_schema_variable='quickbooks_union_schemas', 
                union_database_variable='quickbooks_union_databases'
                ) 
        }}
    from base
),

final as (
    
    select 
        cast(id as {{ dbt.type_string() }}) as sales_receipt_id,
        balance,
        cast(doc_number as {{ dbt.type_string() }}) as doc_number,
        home_total_amount as total_amount,
        cast(deposit_to_account_id as {{ dbt.type_string() }}) as deposit_to_account_id,
        created_at,
        cast(customer_id as {{ dbt.type_string() }}) as customer_id,
        cast(department_id as {{ dbt.type_string() }}) as department_id,
        cast(class_id as {{ dbt.type_string() }}) as class_id,
        currency_id,
        exchange_rate,
        cast( {{ dbt.date_trunc('day', 'transaction_date') }} as date) as transaction_date,
        _fivetran_deleted,
        source_relation
    from fields
)

select * 
from final
where not coalesce(_fivetran_deleted, false)
