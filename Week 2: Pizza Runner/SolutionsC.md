# Case Study Questions & Solutions - Part C: Ingredient Optimisation

### Some prework...
To help answer these questions, I've created a temporary table, ordersWithWords. This table tranforms the information from (cleaned) customer orders, changing the extras, exclusions, and pizza id columns from integer values to their corresponding values in words, gathering the new values from the pizza_names and pizza_toppings tables. 

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

Here's what that table looks like...
| id | order_id | customer_id | pizza_name | order_time | exclusions | extras |
| -------- | -------- | -------- | -------- | -------- | -------- | -------- |
| 1 |	1 |	101 |	Meatlovers |	2020-01-01 18:05:02 |  |  |
| 2 |	2 |	101 |	Meatlovers |	2020-01-01 19:00:52 |  |  |		
| 3 |	3 |	102 |	Meatlovers |	2020-01-02 23:51:23 |  |  |	
| 4 |	3 |	102 |	Vegetarian |	2020-01-02 23:51:23 |	 |	|
| 5 |	4 |	103 |	Meatlovers |	2020-01-04 13:23:46 |	Cheese |  |
| 6 |	4 |	103 |	Meatlovers |	2020-01-04 13:23:46 |	Cheese |	|
| 7 |	4 |	103 |	Vegetarian |	2020-01-04 13:23:46 |	Cheese |	|
| 8 |	5 |	104 |	Meatlovers |	2020-01-08 21:00:29 |	 |	Bacon |
| 9 |	6 |	101 |	Vegetarian |	2020-01-08 21:03:13 |	 |	|
| 10 |	7 |	105 |	Vegetarian |	2020-01-08 21:20:29 |	 |	Bacon |
| 11 |	8 |	102 |	Meatlovers |	2020-01-09 23:54:33 |  |  |
| 12 |	9 |	103 |	Meatlovers |	2020-01-10 11:22:59 |	Cheese |	Bacon, Chicken |
| 13 |	10 |	104 |	Meatlovers |	2020-01-11 18:34:49 |	 |  |	
| 14 |	10 |	104 |	Meatlovers |	2020-01-11 18:34:49 |	BBQ Sauce, Mushrooms |	Bacon, Cheese |

***
### Q1. What are the standard ingredients for each pizza?

#### SQL:
    with allToppings as (
    	select * 
    	from pizza_recipes 
    		join pizza_toppings
    	where toppings like concat(topping_id, ',%')
    		or toppings like concat('%, ', topping_id, ',%')
    		or toppings like concat('%, ', topping_id)
    		or toppings = topping_id
    )
    select pizza_name as Pizza, group_concat(topping_name separator ', ') as Ingredients
    from allToppings
    	join pizza_names on pizza_names.pizza_id = allToppings.pizza_id
    group by pizza_name;

#### Results:
| Pizza | Ingredients |
| -------- | -------- |
| Meatlovers |	Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| Vegetarian |	Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce |

***
### Q2. What was the most commonly added extra?

#### SQL:
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

#### Results:
| MostCommonExtra |
| -------- |
| Bacon |

***
### Q3. What was the most common exclusion?

#### SQL:
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

#### Results:
| MostCommonExclusion |
| -------- |
| Cheese |

***
### Q4. Generate an order item for each record in the customers_orders table in the format of one of the following:
  - Meat Lovers
	- Meat Lovers - Exclude Beef 
	- Meat Lovers - Extra Bacon
	- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

#### SQL:
    select id, pizza_name, extras, exclusions,
    	case
    		when extras is not null and exclusions is not null then concat(pizza_name, ' - Exclude ', exclusions, ' - Extra ', extras)
            when extras is not null then concat(pizza_name, ' - Extra ', extras)
            when exclusions is not null then concat(pizza_name, ' - Exclude ', exclusions)
            else pizza_name
        end as order_item
    from ordersWithWords;

