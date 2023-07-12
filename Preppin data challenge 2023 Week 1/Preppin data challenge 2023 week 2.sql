-- Preppin data challenge 2023 week 2
-- https://preppindata.blogspot.com/2023/01/2023-week-2-international-bank-account.html

-- In the Transactions table, there is a Sort Code field which contains dashes. We need to remove these so just have a 6 digit string (hint)
select
    replace(sort_code,'-','') as sort_code_new,
    *
from pd2023_wk02_transactions;

-- Use the SWIFT Bank Code lookup table to bring in additional information about the SWIFT code and Check Digits of the receiving bank account (hint)
select
    replace(sort_code,'-','') as sort_code_new,
    *
from pd2023_wk02_transactions as trans
    left join pd2023_wk02_swift_codes as swift on trans.bank = swift.bank;
    
-- Add a field for the Country Code (hint)
-- Hint: all these transactions take place in the UK so the Country Code should be GB
select
    replace(sort_code,'-','') as sort_code_new,
    'GB' as country_code,
    *
from pd2023_wk02_transactions as trans
    left join pd2023_wk02_swift_codes as swift on trans.bank = swift.bank;

-- Create the IBAN as above (hint)
-- Hint: watch out for trying to combine sting fields with numeric fields - check data types
select
    transaction_id,
    'GB' || check_digits || swift_code || replace(sort_code,'-','') || to_char(account_number) as IBAN
from pd2023_wk02_transactions as trans
    left join pd2023_wk02_swift_codes as swift on trans.bank = swift.bank;
