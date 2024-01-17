-- SQL Challenge 4 https://8weeksqlchallenge.com/case-study-4/

-- Part A
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
unpivot ("metric" for region in ("median", "80th percentile", "95th percentile"))