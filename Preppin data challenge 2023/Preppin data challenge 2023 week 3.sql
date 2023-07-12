-- Preppin data challenge 2023 week 3
-- https://preppindata.blogspot.com/2023/01/2023-week-3-targets-for-dsb.html

-- For the transactions file:
    -- Filter the transactions to just look at DSB (help)
        -- These will be transactions that contain DSB in the Transaction Code field
    -- Rename the values in the Online or In-person field, Online of the 1 values and In-Person for the 2 values
    -- Change the date to be the quarter (help)
    -- Sum the transaction values for each quarter and for each Type of Transaction (Online or In-Person) (help)
select
    case online_or_in_person
        when 1 then 'Online'
        when 2 then 'In person'
        end as online_or_in_person,
    quarter(to_date(split_part(transaction_date,' ',1),'DD/MM/YYYY')) as Quarter,
    sum(value)
from pd2023_wk01
where contains(transaction_code,'DSB')
group by online_or_in_person, quarter;

-- For the targets file:
    -- Pivot the quarterly targets so we have a row for each Type of Transaction and each Quarter (help)
    --  Rename the fields
    -- Remove the 'Q' from the quarter field and make the data type numeric (help)
with cte as(    
select
    *
from pd2023_wk03_targets
UNPIVOT(transaction for quarter in (Q1,Q2,Q3,Q4))
)
select
    online_or_in_person,
    replace(quarter,'Q','')::int as Quarter,
    transaction
from cte;

-- Join the two datasets together (help)
    -- You may need more than one join clause!
-- Calculate the Variance to Target for each row (help)
with target as(    
select
    *
from pd2023_wk03_targets
UNPIVOT(target for quarter in (Q1,Q2,Q3,Q4))
), transaction as (
select
    case online_or_in_person
        when 1 then 'Online'
        when 2 then 'In person'
        end as online_or_in_person,
    quarter(to_date(split_part(transaction_date,' ',1),'DD/MM/YYYY')) as Quarter,
    sum(value) as value
from pd2023_wk01
where contains(transaction_code,'DSB')
group by online_or_in_person, quarter
)
select
    ta.online_or_in_person,
    replace(ta.quarter,'Q','') :: int as quarter_new,
    target,
    value,
    value-target as variance
from target as ta
    join transaction as tr on ta.online_or_in_person = tr.online_or_in_person
        and quarter_new = tr.quarter
