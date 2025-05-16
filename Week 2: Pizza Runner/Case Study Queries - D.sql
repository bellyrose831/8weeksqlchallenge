-- D. Pricing and Ratings
-- If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - 
		-- how much money has Pizza Runner made so far if there are no delivery fees?
        
with PizzaPrices as (
select id, pizza_name, 
	case 
		when pizza_name = 'Meatlovers' then 12
        when pizza_name = 'Vegetarian' then 10
    end as price
from cleaned_customer_orders cco
	join pizza_names on cco.pizza_id = pizza_names.pizza_id
)
select sum(price) as MoneyMade from PizzaPrices;

-- What if there was an additional $1 charge for any pizza extras?
		-- Add cheese is $1 extra

with PizzaPrices as (
select id, pizza_name, extras,
	case 
		when pizza_name = 'Meatlovers' then 12
        when pizza_name = 'Vegetarian' then 10
    end as price,
    case
		when extras is null then 0
        when extras not like '%,%' then 1
        when extras like '%,%' then 1 + length(extras) - length(replace(extras, ',', ''))
    end as extrasPrice
from cleaned_customer_orders cco
	join pizza_names on cco.pizza_id = pizza_names.pizza_id
)
select sum(price)+sum(extrasPrice) as MoneyMade from PizzaPrices;

-- The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
	-- how would you design an additional table for this new dataset - 
	-- generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

create temporary table runner_ratings (
	runner_id INTEGER NOT NULL,
    order_id INTEGER NOT NULL,
    comments VARCHAR(200),
    rating INTEGER NOT NULL,
    CHECK (rating <= 5)
);
INSERT INTO runner_ratings
	(runner_id, order_id, comments, rating)
VALUES
(1, 1, "nice kid, pizzas still felt fresh out of the oven even though we live pretty far" , 5),
(1, 2, "Had the same driver, nice to see a familiar face! Love to see kids getting involved in local businesses", 5),
(1, 3, null, 4),
(2, 4, "Took over an hour to get three pizzas", 2),
(3, 5, null, 4),
(2, 7, null, 5),
(2, 8, "dude had super speed" , 5),
(1, 10, null, 5);

select * from runner_ratings
order by runner_id;

-- Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
	-- customer_id
	-- order_id
	-- runner_id
	-- rating
	-- order_time
	-- pickup_time
	-- Time between order and pickup
	-- Delivery duration
	-- Average speed
	-- Total number of pizzas
create temporary table all_info as (
select customer_id, rr.order_id, rr.runner_id, rating, order_time, pickup_time, timediff(pickup_time, order_time) as time_between_order_and_pickup, duration, round(distance / duration,2) as average_speed, count(id) as total_number_pizzas
from runner_ratings rr
	join cleaned_customer_orders cco on rr.order_id = cco.order_id
    join cleaned_runner_orders cro on cro.order_id = cco.order_id
where cancellation is null
group by customer_id, rr.order_id, rr.runner_id, rating, order_time, pickup_time, time_between_order_and_pickup, duration, average_speed
);
select * from all_info;

-- If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - 
		-- how much money does Pizza Runner have left over after these deliveries?
        
with PizzaPrices as (
select id, cco.order_id, pizza_name,
	case 
		when pizza_name = 'Meatlovers' then 12
        when pizza_name = 'Vegetarian' then 10
    end as price
from cleaned_customer_orders cco
	join pizza_names on cco.pizza_id = pizza_names.pizza_id
),
OrderPizzaPrices as (
select order_id, sum(price) as order_price
from PizzaPrices
group by order_id
),
RunnerCosts as (
select order_id, .3 * distance as runner_cost
from cleaned_runner_orders
)
select round(sum(order_price)-sum(runner_cost),2) as MoneyMade 
from OrderPizzaPrices
	join RunnerCosts on OrderPizzaPrices.order_id - RunnerCosts.order_id;