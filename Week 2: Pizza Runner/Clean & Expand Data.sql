-- clean data

-- Customer Orders
-- exclusions and extras have funky data - we can clean these and create a temp table with the cleaned values
drop table if exists cleaned_customer_orders;
create temporary table cleaned_customer_orders (
  id INTEGER,
  order_id INTEGER,
  customer_id INTEGER,
  pizza_id INTEGER,
  exclusions VARCHAR(4),
  extras VARCHAR(4),
  order_time TIMESTAMP
);

insert into cleaned_customer_orders
select row_number() over (), order_id, customer_id, pizza_id, 
	case 
		when exclusions = '' or exclusions = 'null' then null
		else exclusions 
    end as cleaned_exclusions,
    case
		when extras = '' or extras = 'null' then null
        else extras
    end as cleaned_extras,
    order_time
from customer_orders;

select * from cleaned_customer_orders;

--  Runner Orders
-- pickup_time, distance, duration, and cancellation fields need to be cleaned
drop table if exists cleaned_runner_orders;
create temporary table cleaned_runner_orders like runner_orders;

insert into cleaned_runner_orders
select order_id, runner_id,
	case
		when pickup_time = '' or pickup_time = 'null' then null
        else pickup_time
    end as cleaned_pickup_time,
    case
		when distance = '' or distance = 'null' then null
        else replace(distance, 'km', '')
    end as cleaned_distance,
    case
		when duration = '' or duration = 'null' then null
        else replace(replace(replace(replace(replace(duration, 'minutes', ''), 'minute', ''), 'mins', ''), 'min', ''), ' ', '')
    end as cleaned_duration,
    case
		when cancellation = '' or cancellation = 'null' then null
        else cancellation
    end as cleaned_cancellation
from runner_orders;

select * from cleaned_runner_orders;

-- expand date
-- prompt: If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT 
-- statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

-- this doesn't impact the customer orders
-- this doesn't impact pizza toppings
-- this doesn't impact runner orders
-- this doesn't impact runners
-- Impacted: pizza names and pizza recipes tables

-- pizza names:
insert into pizza_names 
values (3, "Supreme");

-- pizza recipes 
-- supreme will have: cheese (4), tomato sauce (12), onion (7), peppers (9), pepperoni (8), bacon (1)
insert into pizza_recipes
values (3, '1, 4, 7, 8, 9, 12');
