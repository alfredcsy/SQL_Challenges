-- SQL Challenge 2 https://8weeksqlchallenge.com/case-study-2/

-- Part A
-- 1.How many pizzas were ordered?
select count(pizza_id)
from customer_orders;

-- 2.How many unique customer orders were made?
select count(distinct order_id)
from customer_orders;

-- 3.How many successful orders were delivered by each runner?
with cte as (
select 
    runner_id,
    count(order_id) as order_count,
    case cancellation
        when '' then null
        when 'null' then null
        else cancellation
    end 
    as cancellation_cleaned
from runner_orders
where cancellation_cleaned is null
group by runner_id, cancellation_cleaned
)
select
    runner_id,
    order_count
from cte;

-- Will's answer
SELECT 
  runner_id, 
  COUNT(DISTINCT order_id) as delivered_orders 
FROM 
  runner_orders 
WHERE 
  pickup_time<>'null' 
GROUP BY 
  runner_id
order by runner_id;

-- 4.How many of each type of pizza was delivered?
select
    pizza_name,
    count(co.order_id)
from customer_orders as co
join runner_orders as ro on co.order_id = ro.order_id
join pizza_names as pn on co.pizza_id = pn.pizza_id
where ro.pickup_time != 'null'
group by pizza_name;


-- 5.How many Vegetarian and Meatlovers were ordered by each customer?
select
    co.customer_id as customer,
    pn.pizza_name as pizza,
    count(order_id)
from customer_orders as co
join pizza_names as pn on co.pizza_id = pn.pizza_id
group by customer,pizza
order by customer;

-- 6.What was the maximum number of pizzas delivered in a single order?
select
    ro.order_id,
    count(pizza_id) as pizza_count
from runner_orders as ro
join customer_orders as co on ro.order_id = co.order_id
where ro.pickup_time != 'null'
group by ro.order_id
order by pizza_count desc
limit 1;

-- 7.For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
with cte as(
select 
    customer_id,
    exclusions,
    extras,
    case 
        when 
        (exclusions is not null 
        and exclusions != 'null' 
        and length(exclusions)>0) = true 
        then true
    end as exclusion_added,
    case 
        when 
        (extras is not null 
        and extras != 'null' 
        and length(extras)>0) = true 
        then true
        end as extra_added
from customer_orders as co
    join runner_orders as ro on co.order_id = ro.order_id
where ro.pickup_time != 'null'
)
select
    customer_id,
    case 
        when exclusion_added = true or extra_added = true
        then 'Changed'
        else 'Unchanged'
        end as Change,
    count(*)
from cte
group by customer_id, Change;

-- 2nd attempt
Select
    customer_id,
    sum(case
        when (
        (exclusions is not null and exclusions != 'null' and length(exclusions) > 0)
            and (extras is not null and extras != 'null' and length(extras) > 0)
            ) =true
        then 1
        else 0
    end) as Change,
    sum(case
        when (
        (exclusions is not null and exclusions != 'null' and length(exclusions) > 0)
            and (extras is not null and extras != 'null' and length(extras) > 0)
            ) =true
        then 0
        else 1
    end) as Unchange
from customer_orders as co
join runner_orders as ro on co.order_id = ro.order_id
where pickup_time != 'null'
group by customer_id;
    
-- Will's answer
SELECT 
  customer_id, 
  SUM(CASE 
    WHEN 
        (
          (exclusions IS NOT NULL AND exclusions<>'null' AND LENGTH(exclusions)>0) 
        AND (extras IS NOT NULL AND extras<>'null' AND LENGTH(extras)>0)
        )=TRUE
    THEN 1 
    ELSE 0
  END) as changes, 
  SUM(CASE 
    WHEN 
        (
          (exclusions IS NOT NULL AND exclusions<>'null' AND LENGTH(exclusions)>0) 
        AND (extras IS NOT NULL AND extras<>'null' AND LENGTH(extras)>0)
        )=TRUE
    THEN 0 
    ELSE 1
  END) as no_changes 
FROM 
  customer_orders as co 
  INNER JOIN runner_orders as ro on ro.order_id = co.order_id 
WHERE 
  pickup_time<>'null'
GROUP BY 
  customer_id;


-- 8.How many pizzas were delivered that had both exclusions and extras?
select count(*) as pizza_exclude_and_extra
from (
select *,
    CASE 
    WHEN 
        (
          (exclusions IS NOT NULL AND exclusions<>'null' AND LENGTH(exclusions)>0) 
        AND (extras IS NOT NULL AND extras<>'null' AND LENGTH(extras)>0)
        )=TRUE
    THEN 1 
    ELSE 0
  END as changes
from customer_orders as co
join runner_orders as ro on co.order_id = ro.order_id
where pickup_time != 'null'
    and changes = 1);


