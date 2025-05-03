# Case Study Questions & Solutions - Part A: Pizza Metrics

### Q1. How many pizzas were ordered?

#### Explanation:
Each pizza is displayed in its own row, with its own id value in the customer_orders table - which means we can simply use the aggregate function count to get the total number of pizzas ordered.  

We can see that there have been 14 pizzas ordered. 

#### SQL:
    select count(id) as PizzasOrdered 
    from cleaned_customer_orders;

#### Results:
| PizzasOrdered |
| -------- | 
| 14 |

***
### Q2. How many unique customer orders were made?

#### Explanation:
Understanding unique and distinct to be synonymous in this context (and not to be excluding orders with identical numbers/types of pizzas), we can look to the order_id field and count the number of unique values.  

There have been 10 distinct customer orders. 

#### SQL:
    select count(distinct order_id) as UniqueCustomerOrders 
    from cleaned_customer_orders;

#### Results:
| UniqueCustomerOrders |
| -------- | 
| 10 |

***
### Q3. How many successful orders were delivered by each runner?

#### Explanation:
Here, we're looking at delivered orders (ie orders that were not cancelled by either party), separating those out by runner, and counting a total per runner to output. 

Here we see that Runner 1 has delivered the most pizzas, as many as runners 2 and 3 combined. Runner 1 has delivered 4 pizzas, runner 2 has delivered 3, and runner 3 has delivered 1. 

#### SQL:
    select runner_id, count(distinct order_id) as OrdersDelivered
    from cleaned_runner_orders 
    where cancellation is null
    group by runner_id;

#### Results:
| runner_id | OrdersDelivered |
| -------- | -------- |
| 1 | 4 |
| 2 | 3 |
| 3 | 1 |

***
### Q4. How many of each type of pizza was delivered?

#### Explanation:
For this question, I looked at pizzas (id) and grouped them by the type of pizza (pizza_name), joining the customer orders table to the pizza names tables to display the names of the pizzas, rather than simply their pizza_id values. 

The Meatlovers pizza seems to be more popular than the Vegetarian option, with 10 Meatlovers pizzas and 4 Vegetarian pizzas ordered.

#### SQL: 
    select pizza_name, count(id) as PizzasOrdered 
    from cleaned_customer_orders
    	join pizza_names on cleaned_customer_orders.pizza_id = pizza_names.pizza_id
    group by pizza_name;

#### Results:
| pizza_name | PizzasOrdered |
| -------- | -------- |
| Meatlovers | 10 |
| Vegetarian | 4 |

***
### Q5. How many Vegetarian and Meatlovers were ordered by each customer?

#### Explanation:
To answer this question, I used a combination of the sum function and case statements to calculate the total number of vegetarian and meatlovers pizzas. To calculate the meatlovers total per customer, I had it sum a series of 1's and 0's relating to each pizza - if the pizza_id was 1, then the pizza was meatlovers, and 1 should be added to the total; otherwise, the pizza wasn't meatlovers and shouldn't impact the total number of meatlovers pizzas, so a 0 was added. A reciprocal but similar process was followed for vegetarian pizzas, looking for pizza_id 2. Since we wanted the results broken out by customer, the results are grouped by customer_id. 

Customers 101, 102, and 103 have ordered both Meatlovers and Vegetarian pizzas. Customer 104 has ordered Meatlovers pizzas exclusively and Customer 105 has only ordered Vegetarian pizzas. Customers 101 and 102 both ordered 3 total pizzas: 2 meatlovers and 1 vegetarian. Customer 103 ordered the most total pizzas, with 3 meatlovers and 1 vegetarian. Customer 104 ordered 3 meatlovers pizzas and Customer 105 ordered 1 vegetarian pizza. 

#### SQL:
    select customer_id, sum(case when pizza_id = 1 then 1 else 0 end) as Meatlovers, sum(case when pizza_id = 2 then 1 else 0 end) as Vegetarian
    from cleaned_customer_orders
    group by customer_id;

#### Results:
| customer_id | Meatlovers | Vegetarian |
| -------- | -------- | -------- |
| 101 | 2 | 1 |
| 102 |	2 | 1 |
| 103 |	3 |	1 |
| 104 |	3 |	0 |
| 105 |	0 |	1 |

