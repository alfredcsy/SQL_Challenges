-- SQL Challenge 1 https://8weeksqlchallenge.com/case-study-1/
-- 1. Total amount each customer spent
select
    customer_id,
    sum(menu.price)
from
    sales
    join menu on sales.product_id = menu.product_id
group by
    customer_id;

    
-- 2. How many days each customers spent
select
    customer_id,
    count(distinct order_date)
from
    sales
group by
    customer_id;

    
--3. What was the first item from the menu purchased by each customer?
select
    a.customer_id,
    min(a.order_date),
    min(b.product_name)
from
    sales as a
    join menu as b on a.product_id = b.product_id
group by
    customer_id;


-- self test
with CTE as (
    SELECT
        customer_id,
        order_date,
        rank() over (partition by customer_id order by order_date) as "rank",
        menu.product_name
    from sales
        join menu on sales.product_id = menu.product_id
    )
    Select *
    from cte
    where "rank" = 1;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select
    sales.product_id,
    menu.product_name,
    count(*) as "num of purchase"
from sales
    join menu on sales.product_id = menu.product_id
group by sales.product_id, menu.product_name
order by "num of purchase" desc
limit 1;


-- 5. Which item was the most popular for each customer?
with cte as (
select 
    s.customer_id,
    m.product_name,
    count(s.product_id) as test,
    rank() over (partition by s.customer_id order by test desc) as rank
from sales as S
    join menu as M on S.product_id = M.PRODUCT_ID
group by 
    s.customer_id, 
    m.product_name
)
select
    customer_id,
    product_name,
    test
from cte
where rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?
with cte as(
select
    s.customer_id,
    s.order_date,
    mem.join_date,
    men.product_name,
    rank() over (partition by s.customer_id order by order_date asc) as date_rank
from sales as s
    join members as mem on s.customer_id = mem.customer_id
        and s.order_date > mem.join_date
    join menu as men on s.product_id = men.product_id
)
select *
from cte
where date_rank = 1;

-- 7. Which item was purchased just before the customer became a member?
with cte as (
select
    s.customer_id,
    s.order_date,
    mem.join_date,
    men.product_name,
    rank() over(partition by s.customer_id order by order_date asc) as date_rank
from sales as s
    join members as mem on s.customer_id = mem.customer_id
        and s.order_date < mem.join_date
    join menu as men on s.product_id = men.product_id
order by customer_id
)
select
    customer_id,
    product_name,
    join_date,
    order_date
from cte
where date_rank = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
select
    s.customer_id,
    count(s.product_id),
    sum(men.price)
from sales as s
    join members as mem on s.customer_id = mem.customer_id
        and s.order_date < mem.join_date
    join menu as men on s.product_id = men.product_id
group by s.customer_id;


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with cte as (
select
    s.customer_id,
    m.product_name,
    case m.product_name
        when 'sushi' then price*10*2
        else price *10 
        end as point
from sales as s
    join menu as m on s.product_id=m.product_id
)
select 
    customer_id,
    sum(point)
from cte
group by customer_id;




-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
-- how many points do customers A and B have at the end of January?

select
    s.customer_id,
    --datediff(day,m.join_date,s.order_date) as date_diff,
    sum(case 
        when s.order_date between m.join_date and dateadd(day,6,m.join_date) then price*20
        when men.product_name = 'sushi' then price*20
        else price*10 
    end )as point
from sales as s 
    join members as m on s.customer_id = m.customer_id
    join menu as men on s.product_id = men.product_id
where date_trunc(month,s.order_date)='2021-01-01'
group by s.customer_id;


