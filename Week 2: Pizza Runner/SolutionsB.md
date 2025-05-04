# Case Study Questions & Solutions - Part B: Runner and Customer Experience

### Q1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

#### Explanation:
To answer this question, I utilized a few different functions: floor, day, timediff, and count. There is a function "week" that returns an integer value representing the week of a certain date - however, that couldn't be used for this question, since it starts week 0 on the first Sunday of the year, not the first day of the year. Since 02/02/2021 isn't a Sunday, the weeks returned from that function are a few days off from the results desired here. To get week numbers that start counting on the date specified, I started by finding the number of days between 01/01/2021 and the registration date for each runner. From that value, I divided by 7 to get the number of weeks between 01/01/2021 and the registration date. Then, since that count be a decimal value, I used the floor function to get the nearest integer that is smaller than that value - for example, if a registration date is .7 weeks after 01/01/2021, we would want the week value to be 0, since it hasn't yet been a whole week since the first, and those dates would be in the same week. I then added 1 to each week value - it makes a lot more sense to a general audience for the first week to be week 1. Finally, I used count to count the instance of the rounded-down values for each week, and show those counts as the output.  

We can see that all runners signed up in the first three weeks of the year, with two signing up in the first week of the year, and then one more in the second and third weeks. 

#### SQL:
    select floor(day(timediff(registration_date, '2021-01-01')) / 7) + 1 as week, count(runner_id) as SignUps
    from runners
    group by week;

#### Results:
| week | SignUps |
|-------- | -------- |
| 1 |	2 |
| 2 |	1 |
| 3 |	1 |

***
### Q2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

#### Explanation:
For this query, I used a subquery to get the average time it tooks the runners to arrive for each order to ensure that I wasn't double counting orders with multiple pizzas. From there, I was able to average those times, grouping by runner ids, and output a rounded value to represent the time in minutes each runner took to pickup their orders, on average. 

Runner 3 had the shortest average arrival time, at just 10 minutes per order, with runner 1 following with 14 minutes per order. AT 20 minutes per order, runner 2 has the slowest arrival time of the three. There is a fourth runner registered, but they did not deliver any orders. 

#### SQL: 
    select runner_id, round(avg(arrivalTime), 0) as arrivalTime
    from (
    	select distinct cro.runner_id, cro.order_id, minute(timediff(pickup_time,order_time)) as arrivalTime
    	from cleaned_runner_orders cro
    		join cleaned_customer_orders cco on cco.order_id = cro.order_id
    	order by runner_id 
    ) as orderTimes
    group by runner_id;

#### Results:
| runner_id | ArrivalTime |
|-------- | -------- |
| 1 |	14 |
| 2 |	20 |
| 3 |	10 |

***
### Q3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

#### Explanation:
Quick note: the phrasing of this question seems to be contradictory to that of the last question - in Q2, it's implied that the time between order time and pickup time is based on the runner, here it's implied to be prep time for the order, related to the work being done in the kitchen. I've answered both questions using those two times as the prompts seem to imply they should be used, but did want to note the discepancy in the interpretation of that chunk of time. 

