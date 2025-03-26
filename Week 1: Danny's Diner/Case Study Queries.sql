/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
select sales.customer_id as Customer, sum(menu.price) as TotalSpent
from sales
	inner join menu on sales.product_id = menu.product_id
group by sales.customer_id;

-- 2. How many days has each customer visited the restaurant?
select sales.customer_id as Customer, count(distinct sales.order_date) as Visits
from sales
group by sales.customer_id;

-- 3. What was the first item from the menu purchased by each customer?
select sales.customer_id as Customer, group_concat(distinct menu.product_name separator ', ') as FirstPurchase
from (
	select sales.customer_id, min(sales.order_date) as minDate
	from sales
	group by sales.customer_id
) as firstDates
	inner join sales on (sales.customer_id = firstDates.customer_id and sales.order_date = firstDates.minDate) 
	inner join menu on sales.product_id = menu.product_id
group by sales.customer_id;
    
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select menu.product_name as Item, count(menu.product_name) as Purchases
from sales
	inner join menu on sales.product_id = menu.product_id
group by menu.product_name
order by Purchases desc
limit 1;

-- 5. Which item was the most popular for each customer?
with itemCount as (
select sales.customer_id, sales.product_id, rank() over (partition by sales.customer_id order by count(*) desc) as rn
from sales
group by sales.customer_id, sales.product_id
order by sales.customer_id
)
select ic.customer_id as Customer, group_concat(menu.product_name separator ', ') as FavItem
from itemCount ic
    inner join menu on menu.product_id = ic.product_id
where rn = 1
group by ic.customer_id;

-- 6. Which item was purchased first by the customer after they became a member?
with ordersBeforeJoining as (
select sales.customer_id, sales.order_date, sales.product_id, rank() over (partition by sales.customer_id order by sales.order_date) as rn
from sales
    inner join members on sales.customer_id = members.customer_id
where members.join_date >= sales.order_date
order by sales.customer_id, sales.order_date
)
select orders.customer_id as Customer, group_concat(menu.product_name separator ', ') as Item
from ordersBeforeJoining orders
	inner join menu on menu.product_id = orders.product_id
where rn = 1
group by orders.customer_id
order by orders.customer_id;

-- 7. Which item was purchased just before the customer became a member?
with ordersAfterJoining as (
select sales.customer_id, sales.order_date, sales.product_id, rank() over (partition by sales.customer_id order by sales.order_date) as rn
from sales
    inner join members on sales.customer_id = members.customer_id
where members.join_date < sales.order_date
order by sales.customer_id, sales.order_date
)
select orders.customer_id as Customer, group_concat(menu.product_name separator ', ') as Item
from ordersAfterJoining orders
	inner join menu on menu.product_id = orders.product_id
where rn = 1
group by orders.customer_id
order by orders.customer_id;

-- 8. What is the total items and amount spent for each member before they became a member?
select sales.customer_id, count(sales.product_id) as totalItems, sum(menu.price) as totalSpent
from sales
	inner join members on members.customer_id = sales.customer_id
	inner join menu on menu.product_id = sales.product_id
where sales.order_date < members.join_date
group by sales.customer_id
order by sales.customer_id;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with itemCount as (
select sales.customer_id, menu.product_name, menu.price, count(*) as numItems
from sales
	inner join menu on menu.product_id = sales.product_id
group by sales.customer_id, menu.product_name, menu.price
),
totalPoints as (
select customer_id, product_name, price, numItems, 
	case
		when product_name = "sushi" then (numItems * price  * 20)
        else (numItems * price  * 10)
    end as numPoints
from itemCount
)
select customer_id as Customer, sum(numPoints) as Points
from totalPoints
group by customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
with itemCount as (
select sales.customer_id, menu.product_name, menu.price, sales.order_date, count(*) as numItems
from sales
	inner join menu on menu.product_id = sales.product_id
group by sales.customer_id, menu.product_name, menu.price, sales.order_date
),
totalPoints as (
select ic.customer_id, ic.product_name, ic.price, ic.numItems, ic.order_date, members.join_date,
	case
		when ic.product_name = "sushi" then (ic.numItems * ic.price  * 20)
        when order_date <= (7 + members.join_date) then (ic.numItems * ic.price  * 20)
        else (ic.numItems * ic.price  * 10)
    end as numPoints
from itemCount ic
	left join members on members.customer_id = ic.customer_id
)
select customer_id as Customer, sum(numPoints) as Points
from totalPoints
group by customer_id;