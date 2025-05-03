# Case Study Questions & Solutions

### Q1. What is the total amount each customer spent at the restaurant?

#### Explanation: 
To answer this question, I used a fairly straightforward query to get the customer ids and used the aggregate function SUM to total the price of the purchased items, grouping the totals by customer id to get separate totals and resulting rows for each customer. As the customer ids and their orders are in the sales table and the price attribute is in the menu table, I need to join those two tables, so I used an inner join on the product id to access all the necessary data.  

This revealed that the customer A had greatest total spending, at $76, with customer B following closely at $74, and customer C leaving a wide margin from them both with only $36 spent. 

#### SQL:

    select customer_id as Customer, sum(price) as TotalSpent
    from sales
      join menu on sales.product_id = menu.product_id
    group by sales.customer_id;

#### Results:
| Customer | TotalSpent |
| -------- | ------- |
| A | 76 |
| B | 74 |
| C | 36 |

***
### Q2. How many days has each customer visited the restaurant?

#### Explanation: 
Similarly to the last query, this query hinges on grouping by customer id and an aggregate function, though this time I used COUNT as oppsed to SUM, since I wanted to total the number of rows, rather than the value of the rows. Also similarly to the last query, the resulting columns are aliased to create a more clean, easy-to-read output.  

This query showed that customer B has visited the restaurant the most, with customers A and C following, in that order. 

#### SQL:

    select customer_id as Customer, count(distinct order_date) as Visits 
    from sales <br>
    group by customer_id;

#### Results:
| Customer | Visits |
| -------- | ------- |
| A | 4 |
| B | 6 |
| C | 2 |

***
### Q3. What was the first item from the menu purchased by each customer?

#### Explanation: 
Here, I utilized a subquery to get the date of the each customer's first order, which I then used to get all sales made on those dates to those customers, respectively. The query could also be rewritten to use a CTE rather than a subquery - in this case, I weighed the run times (with the relatively small table sizes, there isn't a significant difference there) and the readability (I found the subquery stronger in this respect), and decided to use a subquery. Finally, to format the output in just one row per customer without losing any data, I used the group_concat function to format the items purchased as a comma-separated list if a customer had more than one.  

From this query, we can see that customer A purchased two items on their first visit: curry and sushi. Customers B and C each purchased one item on their first visits, curry and ramen, respectively. 

#### SQL:

    select sales.customer_id as Customer, group_concat(distinct product_name separator ', ') as FirstPurchase
    from (
    	select sales.customer_id, min(order_date) as minDate
    	from sales
    	group by sales.customer_id
    ) as firstDates
    	join sales on (sales.customer_id = firstDates.customer_id and order_date = minDate) 
    	join menu on sales.product_id = menu.product_id
    group by sales.customer_id;

#### Results:
| Customer | FirstPurchase |
| -------- | ------- |
| A | curry, sushi |
| B | curry |
| C | ramen |

***
### Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?

#### Explanation: 
This question was able to be answered with a fairly straightforward query. Once I'd retrieved the necessary data, I sorted on the number of purchases and limited the output to just the top row - giving me the item with the most purchases.  

With this, we've found that ramen is the most purchased item at Danny's Diner, having been purchased 8 times. 

#### SQL:

    select product_name as Item, count(product_name) as Purchases
    from sales
    	join menu on sales.product_id = menu.product_id
    group by product_name
    order by Purchases desc
    limit 1;

#### Results:
| Item | Purchases |
| -------- | ------- |
| ramen | 8 |

***
### Q5. Which item was the most popular for each customer?

#### Explanation: 
For this query, I utilized a CTE to get the number of times each customer had purchased each item. From that information, I used rank() to find which items had been purchased the most for each customer. Rank is useful here, as it allows for multiple items to have the same rank if they have been purchased the same amount of times - where using limit doesn't allow for such nuance. Once ranks have been assigned by customer and product, the customer names are output along with a list of products with rank 1 (most purchases) for that customer.  

The results of this query were pretty interesting - customers A and C both seemed to favorite ramen, whereas customer B had no clear preference, having purchased each of the three items twice. 

#### SQL:

    with itemCount as (
    	select customer_id, product_id, rank() over (partition by customer_id order by count(*) desc) as rn
    	from sales
    	group by customer_id, product_id
    	order by customer_id
    )
    select ic.customer_id as Customer, group_concat(menu.product_name separator ', ') as FavItem
    from itemCount ic
        join menu on menu.product_id = ic.product_id
    where rn = 1
    group by ic.customer_id;

#### Results:
| Customer | FavItem |
| -------- | ------- |
| A | ramen |
| B | sushi, curry, ramen |
| C | ramen |

***
### Q6. Which item was purchased first by the customer after they became a member?

#### Explanation: 
For this question and the next, the timing of membership being established compared to items purchased is not defined - I've written these queries with the understanding that purchases that are made on the same day as membership is established are counted as occuring after the customer becomes a member (ie membership is established at the beginning of these transactions). In the case of the alternate scenario, the change to the queries is simple, but would slightly alter the results of both questions.  

