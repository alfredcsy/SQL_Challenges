-- SQL Challenge 3 https://8weeksqlchallenge.com/case-study-4/

-- Part A - Customer Nodes Exploration
-- How many unique nodes are there on the Data Bank system?
select count (node_id)
from (
    select  distinct  (node_id)
    from customer_nodes
    );

    
--What is the number of nodes per region?
select 
    cn.region_id,
    r.region_name,
    count (cn.node_id)
from customer_nodes cn
join regions r 
    on cn.region_id = r.region_id
group by 
    cn.region_id,
    r.region_name
order by cn.region_id;


--How many customers are allocated to each region?
select 
    cn.region_id,
    r.region_name,
    count(distinct cn.customer_id)
from customer_nodes cn
join regions r 
    on cn.region_id = r.region_id
group by 
    cn.region_id,
    r.region_name
order by cn.region_id;


--How many days on average are customers reallocated to a different node?

select
    round(avg("date_diff"),2) as "avg reallocated day"
from (
    select 
        customer_id,
        node_id,
        sum(datediff("day",start_date,end_date)) as "date_diff"
    from customer_nodes
    where end_date != to_date('9999-12-31')
    group by customer_id, node_id
    order by customer_id
    );


--What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
with cte as (
    select
        cn.customer_id,
        r.region_name,
        cn.node_id,
        sum(datediff("day",cn.start_date,cn.end_date)) as "date_diff"
    from customer_nodes cn
    join regions r
        on cn.region_id = r.region_id
    where cn.end_date != to_date('9999-12-31')
    group by 
        cn.customer_id,
        r.region_name,
        cn.node_id
)
select 
    region_name,
    round(MEDIAN("date_diff"),0) as "median",
    round(percentile_cont(0.8) within group (order by "date_diff" asc),0) as "80th percentile",
    round(percentile_cont(0.95) within group (order by "date_diff" asc),0) as "95th percentile"
from cte
group by region_name
order by region_name;



-- mehotd #2: with pivoting result 
with cte as (
    select
        cn.customer_id,
        r.region_name,
        cn.node_id,
        sum(datediff("day",cn.start_date,cn.end_date)) as "date_diff"
    from customer_nodes cn
    join regions r
        on cn.region_id = r.region_id
    where cn.end_date != to_date('9999-12-31')
    group by 
        cn.customer_id,
        r.region_name,
        cn.node_id
),
cte2 as (
select 
    region_name,
    round(MEDIAN("date_diff"),0) as "median",
    round(percentile_cont(0.8) within group (order by "date_diff" asc),0) as "80th percentile",
    round(percentile_cont(0.95) within group (order by "date_diff" asc),0) as "95th percentile"
from cte
group by region_name
order by region_name    
)
select *
from cte2
unpivot ("metric" for region in ("median", "80th percentile", "95th percentile"));




-- Part B - Customer Transactions
-- What is the unique count and total amount for each transaction type?
select
    txn_type,
    count(*) as unique_count,
    sum(txn_amount) as total_amount
from customer_transactions
group by txn_type;


--What is the average total historical deposit counts and amounts for all customers?
with cte as (
    select
        customer_id,
        count(*) as historical_count,
        avg(txn_amount) as avg_amount
    from customer_transactions
    where txn_type = 'deposit'
    group by customer_id
)
select
    round(avg(historical_count),0) as avg_deposit_times,
    round(avg(avg_amount),2) as avg_deposit_amount
from cte;


--For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
with cte as (
select
    customer_id,
    monthname(date_trunc("month",txn_date)) as month_name,
    sum(
        case txn_type
        when 'deposit'
        then 1
        end
        ) as deposit_count,
    sum(
        case
        when txn_type != 'deposit'
        then 1
        end
       ) as withdraw_or_purchase
from customer_transactions
group by 
    customer_id, 
    month_name
having deposit_count > 1
    and withdraw_or_purchase = 1
)
select 
    month_name,
    count(customer_id) as customer_count
from cte
group by month_name;


--What is the closing balance for each customer at the end of the month?
--What is the percentage of customers who increase their closing balance by more than 5%?