-- 9.What was the total volume of pizzas ordered for each hour of the day?
select 
    date_part("hour",order_time) as "hour",
    count(order_id)
from customer_orders
group by "hour"
order by "hour";

-- 10.What was the volume of orders for each day of the week?
select
    dayname(order_time) as day,
    count(*)
from customer_orders
group by day;

-- Part B
-- 1.How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
select
    date_trunc(week,registration_date)+4 as week,
    count(*) as signups
from runners
group by week
order by week;


-- 2.What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
select
    ro.runner_id,
    avg(timediff(minute,co.order_time,ro.pickup_time)) as time
from customer_orders as co
join runner_orders as ro 
    on co.order_id = ro.order_id
where ro.pickup_time != 'null'
group by ro.runner_id
order by ro.runner_id;

-- 3.Is there any relationship between the number of pizzas and how long the order takes to prepare?
with cte as (
select
    co.order_id,
    count(co.pizza_id) as "no of pizza",
    max(timediff(minute,co.order_time,ro.pickup_time)) as time_needed
from  customer_orders as co
join runner_orders as ro 
    on co.order_id = ro.order_id
where ro.pickup_time != 'null'
group by co.order_id
order by "no of pizza" desc
)
select 
    "no of pizza",
    avg(time_needed)
from cte
group by "no of pizza"
order by "no of pizza";


-- 4.What was the average distance travelled for each customer?
select
    co.customer_id,
    avg(trim(ro.distance,'km')::float) as avg_distance,
    avg(replace(distance,'km')::numeric(3,1))
from runner_orders as ro
join customer_orders as co on ro.order_id = co.order_id
where ro.distance != 'null'
group by co. customer_id;


-- 5.What was the difference between the longest and shortest delivery times for all orders?
select
    max(regexp_replace(duration,'[^0-9]','')::integer)-min(regexp_replace(duration,'[^0-9]','')::integer) as timediff
from  runner_orders
where duration != 'null';


-- 6.What was the average speed for each runner for each delivery and do you notice any trend for these values?
with cte as (
select 
    runner_id,
    order_id,
    distance,
    duration,
    try_cast(regexp_replace(duration,'[^0-9]','')as integer) as duration_clean,
    duration_clean/60 as duration_hour,
    try_cast(replace(distance,'km','')as float) as distance_clean
from runner_orders
where pickup_time != 'null'
)
select
    runner_id,
    order_id,
    avg(distance_clean/duration_clean) as "avg km/min",
    avg(distance_clean/duration_hour) as "avg km/h"
from cte
group by runner_id, order_id
order by runner_id, order_id;

-- Will's answer
SELECT 
  runner_id, 
  order_id, 
  REPLACE(distance, 'km', '')::numeric(3, 1) / REGEXP_REPLACE(duration, '[^0-9]', '')::numeric(3, 1) as speed_km_per_minute 
FROM 
  runner_orders 
WHERE 
  duration <> 'null' 
ORDER BY 
  runner_id, 
  order_id;

-- 7.What is the successful delivery percentage for each runner?/
select
    runner_id,
    count(order_id) as total_order,
    sum(iff(pickup_time!='null',1,0))as success_count,
    success_count/total_order as "success %"
from runner_orders
group by runner_id;

-- Part C
-- 1.What are the standard ingredients for each pizza?
with cte as(
select
    pn.pizza_id,
    pn.pizza_name,
    toppings,
    topping_split.value as topping_split,
    trim(topping_split)::float as topping_int
from pizza_names as pn
join pizza_recipes as pr on pn.pizza_id = pr.pizza_id,
lateral flatten(input=>split(toppings,',')) as topping_split
)
select
    pizza_id,
    pizza_name,
    topping_int,
    topping_name
from cte
join pizza_toppings on cte.topping_int = pizza_toppings.topping_id
order by pizza_id;


-- 2.What was the most commonly added extra?
with cte as(
select
    trim(extra_split.value) as extra_split,
    count(trim(extra_split.value)) as extra_count
from customer_orders,
lateral flatten(input=>split(extras,',')) as extra_split
where extras not in ('','null')
group by extra_split
)
select
    pizza_toppings.topping_name,
    extra_count
from cte 
join pizza_toppings on cte.extra_split = pizza_toppings.topping_id
order by extra_count desc
limit 1;

-- 3.What was the most common exclusion?
with cte as (
select
    trim(exclusions_split.value) as exclusions_split,
    count(trim(exclusions_split.value)) as exclusions_count
from customer_orders,
lateral flatten(input=>split(exclusions,',')) as exclusions_split
where exclusions not in ('','null')
group by exclusions_split
)
select
    pizza_toppings.topping_name as exclusion,
    exclusions_count