***
### Q6. What was the maximum number of pizzas delivered in a single order?

#### Explanation:
In this query, I used a CTE to find out how many pizzas were included in each order that was delivered, then found the maximum value from that CTE and output that as the maximum number of pizzas delivered in a single order.

The largest order received was three pizzas. 

#### SQL:
    with orderCounts as (
    select cco.order_id, count(id) as numOrders
    from cleaned_customer_orders cco
    	join cleaned_runner_orders cro on cco.order_id = cro.order_id
    where cancellation is null
    group by order_id
    )
    select max(numOrders) as MostPizzas from orderCounts;

#### Results:
| MostPizzas |
| -------- |
| 3 |


***
### Q7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

#### Explanation:
This query is structured similarly to that from question 5, wth sum and case being used to tandem to determine for each delivered order which scenario was true, and increasing the relevant total by 1. As we're specifically looking for by-customer results for delivered pizzas, the results only show pizzas that were not cancelled by either party, and totals are shown for each customer. '

Customers 101 and 102 both only had delivered pizzas with no changes, 2 and 3 respectively. Customers 103 and 105 were just the opposite - only receiving pizzas with changes, 3 and 1 pizzas respectively. Customer 104 was the only customer who had pizzas delivered with changes (2) and without changes (1). 

#### SQL:
    select cco.customer_id, sum(case when (extras is not null or exclusions is not null) then 1 else 0 end) as Changes,
	sum(case when (extras is null and exclusions is null) then 1 else 0 end) as NoChanges
    from cleaned_customer_orders cco
    	join cleaned_runner_orders cro on cco.order_id = cro.order_id
    where cancellation is null
    group by cco.customer_id;

#### Results:
| customer_id | Changes | NoChanges |
| -------- | -------- | -------- |
| 101 |	0 |	2 |
| 102 |	0 |	3 |
| 103 |	3 |	0 |
| 104 |	2 |	1 |
| 105 |	1 |	0 |

***
### Q8. How many pizzas were delivered that had both exclusions and extras?

#### Explanation:
Like the queries for questions 5 and 7, this query uses sum combined with a case statement to calculate a total for a particular scenario - in this case, we want to know the number of pizzas where the extras and exclusions fields both have some value. For each pizza where that is true, we increment the total by 1, otherwise, the total does not change. 

Only 1 pizza was delivered with both exclusions and extras. 

#### SQL: 
    select sum(case when (extras is not null and exclusions is not null) then 1 else 0 end) as ExclusionsAndExtras
    from cleaned_customer_orders;

#### Results:
| ExlusionsAndExtras |
| -------- |
| 1 |

***
### Q9. What was the total volume of pizzas ordered for each hour of the day?

#### Explanation:
To answer this question, I used the hour function that returns the hour portion of a date and time value. Once I obtained that value for each pizza, I was able to count the total number of records for each hour value, and then return the hours and volumes in ascending order.

Pizzas were ordered between 11am and 11pm - with the most frequent order times being 1pm, 6pm, 9pm, and 11pm, with 3 pizzas orderd in each of those hours. They also received a single pizza order at 11am and at 7pm.

#### SQL:
    select hour(order_time) as hourOrdered, count(id) as Volume
    from cleaned_customer_orders 
    group by hourOrdered
    order by hourOrdered;

#### Results: 
| hourOrdered | Volume |
| -------- | -------- |
| 11 |	1 |
| 13 |	3 |
| 18 |	3 |
| 19 |	1 |
| 21 |	3 |
| 23 |	3 |

***
### Q10. What was the volume of orders for each day of the week?

#### Explanation:
Here, I utilized the dayofweek function to determine which days were related to which orders and a subquery to ensure the results pertained to orders rather than pizzas. To increase readability in the results, I used a case statement to convert the numerical values output by the dayofweek function to their equivalent day names.

From this, wee can see that they received orders on each day Wednesday through Saturday, with half of the orders occurring on Wednesday. Out of 10 total orders, they saw 5 on Wednesday, 2 on Thursday, 1 on Friday, and 2 on Saturday. 

#### SQL:
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

#### Results:
| DayOfWeek | Orders |
| -------- | -------- |
| Wednesday | 5 |
| Thursday | 2 |
| Saturday | 2 |
| Friday | 1 |
