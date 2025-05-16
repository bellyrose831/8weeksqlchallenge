-- C. Ingredient Optimisation

-- to help answer these questions, I'm using a temporary table:
create temporary table ordersWithWords as (
with extras as (
	select order_id, id, pizza_name, exclusions, extras, topping_id, topping_name
	from cleaned_customer_orders cco
		join pizza_names on pizza_names.pizza_id = cco.pizza_id
		join pizza_toppings on extras like concat(topping_id, ',%')
		or extras like concat('%, ', topping_id, ',%')
		or extras like concat('%, ', topping_id)
		or cast(extras as char) = cast(topping_id as char)
),
extrasCondensed as (
	select order_id, id, group_concat(topping_name separator ', ') as extras
	from extras
	group by order_id, id
),
exclusions as (
	select order_id, id, pizza_name, exclusions, extras, topping_id, topping_name
	from cleaned_customer_orders cco
		join pizza_names on pizza_names.pizza_id = cco.pizza_id
		join pizza_toppings on exclusions like concat(topping_id, ',%')
		or exclusions like concat('%, ', topping_id, ',%')
		or exclusions like concat('%, ', topping_id)
		or cast(exclusions as char) = cast(topping_id as char)
),
exclusionsCondensed as (
	select order_id, id, group_concat(topping_name separator ', ') as exclusions
	from exclusions
	group by order_id, id
)
select cco.id, cco.order_id, cco.customer_id, pizza_name,
	cco.order_time, exclusionsCondensed.exclusions, extrasCondensed.extras
from cleaned_customer_orders cco
	left join extrasCondensed on cco.id = extrasCondensed.id
    left join exclusionsCondensed on cco.id = exclusionsCondensed.id
    join pizza_names on cco.pizza_id = pizza_names.pizza_id
);
select * from ordersWithWords;
-- What are the standard ingredients for each pizza?
with allToppings as (
	select * 
	from pizza_recipes 
		join pizza_toppings on toppings like concat(topping_id, ',%')
			or toppings like concat('%, ', topping_id, ',%')
			or toppings like concat('%, ', topping_id)
			or toppings = topping_id
)
select pizza_name as Pizza, group_concat(topping_name separator ', ') as Ingredients
from allToppings
	join pizza_names on pizza_names.pizza_id = allToppings.pizza_id
group by pizza_name;


-- What was the most commonly added extra?
with extrasSplitOut as (
select order_id, id, pizza_name, exclusions, extras, topping_id, topping_name
	from cleaned_customer_orders cco
		join pizza_names on pizza_names.pizza_id = cco.pizza_id
		join pizza_toppings on extras like concat(topping_id, ',%')
		or extras like concat('%, ', topping_id, ',%')
		or extras like concat('%, ', topping_id)
		or cast(extras as char) = cast(topping_id as char)
)
select topping_name as MostCommonExtra
from extrasSplitOut
group by topping_name
order by count(*) desc
limit 1;

-- What was the most common exclusion?
with exclusionsSplitOut as (
select order_id, id, pizza_name, exclusions, extras, topping_id, topping_name
	from cleaned_customer_orders cco
		join pizza_names on pizza_names.pizza_id = cco.pizza_id
		join pizza_toppings on exclusions like concat(topping_id, ',%')
		or exclusions like concat('%, ', topping_id, ',%')
		or exclusions like concat('%, ', topping_id)
		or cast(exclusions as char) = cast(topping_id as char)
)
select topping_name as MostCommonExclusion
from exclusionsSplitOut
group by topping_name
order by count(*) desc
limit 1;

-- Generate an order item for each record in the customers_orders table in the format of one of the following:
	-- Meat Lovers
	-- Meat Lovers - Exclude Beef 
	-- Meat Lovers - Extra Bacon
	-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
select id, pizza_name, extras, exclusions,
	case
		when extras is not null and exclusions is not null then concat(pizza_name, ' - Exclude ', exclusions, ' - Extra ', extras)
        when extras is not null then concat(pizza_name, ' - Extra ', extras)
        when exclusions is not null then concat(pizza_name, ' - Exclude ', exclusions)
        else pizza_name
    end as order_item
from ordersWithWords;

-- Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
	-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
