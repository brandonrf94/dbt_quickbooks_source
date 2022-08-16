--To disable this model, set the using_bill_payment variable within your dbt_project.yml file to False.
{{ config(enabled=var('using_bill', True)) }}

with base as (

    select * 
    from {{ ref('stg_quickbooks__bill_payment_line_tmp') }}

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
                source_columns=adapter.get_columns_in_relation(ref('stg_quickbooks__bill_payment_line_tmp')),
                staging_columns=get_bill_payment_line_columns()
            )
        }}
        
    from base
),

final as (
    
    select 
        cast(bill_payment_id as {{ dbt_utils.type_string() }}) as bill_payment_id,
        index,
        amount,
        cast(bill_id as {{ dbt_utils.type_string() }}) as bill_id,
        deposit_id,
        expense_id,
        journal_entry_id,
        linked_bill_payment_id,
        vendor_credit_id
    from fields
)

select * 
from final
