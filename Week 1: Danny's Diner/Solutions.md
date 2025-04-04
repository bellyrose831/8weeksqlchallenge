# Case Study Questions & Solutions

### Q1. What is the total amount each customer spent at the restaurant?

#### Explanation: 
To answer this question, I used a fairly straightforward query to get the customer ids and used the aggregate function SUM to total the price of the purchased items, grouping the totals by customer id to get separate totals and resulting rows for each customer. As the customer ids and their orders are in the sales table and the price attribute is in the menu table, I need to join those two tables, so I used an inner join on the product id to access all the necessary data.

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
Similarly to the last query, this query hinges on grouping by customer id and an aggregate query, though this time I'm using COUNT as oppsed to SUM, since I want to total the number of rows, rather than the value of the rows. Also similarly to the last query, the resulting columns are aliased to create a more clean, easy-to-read output. 

#### SQL:

    select customer_id as Customer, count(distinct order_date) as Visits <br>
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

***
### Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?

#### SQL:

    select product_name as Item, count(product_name) as Purchases
    from sales
    	join menu on sales.product_id = menu.product_id
    group by product_name
    order by Purchases desc
    limit 1;

***
### Q5. Which item was the most popular for each customer?

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

***
### Q6. Which item was purchased first by the customer after they became a member?

#### SQL:

    with ordersBeforeJoining as (
    	select sales.customer_id, order_date, product_id, rank() over (partition by sales.customer_id order by order_date) as rn
    	from sales
    		join members on sales.customer_id = members.customer_id
    	where join_date >= order_date
    	order by sales.customer_id, order_date
    )
    select customer_id as Customer, group_concat(product_name separator ', ') as Item
    from ordersBeforeJoining orders
    	join menu on menu.product_id = orders.product_id
    where rn = 1
    group by customer_id
    order by customer_id;

***
### Q7. Which item was purchased just before the customer became a member?

#### SQL:

    with ordersAfterJoining as (
    	select sales.customer_id, order_date, product_id, rank() over (partition by sales.customer_id order by order_date) as rn
    	from sales
    		join members on sales.customer_id = members.customer_id
    	where join_date < order_date
    	order by sales.customer_id, order_date
    )
    select customer_id as Customer, group_concat(product_name separator ', ') as Item
    from ordersAfterJoining orders
    	join menu on menu.product_id = orders.product_id
    where rn = 1
    group by customer_id
    order by customer_id;
***
### Q8. What is the total items and amount spent for each member before they became a member?

#### SQL:

    select sales.customer_id, count(sales.product_id) as totalItems, sum(price) as totalSpent
    from sales
    	join members on members.customer_id = sales.customer_id
    	join menu on menu.product_id = sales.product_id
    where order_date < join_date
    group by sales.customer_id
    order by sales.customer_id;

***
### Q9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

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

***
### Q10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

#### SQL:

    with itemCount as (
    	select customer_id, product_name, price, order_date, count(*) as numItems
    	from sales
    		join menu on menu.product_id = sales.product_id
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
    group by customer_id;