In this query, I began by using a CTE to get all of the orders made by members made on or after the day they joined. I then ordered those results by customer and then by date, with the earliest-dated purchases receiving a rank of 1. Again here, rank allows for multiple products purchased on that earliest date to be included in the final result, as they will all have a rank of 1. The 1-ranked purchases for each customers are then output with the customer ids.  

This query shows that customer A first purchased curry after becoming a member and customer B first purchased sushi after becoming a member. 

#### SQL:

    with ordersAfterJoining as (
	select sales.customer_id, order_date, product_id, rank() over (partition by sales.customer_id order by order_date) as rn
	from sales
		join members on sales.customer_id = members.customer_id
	where join_date <= order_date
	order by sales.customer_id, order_date
    )
    select customer_id as Customer, group_concat(product_name separator ', ') as Item
    from ordersAfterJoining orders
    	join menu on menu.product_id = orders.product_id
    where rn = 1
    group by customer_id
    order by customer_id;

#### Results:
| Customer | Item |
| -------- | ------- |
| A | curry |
| B | sushi |

***
### Q7. Which item was purchased just before the customer became a member?

#### Explanation: 
The strategy to answer this question was similar but reciprocal to that used in the last question. I began by using a CTE to get all of the orders made by members made before the date they joined. I then ordered those results by customer and then by date, with the latest-dated purchases receiving a rank of 1. Again here, rank allows for multiple products purchased on that latest date to be included in the final result, as they will all have a rank of 1. The 1-ranked purchases for each customers are then output with the customer ids.   

This query shows that customer A purchased sushi and curry just before becoming a member and customer B purchased sushi just before becoming a member. 

#### SQL:

    with ordersBeforeJoining as (
	select sales.customer_id, order_date, product_id, rank() over (partition by sales.customer_id order by order_date desc) as rn
	from sales
		join members on sales.customer_id = members.customer_id
	where join_date > order_date
	order by sales.customer_id, order_date desc
    )
    select customer_id as Customer, group_concat(product_name separator ', ') as Item
    from ordersBeforeJoining orders
    	join menu on menu.product_id = orders.product_id
    where rn = 1
    group by customer_id
    order by customer_id;

#### Results:
| Customer | Item |
| -------- | ------- |
| A | sushi, curry |
| B | sushi |
    
***
### Q8. What is the total items and amount spent for each member before they became a member?

#### Explanation: 
This query is fairly basic, hinging on the aggregate functions count and sum to calculate the totals for the members.  

The results here show customer A purchasing 2 items totaling $25 before they became a member. Customer B bought three items totaling $40. Customer C is not represented here as they are not a member. 

#### SQL:

    select sales.customer_id as Customer, count(sales.product_id) as TotalItems, sum(price) as TotalSpent
    from sales
    	join members on members.customer_id = sales.customer_id
    	join menu on menu.product_id = sales.product_id
    where order_date < join_date
    group by sales.customer_id
    order by sales.customer_id;

#### Results:
| Customer | TotalItems | TotalSpent |
| -------- | ------- | ------ |
| A | 2 | 25 |
| B | 3 | 40 |

***
### Q9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

#### Explanation: 
This query utilized two CTEs to calculate each customers' number of purchases per item and each customers' points from each item. The second table utilized a case statement to differentiate between the points earned at the higher rate from sushi versus points earned from other items. Finally, the total points are calculated for each customer by finding the sum of the points from each item they purchased.   

With this points system, customer B would have the most points with 940, followed by A with 860, and C with 360. 

#### SQL:

    with itemCount as (
    	select customer_id, product_name, price, count(*) as numItems
    	from sales
    		join menu on menu.product_id = sales.product_id
    	group by customer_id, product_name, price
    ),
    totalPoints as (
    	select customer_id, product_name, price, numItems, 
    		case
    			when product_name = "sushi" then (numItems * price  * 20)
    			else (numItems * price  * 10)
    		end as numPoints
    	from itemCount
    )
    select customer_id as Customer, sum(numPoints) as Points
    from totalPoints
    group by customer_id;

#### Results:
| Customer | Points |
| -------- | ------- |
| A | 860 |
| B | 940 |
| C | 360 |

***
### Q10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

#### Explanation: 
The structure here is similar to that used in the last question, with the key differences being an additional case in the second CTE and a condition in the first CTE that limits results to products purchased before the end of January. Now, points are double if the item is sushi, points are doubled if the order date is within a week of the customer's join date, otherwise, points are issues at the regular rate - and in all cases, we are only seeing purchases made before 2/1. Finally, we sum the totals and look specifically at the point totals for customers A and B.

With this points system, customer A would have 1520 points and customer B would have 1240.


