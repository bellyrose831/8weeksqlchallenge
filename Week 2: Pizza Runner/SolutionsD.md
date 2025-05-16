# Case Study Questions & Solutions - Part D: Pricing and Ratings

### Q1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

#### Explanation:
This question can be answered with a combination of a case statement and the sum function. Here, I use a case statement to assign the prices of $12 and $10 to Meatlovers and Vegarian pizzas, respectively, through a CTE, then sum the prices and display that total as the result.

#### SQL:
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

#### Results:
| MoneyMade |
| -------- |
| 160 |

***
### Q2. What if there was an additional $1 charge for any pizza extras?

#### Explanation:
This question builds on the scenario from the previous question, so this query also build on that one as a base. Additionally, to account for the topping charges for extras, an additional case statement has been added to the CTE to account for three scenarios relating to extras: 1) if there are no extras, the extra-related cost is $0; 2) if there is 1 extra (and therefore that field is not null, but doesn't include any commas), the additional cost is $1; 3) if there are multiple extras (there is at least one comma in that field), then the cost can be calculated by finding the number of commas in the field and adding 1 (a list with 2 items has 1 comma and is then $2, a list with 3 items has 2 commas and is then $3, etc). Finally, the prices of the base pizzas are added to the extra costs from extras to get the total.

#### SQL: 
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

#### Results:
| MoneyMade |
| -------- |
| 166 |

***
### Q3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

#### Explanation:
For the ratings table, I included some basic fields - the runner_id and order_id to connect to existing data collected. Then, for the review itself, there is an optional comments field that accepts text (up to 200 characters) if they want to leave a detailed review and then a mandatory rating field that must be an integer value 1-5. Then, I inserted some data into that table (attempted to draw from the data to guess at reasonable reviews) for each of the orders that was delivered.

#### SQL:
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

#### Results:
| runner_id | order_id | comments | rating |
| -------- | -------- | -------- | -------- |
| 1 |	1 |	nice kid, pizzas still felt fresh out of the oven even though we live pretty far |	5 |
| 1 |	2 |	Had the same driver, nice to see a familiar face! Love to see kids getting involved in local businesses |	5 |
| 1 |	3 | | 	4 |
| 1 |	10 	|	| 5 |
| 2 |	4 |	Took over an hour to get three pizzas |	2 |
| 2 |	7 |	 |	5 |
| 2 |	8 |	dude had super speed |	5 |
| 3 |	5 |	|	4 |

***
### Q4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
- customer_id
- order_id
- runner_id
- rating
- order_time
- pickup_time
- Time between order and pickup
- Delivery duration
- Average speed
- Total number of pizzas

#### Explanation:
This question's answer is fairly straightforward! The table is built by adding the results of a query as data in the newly created temporary table all_info. In that query, the new table from question 3 is combined with the customer orders and runner orders tables to retrieve all of the requested data. Orders that were cancelled by either party are excluded from the results and thereby the new table.

#### SQL:
        create temporary table all_info as (
            select customer_id, rr.order_id, rr.runner_id, rating, order_time, pickup_time, timediff(pickup_time, order_time) as time_between_order_and_pickup, duration, round(distance / duration,2) as average_speed, count(id) as total_number_pizzas
            from runner_ratings rr
            	join cleaned_customer_orders cco on rr.order_id = cco.order_id
                join cleaned_runner_orders cro on cro.order_id = cco.order_id
            where cancellation is null
            group by customer_id, rr.order_id, rr.runner_id, rating, order_time, pickup_time, time_between_order_and_pickup, duration, average_speed
        );
        select * from all_info;

#### Results:
| customer_id | order_id | runner_id | rating | order_time | pickup_time | time_between_order_and_pickup | duration | average_speed | total_number_pizzas |
| -------- | -------- | -------- | -------- | -------- | -------- | -------- | -------- | -------- | -------- |
| 101 |	1 |	1 |	5 |	2020-01-01 18:05:02 |	2020-01-01 18:15:34 |	00:10:32.000000 |	32 |	0.62 |	1 |
| 101 |	2 |	1 |	5 |	2020-01-01 19:00:52 |	2020-01-01 19:10:54 |	00:10:02.000000 |	27 |	0.74 |	1 |
| 102 |	3 |	1 |	4 |	2020-01-02 23:51:23 |	2020-01-03 00:12:37 |	00:21:14.000000 |	20 |	0.67 |	2 |
| 103 |	4 |	2 |	2 |	2020-01-04 13:23:46 |	2020-01-04 13:53:03 |	00:29:17.000000 |	40 |	0.58 |	3 |
| 104 |	5 |	3 |	4 |	2020-01-08 21:00:29 |	2020-01-08 21:10:57 |	00:10:28.000000 |	15 |	0.67 |	1 |
| 105 |	7 |	2 |	5 |	2020-01-08 21:20:29 |	2020-01-08 21:30:45 |	00:10:16.000000 |	25 |	1 |	1 |
| 102 |	8 |	2 |	5 |	2020-01-09 23:54:33 |	2020-01-10 00:15:02 |	00:20:29.000000 |	15	| 1.56|	1 |
| 104 |	10 |	1 |	5 |	2020-01-11 18:34:49 |	2020-01-11 18:50:20 |	00:15:31.000000 |	10 |	1 |	2 |

***
### Q5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

#### Explanation:
To answer this question, we need to calculate and find the difference of the money brought in from base pizza costs (calculated in question 1 of this section) and the amounts paid out to runners for their deliveries. The first is calculated for each pizza, and the second for each order, so these needed to be calculated separately. The first two CTEs calculate the money brought in by pizzas (CTE 1), and change it to be in terms of orders, rather than pizzas (CTE 2), so it can be ultimately joined to the table with runner costs. The third CTE calculates the runner costs per order. Then, the final query joins the reuslts of teh second and third CTEs and subtracts the total runner costs from the total money made from the pizzas.

#### SQL:
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

#### Results:
| MoneyMade |
| -------- |
| 1047.96 | 