from cte 
join pizza_toppings on cte.exclusions_split = pizza_toppings.topping_id
order by exclusions_count desc
limit 1;

-- 4.Generate an order item for each record in the customers_orders table in the format of one of the following:
    -- Meat Lovers
    -- Meat Lovers - Exclude Beef
    -- Meat Lovers - Extra Bacon
    -- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
with normal_meatlover as(
select
    co.order_id,
    co.customer_id,
    pn.pizza_name,
    co.pizza_id
from customer_orders as co
join pizza_names as pn on co.pizza_id = pn.pizza_id
where (co.exclusions ='' or co.exclusions = 'null' or co.exclusions is null)
    and (co.extras ='' or co.extras = 'null' or co.extras is null)
    and pn.pizza_name = 'Meatlovers'
),
 pizza_with_exclude as (
select 
    co.order_id,
    co.customer_id,
    pn.pizza_name,
    trim(exclusions_split.value)::int as exclusion_int,
    pt.topping_name as toppings,
    co.exclusions,
    co.extras
from customer_orders as co
    join pizza_names as pn on co.pizza_id = pn.pizza_id,
lateral flatten(input=>split(exclusions,',')) as exclusions_split
    join pizza_toppings pt on exclusion_int = pt.topping_id
where (co.exclusions !='' and co.exclusions != 'null' and co.exclusions is not null)
    and (co.extras ='' or co.extras = 'null' or co.extras is null)
    and pn.pizza_name = 'Meatlovers'
),
pizza_with_extra as (
select 
    co.order_id,
    co.customer_id,
    pn.pizza_name,
    trim(extras_split.value)::int as extras_int,
    pt.topping_name as toppings,
    co.exclusions,
    co.extras
from customer_orders as co
    join pizza_names as pn on co.pizza_id = pn.pizza_id,
lateral flatten(input=>split(extras,',')) as extras_split
     join pizza_toppings pt on extras_int = pt.topping_id
where (co.extras !='' and co.extras != 'null' and co.extras is not null)
    and (co.exclusions ='' or co.exclusions = 'null' or co.exclusions is null)
    and pn.pizza_name = 'Meatlovers'
)
, extra_and_exclude as (
select 
    co.order_id,
    co.customer_id,
    pn.pizza_name,
    co.exclusions,
    co.extras,
    trim(extras_split.value)::int as extras_int,
    trim(exclusions_split.value)::int as exclusions_int
from customer_orders as co
join pizza_names as pn on co.pizza_id = pn.pizza_id,
lateral flatten(input=>split(extras,',')) as extras_split,
lateral flatten(input=>split(exclusions,',')) as exclusions_split
where (co.exclusions !='' and co.exclusions != 'null' and co.exclusions is not null)
     and (co.extras !='' and co.extras != 'null' and co.extras is not null)
     and pn.pizza_name = 'Meatlovers'
)
,extra_and_exclude_lv2 as (
select 
    order_id,
    customer_id,
    extras,
    exclusions,
    pizza_name,
    pt.topping_name as extra_topping,
    pt2.topping_name as excluded_topping
from extra_and_exclude as ee
    join pizza_toppings as pt on ee.extras_int = pt.topping_id
    join pizza_toppings as pt2 on ee.exclusions_int = pt2.topping_id
), extra_and_exclude_lv3 as(
select
    order_id,
    customer_id,
    pizza_name,
    listagg(distinct extra_topping,',')as extras,
    listagg(distinct excluded_topping,',')as exclusions
from extra_and_exclude_lv2
group by order_id, customer_id, pizza_name
)
select
    order_id,
    customer_id,
    pizza_name
from normal_meatlover
union
select
    order_id,
    customer_id,
    pizza_name ||  ' - Exclude ' || toppings as pizza_name
from pizza_with_exclude
union
select
    order_id,
    customer_id,
    pizza_name ||  ' - Extra ' || toppings as pizza_name
from pizza_with_extra
union
select
    order_id,
    customer_id,
    pizza_name ||  ' - Extra ' || extras  || ', ' || 'exclude ' || exclusions
from extra_and_exclude_lv3;


-- 5.Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
    -- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
