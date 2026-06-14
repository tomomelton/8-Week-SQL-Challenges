SET SEARCH_PATH TO dannys_diner;

-- 1. What is the total amount each customer spent at the resturant?

SELECT customer_id, SUM(price)
FROM menu, sales
WHERE sales.product_id = menu.product_id
GROUP BY customer_id
ORDER BY customer_id;


-- 2. How many days has each customer visited the resturant?

SELECT customer_id, COUNT(DISTINCT order_date)
FROM sales
GROUP BY customer_id
ORDER BY customer_id;


-- 3. What was the first item from the menu purchased by each customer?

-- DISTINCT ON limits only one item per customer id
SELECT DISTINCT ON (a.customer_id) a.customer_id, product_name
FROM sales, menu, (
	-- Select smallest order date for each customer
	SELECT customer_id, MIN(order_date) AS min_date
	FROM sales
	GROUP BY customer_id
)	AS a
WHERE sales.customer_id = a.customer_id
AND sales.product_id = menu.product_id
AND sales.order_date = a.min_date
ORDER BY customer_id, product_name;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT customer_id, menu.product_name, COUNT(sales.product_id) AS times_ordered
FROM sales, menu, (
	-- Return most ordered item and its number of orders
	SELECT product_id, COUNT(product_id) AS times_ordered
	FROM sales
	GROUP BY product_id
	ORDER BY times_ordered DESC
	LIMIT 1 
)	AS a
WHERE sales.product_id = a.product_id
AND sales.product_id = menu.product_id
GROUP BY customer_id, menu.product_name
ORDER BY customer_id;


-- 5. Which item was the most popular for each customer?

SELECT DISTINCT ON (customer_id) customer_id, product_name, MAX(times_ordered) AS biggest_order
FROM menu, (
	-- Number of times each customer has ordered an item
	SELECT customer_id, product_id, COUNT(product_id) AS times_ordered
	FROM sales
	GROUP BY customer_id, product_id
	ORDER BY times_ordered
)	AS a
WHERE menu.product_id = a.product_id
GROUP BY customer_id, product_name
ORDER BY customer_id, biggest_order DESC;


-- 6. Which item was purchased first by the customer after they became a member?

SELECT DISTINCT ON (members.customer_id) members.customer_id, product_name
FROM members
JOIN sales ON members.customer_id = sales.customer_id
JOIN menu ON sales.product_id = menu.product_id
WHERE order_date >= join_date
ORDER BY customer_id, order_date;


-- 7. Which item was purchased just before the customer became a member?

SELECT DISTINCT ON (members.customer_id) members.customer_id, product_name
FROM members
JOIN sales ON members.customer_id = sales.customer_id
JOIN menu ON sales.product_id = menu.product_id
WHERE order_date < join_date
ORDER BY customer_id, order_date DESC;


-- 8. What is the total items and amount spent for each member before they became a member?

SELECT members.customer_id, SUM(price) AS amount_spent
FROM members
JOIN sales ON members.customer_id = sales.customer_id
JOIN menu ON sales.product_id = sales.product_id
WHERE order_date < join_date
GROUP BY members.customer_id;


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT customer_id, SUM(score) AS score
FROM (
	-- Select sushi score
	SELECT customer_id, price * 10 * 2 AS score
	FROM sales
	JOIN menu ON menu.product_id = sales.product_id
	AND product_name = 'sushi'
	
	UNION ALL
	
	-- Select not sushi score
	SELECT customer_id, price * 10 AS score
	FROM sales
	JOIN menu ON menu.product_id = sales.product_id
	AND product_name != 'sushi'
) AS a
GROUP BY customer_id
ORDER BY customer_id;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?

SELECT customer_id, SUM(score) AS score
FROM (

	-- Select scores within 1st week
	SELECT members.customer_id, product_name, order_date, price * 10 * 2 AS score
	FROM members
	JOIN sales ON members.customer_id = sales.customer_id
	JOIN menu ON sales.product_id = menu.product_id
	AND order_date BETWEEN join_date AND join_date + 7
	
	-- Select sales excluding 1st week
	
	UNION ALL
	
	-- Select sushi scores
	SELECT members.customer_id, product_name, order_date, price * 10 * 2 AS score
	FROM members
	JOIN sales ON members.customer_id = sales.customer_id
	JOIN menu ON sales.product_id = menu.product_id
	AND order_date NOT BETWEEN join_date AND join_date + 7
	AND product_name = 'sushi'
	
	UNION ALL
	
	-- Select non-sushi scores
	SELECT members.customer_id, product_name, order_date, price * 10 AS score
	FROM members
	JOIN sales ON members.customer_id = sales.customer_id
	JOIN menu ON sales.product_id = menu.product_id
	AND order_date NOT BETWEEN join_date AND join_date + 7 
	AND product_name != 'sushi'

	ORDER BY customer_id, order_date
) AS a
WHERE order_date < '2021-02-01'
GROUP BY customer_id
ORDER BY customer_id;