#### SQL:

    with itemCount as (
	select customer_id, product_name, price, order_date, count(*) as numItems
	from sales
		join menu on menu.product_id = sales.product_id
    where order_date < '2021-02-01'
	group by customer_id, product_name, price, order_date
    ),
    totalPoints as (
    	select ic.customer_id, product_name, price, numItems, order_date, join_date,
    		case
    			when product_name = "sushi" then (numItems * price  * 20)
    			when order_date <= (7 + join_date) then (numItems * price  * 20)
    			else (numItems * price  * 10)
    		end as numPoints
    	from itemCount ic
    		left join members on members.customer_id = ic.customer_id
    )
    select customer_id as Customer, sum(numPoints) as Points
    from totalPoints
    where customer_id = 'A' or customer_id = 'B'
    group by customer_id
    order by customer_id;

#### Results:
| Customer | Points |
| -------- | ------- |
| A | 1520 |
| B | 1240 |

***
# Bonus Questions

### Join All The Things

#### Explanation:
This goal of this exercise was to replicate a table provided in the case study with customer_id, order_date, product_name, price, and member fields, with member being a Y/N value based on the customer's membership status at the time of purchase. To build that table, I joined all three of the tables, and wrote a case statement to determine the member value for each purchase based on a comparison of the join date (if there was one) and order date. For customers with no join date (customer C), all purchases had an 'N' in the member column.

#### SQL: 
	select sales.customer_id, order_date, product_name, price,
	    case
		when join_date is not null and order_date >= join_date then 'Y'
	        else 'N'
	    end as member
	from sales
	    left join members on sales.customer_id = members.customer_id
	    left join menu on sales.product_id = menu.product_id
	order by customer_id, order_date, product_name;

 #### Results:
| customer_id | order_date | product_name | price | member |
| -------- | -------- | -------- | -------- | -------- |
| A | 2021-01-01 | curry | 15 | N |
| A | 2021-01-01 | sushi | 10 | N |
| A | 2021-01-07 | curry | 15 | Y |
| A | 2021-01-10 | ramen | 12 | Y |
| A | 2021-01-11 | ramen | 12 | Y |
| A | 2021-01-11 | ramen | 12 | Y |
| B | 2021-01-01 | curry | 15 | N |
| B | 2021-01-02 | curry | 15 | N |
| B | 2021-01-04 | sushi | 10 | N |
| B | 2021-01-11 | sushi | 10 | Y |
| B | 2021-01-16 | ramen | 12 | Y |
| B | 2021-02-01 | ramen | 12 | Y |
| C | 2021-01-01 | ramen | 12 | N |
| C | 2021-01-01 | ramen | 12 | N |
| C | 2021-01-07 | ramen | 12 | N |

***
### Rank All The Things

#### Explanation:
This goal of this exercise was to replicate a table provided in the case study with the same fields as in the last prompt, as well as a new "ranking" field consisting of a numerical value or a null value, determined by the customer id, membership status, and order date. For puchases with member = 'Y', the ranking counts up from 1, starting with the earliest purchase, with multiple purchases made on the same day receiving the same rank. For purchases with member = 'N', the ranking is null. To calculate this new ranking value for all purchases, I used a CTE looking only at purchases that should have non-null values, and used the rank() function, then joined this table to the one created for the last exercise in order to build the required table for this task.

#### SQL: 
	with rankedPurchases as 
	(
		select distinct sales.customer_id, order_date, 
  			rank () over (partition by sales.customer_id order by order_date) as rankVal
		from sales
			left join members on sales.customer_id = members.customer_id
			left join menu on sales.product_id = menu.product_id
		where join_date is not null and join_date <= order_date
		order by customer_id, order_date
	)
	select sales.customer_id, sales.order_date, product_name, case
	    when 
		join_date is not null and sales.order_date >= join_date then 'Y'
	        else 'N'
	    end as member, rankVal
	from sales
	    left join members on sales.customer_id = members.customer_id
	    left join menu on sales.product_id = menu.product_id
	    left join rankedPurchases rp on sales.customer_id = rp.customer_id and sales.order_date = rp.order_date
	order by customer_id, order_date, product_name;

 #### Results:
| customer_id | order_date | product_name | price | member | ranking |
| -------- | -------- | -------- | -------- | -------- | -------- |
| A | 2021-01-01 | curry | 15 | N | null |
| A | 2021-01-01 | sushi | 10 | N | null |
| A | 2021-01-07 | curry | 15 | Y | 1 |
| A | 2021-01-10 | ramen | 12 | Y | 2 |
| A | 2021-01-11 | ramen | 12 | Y | 3 |
| A | 2021-01-11 | ramen | 12 | Y | 3 |
| B | 2021-01-01 | curry | 15 | N | null |
| B | 2021-01-02 | curry | 15 | N | null |
| B | 2021-01-04 | sushi | 10 | N | null |
| B | 2021-01-11 | sushi | 10 | Y | 1 |
| B | 2021-01-16 | ramen | 12 | Y | 2 |
| B | 2021-02-01 | ramen | 12 | Y | 3 |
| C | 2021-01-01 | ramen | 12 | N | null |
| C | 2021-01-01 | ramen | 12 | N | null |
| C | 2021-01-07 | ramen | 12 | N | null |
