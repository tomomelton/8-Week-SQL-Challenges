# Case Study #2 | Pizza Runner
## D. Pricing and Ratings

### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
``` SQL
WITH
-- Pair each delivered pizza with its price
a AS (
	SELECT 
		co.order_id,
		co.pizza_id,
		CASE
			WHEN pizza_id::int = 2 THEN 10
			ELSE 12
		END AS price
	FROM runner_orders AS ro
	JOIN customer_orders AS co
	ON ro.order_id = co.order_id

	WHERE cancellation IS NULL
)
SELECT 
	SUM(price) AS revenue_dollars
FROM a;
```
| revenue_dollars |
|:---------------:|
| 138             |

---

### 2. What if there was an additional $1 charge for any pizza extras?
  - Add cheese is $1 extra
``` SQL
WITH
-- Pair each delivered pizza with its price and unnest extras
a AS (
	SELECT 
		co.order_id,
		co.pizza_id,
		UNNEST(COALESCE(string_to_array(co.extras, ', '), ARRAY['0'])) AS extras,
		CASE
			WHEN pizza_id::int = 2 THEN 10
			ELSE 12
		END AS price
	FROM runner_orders AS ro
	JOIN customer_orders AS co
	ON ro.order_id = co.order_id

	WHERE cancellation IS NULL
),
-- Add $1 to price when there is an extra
b AS (
	SELECT 
		order_id,
		pizza_id,
		COALESCE(
			CASE
				WHEN extras::int > 0
				THEN price + 1
			END,
			price
		) AS price
	FROM a
)
SELECT 
	SUM(price) AS revenue_dollars
FROM b;
```
| revenue_dollars |
|:---------------:|
| 154             |

---

### 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
``` SQL
DROP TABLE IF EXISTS runner_ratings;
CREATE TABLE runner_ratings (
  	"order_id" INTEGER,
  	"runner_id" INTEGER,
  	"rating" INTEGER
  	CHECK (rating >= 1 AND rating <= 5)
);


INSERT INTO runner_ratings
	(order_id, runner_id, rating)
VALUES
	(1, 1, 3),
	(2, 1, 4),
	(3, 1, 4),
	(4, 2, 2),
	(5, 3, 4),
	(7, 2, 5),
	(8, 2, 5),
	(10, 1, 5);


SELECT * FROM runner_ratings;
```
| order_id | runner_id | rating |
|:--------:|:---------:|:------:|
| 1	       | 1	       | 3      |
| 2	       | 1	       | 4      |
| 3	       | 1	       | 4      |
| 4	       | 2	       | 2      |
| 5	       | 3	       | 4      |
| 7	       | 2	       | 5      |
| 8	       | 2	       | 5      |
| 10	     | 1	       | 5      |

---

### 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
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
``` SQL
SELECT 
	co.customer_id,
	ro.order_id,
	ro.runner_id,
	rr.rating,
	co.order_time,
	ro.pickup_time,
	
	TO_TIMESTAMP(
		ro.pickup_time,
		'YYYY-MM-DD HH24:MI:SS'
	) 
	- co.order_time
	AS time_between_order_and_pickup,
	
	ro.duration,
	
	ROUND(
		REGEXP_REPLACE(ro.distance, '[[:alpha:]]', '', 'g')::numeric
			/
		REGEXP_REPLACE(ro.duration, '[[:alpha:]]', '', 'g')::numeric * 60,
		2
	) AS average_speed_km_per_h,

	COUNT(co.pizza_id) AS number_of_pizzas
	
FROM runner_orders AS ro

JOIN runner_ratings AS rr
ON ro.order_id = rr.order_id

JOIN customer_orders AS co
ON ro.order_id = co.order_id

GROUP BY
	co.customer_id,
	ro.order_id,
	ro.runner_id,
	rr.rating,
	co.order_time,
	ro.pickup_time,
	time_between_order_and_pickup,
	ro.duration,
	average_speed_km_per_h;
```
| customer_id | order_id | runner_id | rating |     order_time      |     pickup_time     | time_between_order_and_pickup |  duration   | average_speed_km_per_h | number_of_pizzas |
|:-----------:|:--------:|:---------:|:------:|:-------------------:|:-------------------:|:-----------------------------:|:-----------:|:----------------------:|:----------------:|
| 101         | 1        | 1         | 3      | 2020-01-01 18:05:02 | 2020-01-01 18:15:34 | 00:10:32                      | 32 minutes  | 37.50                  | 1                |
| 101         | 2        | 1         | 4      | 2020-01-01 19:00:52 | 2020-01-01 19:10:54 | 00:10:02                      | 27 minutes  | 44.44                  | 1                |
| 102         | 3        | 1         | 4      | 2020-01-02 23:51:23 | 2020-01-03 00:12:37 | 00:21:14                      | 20 mins     | 40.20                  | 2                |
| 102         | 8        | 2         | 5      | 2020-01-09 23:54:33 | 2020-01-10 00:15:02 | 00:20:29                      | 15 minute   | 93.60                  | 1                |
| 103         | 4        | 2         | 2      | 2020-01-04 13:23:46 | 2020-01-04 13:53:03 | 00:29:17                      | 40          | 35.10                  | 3                |
| 104         | 5        | 3         | 4      | 2020-01-08 21:00:29 | 2020-01-08 21:10:57 | 00:10:28                      | 15          | 40.00                  | 1                |
| 104         | 10       | 1         | 5      | 2020-01-11 18:34:49 | 2020-01-11 18:50:20 | 00:15:31                      | 10minutes   | 60.00                  | 2                |
| 105         | 7        | 2         | 5      | 2020-01-08 21:20:29 | 2020-01-08 21:30:45 | 00:10:16                      | 25mins      | 60.00                  | 1                |

---

### 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
``` SQL
WITH
-- Pair each delivered pizza with its price
-- and calculate the runners fee for each delivery
a AS (
	SELECT 
		co.order_id,
		co.pizza_id,
		ROUND(
			REGEXP_REPLACE(ro.distance, '[[:alpha:]]', '', 'g')::numeric
		) 
		* 0.3 --$0.30
		AS runner_fee,
		CASE
			WHEN pizza_id::int = 2 THEN 10
			ELSE 12
		END AS price
	FROM runner_orders AS ro
	
	JOIN customer_orders AS co
	ON ro.order_id = co.order_id

	WHERE cancellation IS NULL
)
SELECT 
	SUM(price)
	-
	SUM(runner_fee)
	AS revenue_dollars
FROM a;
```
| revenue_dollars |
|:---------------:|
| 74.1            |