with order_normal as (
select
    co.order_id,
    co.customer_id,
    co.pizza_id,
    pn.pizza_name,
    pr.toppings,
    trim(topping_split.value) :: int as topping,
    pt.topping_name
from customer_orders as co
    join pizza_recipes as pr on co.pizza_id = pr.pizza_id
    join pizza_names as pn on co.pizza_id = pn.pizza_id,
    lateral flatten(input=>split(pr.toppings,',')) as topping_split
join pizza_toppings as pt on topping = pt.topping_id
where (co.exclusions = '' or co.exclusions = 'null' or co.exclusions is null)
    and (co.extras = '' or co.extras = 'null' or co.extras is null)
order by order_id, customer_id, topping
),
order_with_extra_lv1 as (
select
    co.order_id,
    co.customer_id,
    co.pizza_id,
    pn.pizza_name,
    pr.toppings,
    co.extras ||', '|| pr.toppings as toppings_updated,
    trim(topping_split.value) :: int as topping,
    pt.topping_name
from customer_orders as co
    join pizza_recipes as pr on co.pizza_id = pr.pizza_id
    join pizza_names as pn on co.pizza_id = pn.pizza_id,
    lateral flatten(input=>split(toppings_updated,',')) as topping_split
join pizza_toppings as pt on topping = pt.topping_id
where (co.exclusions = '' or co.exclusions = 'null' or co.exclusions is null)
    and (co.extras != '' and co.extras != 'null' and co.extras is not null)
order by co.order_id, co.customer_id
), 
order_with_extra_lv2 as (
select
    order_id,
    pizza_name,
    topping_name,
    count(*) as topping_count
from order_with_extra_lv1
group by order_id, pizza_name, topping_name
),
order_with_exclude as (
select
    co.order_id,
    co.customer_id,
    co.pizza_id,
    pn.pizza_name,
    pr.toppings,
    trim(topping_split.value) :: int as topping,
    pt.topping_name,
    co.exclusions,
    co.extras
from customer_orders as co
    join pizza_recipes as pr on co.pizza_id = pr.pizza_id
    join pizza_names as pn on co.pizza_id = pn.pizza_id,
    lateral flatten(input=>split(toppings,',')) as topping_split
join pizza_toppings as pt on topping = pt.topping_id
where topping != exclusions
    and (co.exclusions != '' and co.exclusions != 'null' and co.exclusions is not null)
    and (co.extras = '' or co.extras = 'null' or co.extras is  null)
order by co.order_id, co.customer_id
), 
order_exclude_and_extra_lv1 as (
select
    co.order_id,
    co.pizza_id,
    co.exclusions,
    co.extras,
    pr.toppings,
    pn.pizza_name,
    pr.toppings || ', ' || co.extras as topping_with_extras,
    topping_extra_split.value :: int as  topping_int
from customer_orders as co
join pizza_recipes as pr on co.pizza_id = pr.pizza_id
join pizza_names as pn on co.pizza_id = pn.pizza_id,
lateral flatten (input=>split(topping_with_extras,',')) as topping_extra_split
where  (co.exclusions != '' and co.exclusions != 'null' and co.exclusions is not null)
    and (co.extras != '' and co.extras != 'null' and co.extras is not null)
), order_exclude_and_extra_lv2 as (
select 
    co.order_id,
    co.customer_id,
    exclusions_split.value :: int as exclusions_int
from customer_orders as co,
lateral flatten (input=> split(exclusions,',')) as exclusions_split
where  (co.exclusions != '' and co.exclusions != 'null' and co.exclusions is not null)
    and (co.extras != '' and co.extras != 'null' and co.extras is not null)
), order_exclude_and_extra_lv3 as (
select
    lv1.order_id,
    lv1.pizza_id,
    lv1.pizza_name,
    lv1.topping_int
from order_exclude_and_extra_lv1 as lv1
join order_exclude_and_extra_lv2  as lv2 on lv1.order_id = lv2.order_id
where lv1.topping_int != lv2.exclusions_int
), order_exclude_and_extra_lv4 as (
select
    lv3.order_id,
    lv3.pizza_name,
    pn.topping_name,
    count(*) as topping_count
from order_exclude_and_extra_lv3 as lv3
    join pizza_toppings as pn on lv3.topping_int = pn.topping_id
group by order_id, pizza_name, topping_name
)
select
    order_id,
    pizza_name,
    pizza_name ||': ' || listagg(topping_name,', ') as order_detail
from order_exclude_and_extra_lv4
group by pizza_name, order_id
union
select
    order_id,
    pizza_name,
    pizza_name ||': ' || listagg(topping_name,', ') as order_detail
from order_normal
group by pizza_name, order_id
union
select
    order_id,
    pizza_name,
    pizza_name||': ' || listagg(case
            when topping_count > 1 then topping_count || 'x' || topping_name
            else topping_name 
            end, ', ') as order_detail
from order_with_extra_lv2
group by pizza_name, order_id
union
select 
    order_id,
    pizza_name,
    pizza_name ||': ' || listagg(topping_name,', ') as order_detail
from order_with_exclude
group by order_id, pizza_name
order by order_id;


    
-- 6.What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
