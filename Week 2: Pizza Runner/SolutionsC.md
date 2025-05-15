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

#### Explanation:
To get the standard ingredients for each pizza, I first needed to transform the recipe table, which contained a list of topping ids associated with each pizza id, into words. To do this, I joined pizza_toppings to pizza_recipes with a compound condition to account for each position in the list a topping id count be in (first, middle, last, only). Since there is a topping with id 1, and another with id 11, this complex condition is necessary (over, say, a simpler toppings like concat('%', topping_id, '%')) so that 1s are not matched with 11s or 12s - and it does so by locating the ids in the list relative to the commas around them. Once I had a table with a row for each topping, for each pizza id, I grouped those rows back into a list by type of pizza, and joined the pizza names table to display the names in words rather than by id value, for clarity in udnerstanding & easy reference. 

#### SQL:
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

#### Results:
| Pizza | Ingredients |
| -------- | -------- |
| Meatlovers |	Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| Vegetarian |	Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce |

***
### Q2. What was the most commonly added extra?

#### Explanation:
To answer this question, I followed the same general format as in the last query - first, get a table with one row per topping per pizza, then, group the results & display only the relevant rows. In the first steps, the list of toppings to split into rows was the "extras" column. For those, I used a CTE with the same structure of condition on the join to ensure that only proper matches are happening, and also join the pizza names table, so we can display the names in words again as well. Then, the rest of the query takes the results from the CTE, group by topping names and counts how many times those names occur. Then, the highest-count topping is displayed as the top row, and the results limited just to show that record. 

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

#### Explanation:
This query is near-identical to the one above, with extras swapped out for exclusions. 

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

#### Explanation:
This query is relatively straightforward, compared to others in this section. The crux here is a case statement, defining values of the order items based on whether a pizza has extras and/or exlusions. The temporary table I created at the top of this section is used to provide the extras and exclusions in words, rather than topping ids, as it is displayed in the original orders tables. 

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

#### Explanation:
I could not find a simpler way to answer this question, so 6 CTEs it was. Here's a quick description of the purpose of each:
1. Get a table with a row for each topping for each standard menu item, from the recipes. Give each of those rows a value of 1, since the ingredient is added once for each time it's listed in the recipe.
 2. As in question 3, create a table that splits out exclusions into a row per topping per pizza id. These are given a value of -1, since the ingredient is removed once for each time it's listed in the exclusions, effectively canceling out the specified ingredients where they were added from the recipe. 
 3. As in question 2, create a table that splits out extras into a row per topping per pizza id. These are given a value of 1, since the ingredient is added once for each time it's listed in the extras.
 4. This combined the above created three tables using a UNION, to produce a list of all toppings added or removed from each pizza. A Full Union is used so that anything purposefully doubled in orders or extras wouldn't be removed (if this were to be on a future order or menu item). The first table is joined with the new temporary table created above in order to connect pizza ids with the recipes they use - so the rows for each recipe are duplicated for each pizza of that recipe, and connecting those rows with the pizza id.
 5. The "allToppingsRanked" table doesn't actually use the rank function (anymore), instead summing the values associated with each topping for each pizza, and producing the count of how many times each topping is on each pizza. If a topping is included more than once on a pizza, it format that as 2x the topping name
 6. Grouping by pizza ids, the ingredient name/counts from the last table are formatted as a comma-separated list. Since I'm using the group_concat function to do this, it has to be a separate step from using the concat function to add the pizza name in front of this list.
 7. Last but not last, I used concat to add the pizza name and a colon in front of the ingredient lists, and display the results by pizza id and order. 

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

#### Explanation:
This query is also somewhat large and unwieldy. If this were to be used frequently, it would probably be worth looking into refactoring it, but our purposes, this will work. The 4 CTEs here closely align with the first four from the last question, but add the criteria that the orders must not have been canceled, since we are only interested in delivered pizzas, not ordered pizzas. The last piece of this query also differs from the previous, again leveraging the sum function on the values of the toppings, but grouping by topping without regard for pizza id, since we're looking at overall ingredient quantities used by the restaurant. Finally, the results are ordered to display the most frequently used ingredients first. 

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
