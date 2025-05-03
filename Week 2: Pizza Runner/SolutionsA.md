# Case Study Questions & Solutions - Part A: Pizza Metrics

### Q1. How many pizzas were ordered?

#### Explanation:
Each pizza is displayed in its own row, with its own id value in the customer_orders table - which means we can simply use the aggregate function count to get the total number of pizzas ordered.  

We can see that there have been 14 pizzas ordered so far. 

#### SQL:
    select count(id) as PizzasOrdered from cleaned_customer_orders;

#### Results:
| PizzasOrdered |
| -------- | 
| 14 |

***
### Q2. How many unique customer orders were made?
    select count(distinct order_id) as UniqueCustomerOrders from cleaned_customer_orders;

***
### Q3. How many successful orders were delivered by each runner?
    select runner_id, count(distinct order_id) as OrdersDelivered
    from cleaned_runner_orders 
    where cancellation is null
    group by runner_id;

***
### Q4. How many of each type of pizza was delivered?
    select pizza_id, count(id) as PizzasOrdered 
    from cleaned_customer_orders
    group by pizza_id;

***
### Q5. How many Vegetarian and Meatlovers were ordered by each customer?
    select customer_id, sum(case when pizza_id = 1 then 1 else 0 end) as Meatlovers, sum(case when pizza_id = 2 then 1 else 0 end) as Vegetarian
    from cleaned_customer_orders
    group by customer_id;

***
### Q6. What was the maximum number of pizzas delivered in a single order?
    with orderCounts as (
    select cco.order_id, count(id) as numOrders
    from cleaned_customer_orders cco
    	join cleaned_runner_orders cro on cco.order_id = cro.order_id
    where cancellation is null
    group by order_id
    )
    select max(numOrders) from orderCounts;

***
### Q7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
    select customer_id, sum(case when (extras is not null or exclusions is not null) then 1 else 0 end) as Changes,
    	sum(case when (extras is null and exclusions is null) then 1 else 0 end) as NoChanges
    from cleaned_customer_orders
    group by customer_id;

***
### Q8. How many pizzas were delivered that had both exclusions and extras?
    select sum(case when (extras is not null and exclusions is not null) then 1 else 0 end) as ExclusionsAndExtras
    from cleaned_customer_orders;

***
### Q9. What was the total volume of pizzas ordered for each hour of the day?
    select hour(order_time) as hourOrdered, count(id) from cleaned_customer_orders
    group by hourOrdered;

***
### Q10. What was the volume of orders for each day of the week?
    select 
    	case
    		when dayofweek(order_time) = 1 then 'Sunday'
    		when dayofweek(order_time) = 2 then 'Monday'
    		when dayofweek(order_time) = 3 then 'Tuesday'
    		when dayofweek(order_time) = 4 then 'Wednesday'
    		when dayofweek(order_time) = 5 then 'Thursday'
    		when dayofweek(order_time) = 6 then 'Friday'
    		else 'Saturday'
        end as DayOfWeek, 
    count(id) as Orders from cleaned_customer_orders
    group by DayOfWeek;
