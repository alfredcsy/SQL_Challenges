-- Preppin data challenge week 1
-- https://preppindata.blogspot.com/2023/01/2023-week-1-data-source-bank.html

-- Split the Transaction Code to extract the letters at the start of the transaction code. These identify the bank who processes the transaction (help)
-- Rename the new field with the Bank code 'Bank'. 
select
    split_part(transaction_code,'-',1) as bank
from pd2023_wk01;

-- Rename the values in the Online or In-person field, Online of the 1 values and In-Person for the 2 values.
select
    split_part(transaction_code,'-',1) as bank,
    case online_or_in_person
    when 1 then 'Online'
    when 2 then 'In person'
    end as online_or_in_person,
    *
from PD2023_WK01;

-- Change the date to be the day of the week (help)
select
    split_part(transaction_code,'-',1) as bank,
    case online_or_in_person
    when 1 then 'Online'
    when 2 then 'In person'
    end as online_or_in_person,
    dayname(to_date(split_part(transaction_date,' ',1),'DD/MM/YYYY')) as weekday,
    *
from PD2023_WK01;

-- Different levels of detail are required in the outputs. You will need to sum up the values of the transactions in three ways (help):
-- 1. Total Values of Transactions by each bank
select 
    split_part(transaction_code,'-',1) as bank,
    sum(value)
from pd2023_wk01
group by bank;

-- 2. Total Values by Bank, Day of the Week and Type of Transaction (Online or In-Person)
select
    split_part(transaction_code,'-',1) as bank,
    case online_or_in_person
        when 1 then 'Online'
        when 2 then 'In person'
        end as online_or_in_person,
    dayname(to_date(split_part(transaction_date,' ',1),'DD/MM/YYYY')) as transaction_day,
    sum(value) as value
from PD2023_WK01
where bank = 'DSB'
group by bank, online_or_in_person, transaction_day;

-- 3. Total Values by Bank and Customer Code
select
    split_part(transaction_code,'-',1) as bank,
    customer_code,
    sum(value)
from pd2023_wk01
group by bank, customer_code;


