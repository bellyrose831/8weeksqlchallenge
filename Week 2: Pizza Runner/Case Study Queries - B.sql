-- B. Runner and Customer Experience
-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
select floor(day(timediff(registration_date, '2021-01-01')) / 7) + 1 as week, count(runner_id) as SignUps
from runners
group by week;

-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
select runner_id, round(avg(arrivalTime), 0) as arrivalTime
from (
	select distinct cro.runner_id, cro.order_id, minute(timediff(pickup_time,order_time)) as arrivalTime
	from cleaned_runner_orders cro
		join cleaned_customer_orders cco on cco.order_id = cro.order_id
	order by runner_id 
) as orderTimes
group by runner_id;

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?
select cco.order_id, count(id) as numPizzas, round(avg(minute(timediff(pickup_time,order_time))),0) as prepTime
from cleaned_runner_orders cro
		join cleaned_customer_orders cco on cco.order_id = cro.order_id
where pickup_time is not null
group by cco.order_id
order by numPizzas, prepTime;

-- What was the average distance travelled for each customer?
select customer_id, avg(distance) as distance
from 
(
select distinct customer_id, cco.order_id, distance 
from cleaned_runner_orders cro
	join cleaned_customer_orders cco on cro.order_id = cco.order_id
) as orderDistances
group by customer_id;

-- What was the difference between the longest and shortest delivery times for all orders?
select max(duration) - min(duration) as timeDifference
from cleaned_runner_orders;

-- What was the average speed for each runner for each delivery and do you notice any trend for these values?
select runner_id, cro.order_id, count(id) as numPizzas, distance, duration, round(duration/distance, 2) as speed
from cleaned_runner_orders cro
	join cleaned_customer_orders cco on cro.order_id = cco.order_id
where cancellation is null
group by runner_id, cro.order_id, distance, duration
order by runner_id;

select runner_id, count(order_id) as ordersDelivered
from cleaned_runner_orders
where cancellation is null
group by runner_id;

select runner_id, round(avg(duration),2) as avgDuration, round(avg(distance),2) as avgDistance
from cleaned_runner_orders
where cancellation is null
group by runner_id;

select runner_id, round(avg(duration/distance), 2) as avgSpeed
from cleaned_runner_orders
where cancellation is null
group by runner_id;

-- What is the successful delivery percentage for each runner?
select runner_id, round(100 * sum(case when cancellation is null then 1 else 0 end) / count(order_id), 0) as deliveryPercentage
from cleaned_runner_orders
group by runner_id;
