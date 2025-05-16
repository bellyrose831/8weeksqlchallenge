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

### Q3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

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