with allMenuToppings as (
	select null as id, null as order_id, pizza_names.pizza_name, topping_name, 1 as toppingValue, 'menu' as sources
	from pizza_recipes 
		join pizza_names on pizza_recipes.pizza_id = pizza_names.pizza_id
		join pizza_toppings on toppings like concat(topping_id, ',%')
		or toppings like concat('%, ', topping_id, ',%')
		or toppings like concat('%, ', topping_id)
		or toppings = topping_id
),
exclusionsSplitOut as (
	select id, order_id, pizza_name, topping_name, -1 as toppingValue, 'exclusions' as sources
	from cleaned_customer_orders cco
		join pizza_names on pizza_names.pizza_id = cco.pizza_id
		join pizza_toppings on exclusions like concat(topping_id, ',%')
		or exclusions like concat('%, ', topping_id, ',%')
		or exclusions like concat('%, ', topping_id)
		or cast(exclusions as char) = cast(topping_id as char)
),
extrasSplitOut as (
	select id, order_id, pizza_name, topping_name, 1 as toppingValue, 'extras' as sources
	from cleaned_customer_orders cco
		join pizza_names on pizza_names.pizza_id = cco.pizza_id
		join pizza_toppings on extras like concat(topping_id, ',%')
		or extras like concat('%, ', topping_id, ',%')
		or extras like concat('%, ', topping_id)
		or cast(extras as char) = cast(topping_id as char)
), 
allToppings as (
	select *
	from extrasSplitOut
	FULL UNION
	select *
	from exclusionsSplitOut
	FULL UNION
	select ordersWithWords.id, ordersWithWords.order_id, allMenuToppings.pizza_name, topping_name, toppingValue, sources
	from allMenuToppings
		join ordersWithWords on ordersWithWords.pizza_name = allMenuToppings.pizza_name
), 
allToppingsRanked as (
	select id, order_id, pizza_name, topping_name, sum(toppingValue),
		case 
			when sum(toppingValue) = 0 then null
			when sum(toppingValue) = 1 then topping_name
			else concat(count(*), 'x', topping_name)
		end as toppingCount
	from allToppings
	group by id, order_id, pizza_name, topping_name
	order by id, topping_name
), 
ingredientList as (
	select id, order_id, pizza_name, group_concat(toppingCount separator ', ') as ingredientslisted
	from allToppingsRanked
	where toppingCount is not null
	group by id, order_id, pizza_name
)
select id, order_id, concat(pizza_name, ': ', ingredientslisted) as IngredientList
from ingredientlist;

-- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
with allMenuToppings as (
	select null as id, null as order_id, pizza_names.pizza_name, topping_name, 1 as toppingValue
	from pizza_recipes 
		join pizza_names on pizza_recipes.pizza_id = pizza_names.pizza_id
		join pizza_toppings on toppings like concat(topping_id, ',%')
		or toppings like concat('%, ', topping_id, ',%')
		or toppings like concat('%, ', topping_id)
		or toppings = topping_id
),
exclusionsSplitOut as (
	select id, cco.order_id, pizza_name, topping_name, -1 as toppingValue
	from cleaned_customer_orders cco
		join pizza_names on pizza_names.pizza_id = cco.pizza_id
		join pizza_toppings on exclusions like concat(topping_id, ',%')
			or exclusions like concat('%, ', topping_id, ',%')
			or exclusions like concat('%, ', topping_id)
			or cast(exclusions as char) = cast(topping_id as char)
		join cleaned_runner_orders cro on cro.order_id = cco.order_id
	where cancellation is null
),
extrasSplitOut as (
select id, cco.order_id, pizza_name, topping_name, 1 as toppingValue
	from cleaned_customer_orders cco
		join pizza_names on pizza_names.pizza_id = cco.pizza_id
		join pizza_toppings on extras like concat(topping_id, ',%')
			or extras like concat('%, ', topping_id, ',%')
			or extras like concat('%, ', topping_id)
			or cast(extras as char) = cast(topping_id as char)
        join cleaned_runner_orders cro on cro.order_id = cco.order_id
	where cancellation is null
), allToppings as (
	select *
	from extrasSplitOut
	FULL UNION
	select *
	from exclusionsSplitOut
	FULL UNION
	select ordersWithWords.id, ordersWithWords.order_id, allMenuToppings.pizza_name, topping_name, toppingValue
	from allMenuToppings
		join ordersWithWords on ordersWithWords.pizza_name = allMenuToppings.pizza_name
        join cleaned_runner_orders cro on cro.order_id = ordersWithWords.order_id
	where cancellation is null
)
select topping_name, sum(toppingValue) as NumOrders
from allToppings 
group by topping_name
order by NumOrders desc, topping_name;