Here, I use round, average, minute, and timediff functions to find the time between order and pickup times for each of the orders (average is necessary because I'm using a group by, but since all pizzas in an order have the same order time and pickup time, this just gets that time difference). Since we want the end result to be grouped by orders, we don't need a subquery here to ensure we're evenly weighting all orders. To make comparing these values easier, I've sorted the output by the number of pizzas in the order, and then the preparation time. 

From the results, we can see that generally, orders with less pizzas require less prep time than orders with more pizzas. This is clearly supported by running another query to show the average prepTime for each numPizzas value has the avergae prep time for 1 pizza is 12 minutes, for 2 pizzas is 18 minutes, and for 3 pizzas is 29 minutes. The results shown here also give a higher level of detail, showing a one order in particular that defies this pattern - order 8, which took 20 minutes to prepare one pizza. However, the pattern that prep time increases is related to the number of pizzas in an order at the roughly linear pace of 10 mins/pizza is fairly well-supported by the data as a whole. Danny can use this data to estimate what time runners will need to be at Headquarters, to anticipate staffing needs as business increases, and to potentially evaluate and rework the efficiency of the pizza preparation process.

#### SQL:
    select cco.order_id, count(id) as numPizzas, round(avg(minute(timediff(pickup_time,order_time))),0) as prepTime
    from cleaned_runner_orders cro
    		join cleaned_customer_orders cco on cco.order_id = cro.order_id
    where pickup_time is not null
    group by cco.order_id
    order by numPizzas, prepTime;

#### Results:
| order_id | numPizzas | prepTime |
| -------- | -------- | -------- |
| 1 |	1 |	10 |
| 2 |	1 |	10 |
| 5 |	1 |	10 |
| 7 |	1 |	10 |
| 8 |	1 |	20 |
| 10 |	2 |	15 |
| 3 |	2 |	21 |
| 4 |	3 |	29 |

***
### Q4. What was the average distance travelled for each customer?

#### Explanation:
Similar to question 2's query, I used a subquery here to ensure that orders with multiple pizzas weren't double counted in teh averages - the result of the subquery gives the distance traveled for each order. Those distances are then grouped by customer and averaged for the output.

From the results, we can see that customer 105 has the runners going the furthest distance on average, 25 kilometers. Customer 104 has the runners traveling the least distance per order, with an average of only 10 kilometers. In the middle are customers 101, 102, and 103, with 20, 18.4, and 23.4 kilometers travelled on average to deliver their orders. 


#### SQL:
    select customer_id, avg(distance) as distance
    from 
    (
    select distinct customer_id, cco.order_id, distance 
    from cleaned_runner_orders cro
    	join cleaned_customer_orders cco on cro.order_id = cco.order_id
    ) as orderDistances
    group by customer_id;
    
#### Results:
| customer_id | distance |
|-------- | -------- |
| 101 |	20 |
| 102 |	18.4 |
| 103 |	23.4 |
| 104 |	10 |
| 105 |	25 |

***
### Q5. What was the difference between the longest and shortest delivery times for all orders?

#### Explanation:
This question was fairly straightforward to answer - I simply found the difference between the min and max durations of the deliveries.

The shortest delivery took 10 minutes and the longest 40 - leaving a 30 minutes difference between the longest and shortest delivery times for all orders. 

#### SQL:
    select max(duration) - min(duration) as timeDifference
    from cleaned_runner_orders;

#### Results:
| timeDifference |
| -------- |
| 30 |

***
### Q6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

#### Explanation: 
To answer this question, I crafted a few different queries to look at how order duration, order distance, number of pizzas in an order, runner assigned, and the runners' experience corrolated with the speeds at which the orders were delivered. From the first query, we can see that runner 1 is the most experienced, with runner 2 following closely behind, with 4 and 3 orders delivered, respectively. The second query tells us that runner 2 has the best speed with their deliveries with 1.12 km/min, then runner 1 with 1.36km/min, then runner 3 with 1.5km/min. From both of those queries, we see that runner 3 has the least experience and the slowest speed - but the order of runners 1 and 2 changes between experience and speed. In the third query, I explored the average distance and duration for each runner. Here, runner 3 has the shortest of both values, then runner 1, then runner 2. This order matches the order found in the runners' speed - and suggests a correlation between orders with longer distances and durations and orders delivered at quicker speeds. The final query compiles all of these attributes - for each order, we have the runner id, number of pizzas, distance, duration, and speed. Interesting enough, this last table reveals that the orders with the highest and lowest speed were both delivered by runner 2. Here, we can also observe that the orders delivered with the quickest speed are not the same orders with the highest combined distance and duration, so the correlation of runner 2 having the lowest speed and the highest avergae distance and duration seems not to be one of causation. The number of pizzas in an order also does not appear to have a strong correlation with the delivery speed of an order - the quickest delivery is of one pizza, and the slowest is for three, but the other data isn't as nicely related.

#### SQL:
    select runner_id, count(order_id) as ordersDelivered
    from cleaned_runner_orders
    where cancellation is null
    group by runner_id;

    select runner_id, round(avg(duration/distance), 2) as avgSpeed
    from cleaned_runner_orders
    where cancellation is null
    group by runner_id;

    select runner_id, round(avg(duration),2) as avgDuration, round(avg(distance),2) as avgDistance
    from cleaned_runner_orders
    where cancellation is null
    group by runner_id;
    
    select runner_id, cro.order_id, distance, duration, count(id) as numPizzas, round(duration/distance, 2) as speed
    from cleaned_runner_orders cro
      join cleaned_customer_orders cco on cro.order_id = cco.order_id
    where cancellation is null
    group by runner_id, cro.order_id, distance, duration
    order by runner_id;

#### Results:
| runner_id | ordersDelivered |
| -------- | -------- |
| 1 |	4 |
| 2 |	3 |
| 3 |	1 |

| runner_id | avgSpeed |
| -------- | -------- |
| 1 |	1.36 |
| 2 |	1.12 |
| 3 |	1.5 |

| runner_id | avgDuration | avgDistance |
| -------- | -------- | -------- |
| 1 |	22.25 |	15.85 |
| 2 |	26.67 |	23.93 |
| 3 |	15 |	10 |

| runner_id | order_id | numPizzas | distance | duration | speed |
| -------- | -------- | -------- | -------- | -------- | -------- |
| 1 |	1 |	1 |	20 |	32 |	1.6 |
| 1 |	2 |	1 |	20 |	27 |	1.35 |
| 1 |	3 |	2 |	13.4 |	20 |	1.49 |
| 1 |	10 |	2 |	10 |	10 |	1 |
| 2 |	4 |	3 |	23.4 |	40 |	1.71 |
| 2 |	7 |	1 |	25 |	25 |	1 |
| 2 |	8 |	1 |	23.4 | 	15 |	0.64 |
| 3 |	5 |	1 |	10 |	15 |	1.5 |


***
### Q7. What is the successful delivery percentage for each runner?

#### Explanation:
To calculate the percentage of successful deliveries for each runner, I used a combination of sum and case to count successful deliveries for each runner, then divided that by the total orders delivered by that runner and multiplied the result by 100. The sum/case portion works by going through each order and incrementing the total by 1 if the cancellation field is empty/null. The success percentages are then output along with the runner ids they relate to. 

From this query, we can see that runner 1 has had a 100% success rate on deliveries, runner 2 has been slightly less successful with a rate of 75%, and runner 3 brings up the rear with just 50% of deliveries being successful. 

#### SQL:
    select runner_id, round(100 * sum(case when cancellation is null then 1 else 0 end) / count(order_id), 0) as deliveryPercentage
    from cleaned_runner_orders
    group by runner_id;

#### Results:
| runner_id | deliveryPercentage |
| -------- | -------- |
| 1 |	100 |
| 2 |	75 |
| 3 |	50 |
