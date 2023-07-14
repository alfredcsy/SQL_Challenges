-- SQL Challenge 3 https://8weeksqlchallenge.com/case-study-3/

-- How many customers has Foodie-Fi ever had?
select distinct count(customer_id)
from subscriptions;

-- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
select
    date_trunc('month',start_date) as month_trunc,
    count(*) as count
from subscriptions as sub
    join plans as pl on sub.plan_id = pl.plan_id
where pl.plan_name = 'trial'
group by month_trunc
order by month_trunc;

-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

-- approach with cte
select
    pl.plan_name,
    count(*) as count
from subscriptions as sub
    join plans as pl on sub.plan_id = pl.plan_id
where sub.start_date > date('2020-12-31')
group by pl.plan_name;

-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
with cte as(
select 
    distinct
    pl.plan_name,
    count(customer_id) as customer_count,
    min(total_count) as total_count
from subscriptions as sub
    join plans as pl on sub.plan_id = pl.plan_id
    join (select count (distinct customer_id) as total_count from subscriptions) on 1 = 1
where pl.plan_name = 'churn'
group by pl.plan_name
)
select 
    plan_name,
    customer_count as count,
    total_count,
    round(customer_count/total_count*100,1) as "churn %"
from cte;

-- another approach
select
    pl.plan_name,
    round(
    count(distinct sub.customer_id)
    /
    (select count (distinct customer_id)
    from subscriptions)*100,1) as "churn %"
from subscriptions as sub
    join plans as pl on sub.plan_id = pl.plan_id
where pl.plan_name = 'churn'
group by pl.plan_name;

-- How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
with cte as (
select
    rank() over (partition by sub.customer_id order by start_date asc) as ranking,
    *
from subscriptions as sub
    join plans as pl on sub.plan_id = pl.plan_id
order by customer_id, ranking
)
select 
    count (distinct customer_id) as churn_count,
    round(count (distinct customer_id)
    /
    (select count (distinct customer_id) from subscriptions)*100,1) as churn_percent
from cte
where plan_name = 'churn' and ranking = 2
order by customer_id, ranking;


-- What is the number and percentage of customer plans after their initial free trial?
with cte as (
select
    rank() over (partition by sub.customer_id order by start_date asc) as ranking,
    *
from subscriptions as sub
    join plans as pl on sub.plan_id = pl.plan_id
order by customer_id, ranking
)
select 
    round(
    ((select count(distinct customer_id) from subscriptions) - count (distinct customer_id))
    /
    (select count(distinct customer_id) from subscriptions)*100,1)as member_with_plan_percent
from cte
where plan_name = 'churn' and ranking = 2
order by customer_id, ranking;

-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
with cte as (
select
    *,
    lead(plan_id) over (partition by customer_id order by start_date asc) as next_plan
from subscriptions as sub
where start_date<=date('2020-12-31')
order by customer_id, start_date
)
select 
    cte.plan_id,
    pl.plan_name,
    count(cte.customer_id) as count,
    round(
    count
    /
    (select count (distinct customer_id) from subscriptions)*100,1) as breakdown_percent
from cte
    join plans as pl on cte.plan_id = pl.plan_id
where cte.next_plan is null
    and cte.start_date <= date('2020-12-31')
group by cte.plan_id, pl.plan_name
order by cte.plan_id;


-- How many customers have upgraded to an annual plan in 2020?
select
    count(distinct customer_id)
from subscriptions
where plan_id = 3
    and start_date <= date('2020-12-31');

-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
with annual_member as (
select *
from subscriptions
where plan_id = 3
),
cte as (
select 
    sub.customer_id,
    sub.plan_id,
    sub.start_date,
    lead(sub.start_date) over (partition by sub.customer_id order by sub.start_date asc) as next_date,
    datediff("day",sub.start_date,next_date) as date_diff
from subscriptions as sub 
    join annual_member as am on sub.customer_id = am.customer_id
where sub.plan_id in (0,3)
)
select 
round(avg(date_diff),0) as avg_day
from cte;

-- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
select
    count(distinct customer_id)
from subscriptions
where plan_id = 3
    and start_date <= date('2020-12-31');

-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
with annual_member as (
select *
from subscriptions
where plan_id = 3
),
cte as (
select 
    sub.customer_id,
    sub.plan_id,
    sub.start_date,
    lead(sub.start_date) over (partition by sub.customer_id order by sub.start_date asc) as next_date
from subscriptions as sub 
    join annual_member as am on sub.customer_id = am.customer_id
where sub.plan_id in (0,3)
), bucket as(
select
    WIDTH_BUCKET(next_date-start_date, 0, 365, 12) AS bins,
    *
from cte
where next_date is not null
)
select 
    (bins-1)*30 || ' - ' || bins*30 || ' days' as bin,
    count(customer_id) as count
from bucket
group by bins
order by bins;

-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
with cte as (
select
    lead(sub.plan_id) over (partition by customer_id order by start_date asc) as next_plan,
    sub.customer_id,
    sub.plan_id,
    sub.start_date,
    pl.plan_name
from subscriptions as sub
    join plans as pl on sub.plan_id = pl.plan_id
where pl.plan_name in ('basic monthly','pro monthly')
order by sub.customer_id, sub.start_date
)
select *
from cte
where next_plan < plan_id

-- no instance as such