#### Results:
| id | pizza_names | extras | exclusions | order_item |
| -------- | -------- | -------- | -------- | -------- |
| 1 |	Meatlovers |	|	 |	Meatlovers |
| 2 |	Meatlovers | | |	Meatlovers |
| 3 |	Meatlovers | | |	Meatlovers |
| 4 |	Vegetarian | | |	Vegetarian |
| 5 |	Meatlovers | |	Cheese |	Meatlovers - Exclude Cheese |
| 6 |	Meatlovers | |		Cheese |	Meatlovers - Exclude Cheese |
| 7 |	Vegetarian |	|	Cheese |	Vegetarian - Exclude Cheese |
| 8 |	Meatlovers |	Bacon |	|	Meatlovers - Extra Bacon |
| 9 |	Vegetarian |	| |	Vegetarian |
| 10 |	Vegetarian |	Bacon |	|	Vegetarian - Extra Bacon |
| 11 |	Meatlovers |	|	|	Meatlovers|
| 12 |	Meatlovers |	Bacon, Chicken |	Cheese |	Meatlovers - Exclude Cheese - Extra Bacon, Chicken |
| 13 |	Meatlovers |	 |	|	Meatlovers |
| 14 |	Meatlovers |	Bacon, Cheese |	BBQ Sauce, Mushrooms |	Meatlovers - Exclude BBQ Sauce, Mushrooms - Extra Bacon, Cheese |

***
### Q5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
  - For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

#### SQL:
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
    ), allToppings as (
    	select *
    	from extrasSplitOut
    	FULL UNION
    	select *
    	from exclusionsSplitOut
    	FULL UNION
    	select ordersWithWords.id, ordersWithWords.order_id, allMenuToppings.pizza_name, topping_name, toppingValue, sources
    	from allMenuToppings
    		join ordersWithWords on ordersWithWords.pizza_name = allMenuToppings.pizza_name
    ), allToppingsRanked as (
    	select id, order_id, pizza_name, topping_name, sum(toppingValue),
    		case 
    			when sum(toppingValue) = 0 then null
    			when sum(toppingValue) = 1 then topping_name
    			else concat(count(*), 'x', topping_name)
    		end as toppingCount
    	from allToppings
    	group by id, order_id, pizza_name, topping_name
    	order by id, topping_name
    ), ingredientList as (
    	select id, order_id, pizza_name, group_concat(toppingCount separator ', ') as ingredientslisted
    	from allToppingsRanked
    	where toppingCount is not null
    	group by id, order_id, pizza_name
    )
    select id, order_id, concat(pizza_name, ': ', ingredientslisted) as IngredientList
    from ingredientlist;

#### Results:
| id | order_id | IngredientList |
| -------- | -------- | -------- |
| 1 |	1 |	Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 2 |	2 |	Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 3 |	3 |	Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 4 |	3 |	Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes |
| 5 |	4 |	Meatlovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami |
| 6 |	4 |	Meatlovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami |
| 7 |	4 |	Vegetarian: Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes |
| 8 |	5 |	Meatlovers: 2xBacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 9 |	6 |	Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes |
| 10 |	7 |	Vegetarian: Bacon, Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes |
| 11 |	8 |	Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 12 |	9 |	Meatlovers: 2xBacon, BBQ Sauce, Beef, 2xChicken, Mushrooms, Pepperoni, Salami |
| 13 |	10 |	Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 14 |	10 |	Meatlovers: 2xBacon, Beef, 2xCheese, Chicken, Pepperoni, Salami |

***
### Q6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

#### SQL:
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

#### Results:
| topping_name | NumOrders |
| -------- | -------- |
| Mushrooms	 | 11 |
| Bacon	| 10 |
| Beef	| 9 |
| Cheese |	9 |
| Chicken |	9 |
| Pepperoni |	9 |
| Salami |	9 |
| BBQ Sauce |	8 |
| Onions |	3 |
| Peppers |	3 |
| Tomato Sauce |	3 |
| Tomatoes |	3 |
