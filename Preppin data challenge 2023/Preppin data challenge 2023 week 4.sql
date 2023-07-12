-- Preppin data challenge 2023 week 4
-- https://preppindata.blogspot.com/2023/01/2023-week-4-new-customers.html

-- We want to stack the tables on top of one another, since they have the same fields in each sheet. We can do this one of 2 ways (help):
    -- Drag each table into the canvas and use a union step to stack them on top of one another
    -- Use a wildcard union in the input step of one of the tables
with cte_lv1 as (
select 
    *,
    1 as month
from pd2023_wk04_january
union all
select 
    *,
    2 as month
from pd2023_wk04_february
union all
select 
    *,
    3 as month
from pd2023_wk04_march
union all
select 
    *,
    4 as month
from pd2023_wk04_april
union all
select 
    *,
    5 as month
from pd2023_wk04_may
union all
select 
    *,
    6 as month
from pd2023_wk04_june
union all
select 
    *,
    7 as month
from pd2023_wk04_july
union all
select 
    *,
    8 as month
from pd2023_wk04_august
union all
select 
    *,
    9 as month
from pd2023_wk04_september
union all
select 
    *,
    10 as month
from pd2023_wk04_october
union all
select 
    *,
    11 as month
from pd2023_wk04_november
union all
select 
    *,
    12 as month
from pd2023_wk04_december
)
, cte_lv2 as (
-- Some of the fields aren't matching up as we'd expect, due to differences in spelling. Merge these fields together
-- Make a Joining Date field based on the Joining Day, Table Names and the year 2023
select
    to_date(
    to_char(joining_day) 
    || '/' ||
    case length(month)
    when 2 then to_char(month)
    else '0' || to_char(month)
    end
    || '/' ||
    '2023',
    'DD/MM/YYYY') as join_day,
    *
from cte_lv1)

-- Now we want to reshape our data so we have a field for each demographic, for each new customer (help)
-- Make sure all the data types are correct for each field
-- Remove duplicates (help)
    -- If a customer appears multiple times take their earliest joining date

select
    *
    exclude (joining_day,month)
from cte_lv2
pivot(min(value) for demographic in ('Ethnicity','Account Type','Date of Birth'))



