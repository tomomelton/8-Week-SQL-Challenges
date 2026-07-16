# Case Study #2 | Pizza Runner
## B. Runner and Customer Experience

### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
``` SQL
SELECT date_trunc('week', registration_date) AS week, COUNT(runner_id) AS runners
FROM runners
GROUP BY week
ORDER BY week;
```
|    week    | runners |
|:----------:|:-------:|
| 2020-12-28 | 2       |
| 2021-01-04 | 1       |
| 2021-01-11 | 1       |

---

### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pick up the order?
``` SQL
SELECT DISTINCT 
	runner_id,
	AVG(EXTRACT(MINUTE FROM pickup_time::timestamp - order_time))::NUMERIC(10, 2) AS average_minutes_to_collect
FROM customer_orders
JOIN runner_orders ON customer_orders.order_id = runner_orders.order_id
AND cancellation IS NULL
GROUP BY runner_id
ORDER BY runner_id;
```
| runner_id | average_minutes_to_collect |
|:---------:|:--------------------------:|
| 1         | 15.33                      |
| 2         | 23.40                      |
| 3         | 10.00                      |

---

### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

Assuming pickup_time represents the time it takes to prepare an order:
``` SQL
SELECT  
	customer_orders.order_id, 
	COUNT(pizza_id) AS pizzas_ordered, 
	EXTRACT(MINUTE FROM pickup_time::timestamp - order_time) AS minutes_to_prepare
FROM customer_orders
JOIN runner_orders ON customer_orders.order_id = runner_orders.order_id
AND cancellation IS NULL
GROUP BY customer_orders.order_id, minutes_to_prepare
ORDER BY pizzas_ordered, minutes_to_prepare;
```
| order_id | pizzas_ordered |	minutes_to_prepare |
|:--------:|:--------------:|:------------------:|
| 1        | 1	            | 10                 |
| 2        | 1	            | 10                 |
| 5        | 1	            | 10                 |
| 7        | 1	            | 10                 |
| 8        | 1	            | 20                 |
| 10       | 2	            | 15                 |
| 3        | 2	            | 21                 |
| 4        | 3	            | 29                 |

There appears to be a relationship: larger orders generally take longer to prepare and therefore take longer to be picked up

---

### 4. What was the average distance travelled for each customer?
``` SQL
SELECT DISTINCT 
	customer_id, 
	AVG(regexp_replace(distance, '[^0-9.]', '', 'g')::numeric)::numeric(10, 2) AS average_distance
FROM customer_orders
JOIN runner_orders ON customer_orders.order_id = runner_orders.order_id
AND cancellation IS NULL
GROUP BY customer_id
ORDER BY customer_id;
```
| customer_id | average_distance |
|:-----------:|:----------------:|
| 101         | 20.00            |
| 102         | 16.73            |
| 103         | 23.40            |
| 104         | 10.00            |
| 105         | 25.00            |

---

### 5. What was the difference between the longest and shortest delivery times for all orders?
``` SQL
WITH
a AS (
	SELECT order_id, regexp_replace(duration, '\D', '', 'g')::numeric AS duration
	FROM runner_orders
	WHERE cancellation IS NULL
)
SELECT MAX(duration) - MIN(duration) AS difference
FROM a;
```
| difference |
|:----------:|
| 30         |

---

### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

Average speed = distance / duration
``` SQL
WITH
a AS (
SELECT 
	order_id, 
	runner_id,
	regexp_replace(distance, '[^0-9.]', '', 'g')::numeric AS distance_km,
	regexp_replace(duration, '\D', '', 'g')::numeric / 60 AS duration_hr
FROM runner_orders
WHERE cancellation IS NULL
ORDER BY order_id
)
SELECT 
	order_id,
	runner_id,
	distance_km,
	duration_hr::numeric(10,2),
	(distance_km / duration_hr)::numeric(10,2) AS average_speed_km_per_hr
FROM a
ORDER BY average_speed_km_per_hr;
```
| order_id | runner_id | distance_km | duration_hr | average_speed_km_per_hr |
|:--------:|:---------:|:-----------:|:-----------:|:-----------------------:|
| 4	       | 2	       |23.4	       | 0.67	       | 35.10                   |
| 1	       | 1	       |20	         | 0.53	       | 37.50                   |
| 5	       | 3	       |10	         | 0.25	       | 40.00                   |
| 3	       | 1	       |13.4	       | 0.33	       | 40.20                   |
| 2	       | 1	       |20	         | 0.45	       | 44.44                   |
| 7	       | 2	       |25	         | 0.42	       | 60.00                   |
| 10	     | 1	       |10	         | 0.17	       | 60.00                   |
| 8	       | 2	       |23.4	       | 0.25	       | 93.60                   |

---

### 7. What is the successful delivery percentage for each runner?

Successful delivery percentage = successful deliveries ÷ total orders × 100
``` SQL
WITH
a AS (
	SELECT 
		c.runner_id,
		COUNT(order_id)::numeric AS success
	FROM runner_orders AS r 
	RIGHT JOIN (SELECT DISTINCT runner_id FROM runner_orders) AS c 
		ON r.runner_id = c.runner_id
	AND cancellation IS NULL
	GROUP BY c.runner_id
),
b AS (
	SELECT
		runner_id,
		COUNT(order_id)::numeric AS total
	FROM runner_orders
	GROUP BY runner_id
)
SELECT 
	a.runner_id,
	(success / total * 100)::numeric(10,2) AS successful_delivery_percentage
FROM a
JOIN b ON a.runner_id = b.runner_id;
```
| runner_id   | successful_delivery_percentage |
|:-----------:|:------------------------------:|
| 3           | 50.00                          |
| 2           | 75.00                          |
| 1           | 100.00                         |
