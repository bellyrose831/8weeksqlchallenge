-- A. Pizza Metrics
-- How many pizzas were ordered?
select count(id) as PizzasOrdered 
from cleaned_customer_orders;

-- How many unique customer orders were made?
select count(distinct order_id) as UniqueCustomerOrders 
from cleaned_customer_orders;

-- How many successful orders were delivered by each runner?
select runner_id, count(distinct order_id) as OrdersDelivered
from cleaned_runner_orders 
where cancellation is null
group by runner_id;

-- How many of each type of pizza was delivered?
select pizza_name, count(id) as PizzasOrdered 
from cleaned_customer_orders
	join pizza_names on cleaned_customer_orders.pizza_id = pizza_names.pizza_id
group by pizza_name;

-- How many Vegetarian and Meatlovers were ordered by each customer?
select customer_id, sum(case when pizza_id = 1 then 1 else 0 end) as Meatlovers, sum(case when pizza_id = 2 then 1 else 0 end) as Vegetarian
from cleaned_customer_orders
group by customer_id;

-- What was the maximum number of pizzas delivered in a single order?
with orderCounts as (
select cco.order_id, count(id) as numOrders
from cleaned_customer_orders cco
	join cleaned_runner_orders cro on cco.order_id = cro.order_id
where cancellation is null
group by order_id
)
select max(numOrders) as MostPizzas from orderCounts;

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
select cco.customer_id, sum(case when (extras is not null or exclusions is not null) then 1 else 0 end) as Changes,
	sum(case when (extras is null and exclusions is null) then 1 else 0 end) as NoChanges
from cleaned_customer_orders cco
	join cleaned_runner_orders cro on cco.order_id = cro.order_id
where cancellation is null
group by cco.customer_id;

-- How many pizzas were delivered that had both exclusions and extras?
select sum(case when (extras is not null and exclusions is not null) then 1 else 0 end) as ExclusionsAndExtras
from cleaned_customer_orders cco
	join cleaned_runner_orders cro on cco.order_id = cro.order_id
where cancellation is null;

-- What was the total volume of pizzas ordered for each hour of the day?
select hour(order_time) as hourOrdered, count(id) as Volume
from cleaned_customer_orders 
group by hourOrdered
order by hourOrdered;

-- What was the volume of orders for each day of the week?
select 
	case
		when dayofweek(order_time) = 1 then 'Sunday'
		when dayofweek(order_time) = 2 then 'Monday'
		when dayofweek(order_time) = 3 then 'Tuesday'
		when dayofweek(order_time) = 4 then 'Wednesday'
		when dayofweek(order_time) = 5 then 'Thursday'
		when dayofweek(order_time) = 6 then 'Friday'
		else 'Saturday'
    end as DayOfWeek, count(order_id) as Orders
from (
select distinct order_id, order_time from cleaned_customer_orders 
) as orderTable
group by DayOfWeek;
