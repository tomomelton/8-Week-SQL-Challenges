# Case Study #1 | Danny's Diner

<img src="https://8weeksqlchallenge.com/images/case-study-designs/1.png" width=500 alt="Danny's Diner Logo">

## Table of Contents

- [Problem Statement](#Problem-Statement)
- [Case Study Questions](#Case-Study-Questions)
- [Links](#Links)

## Problem Statement

## Case Study Questions
### 1. What is the total amount each customer spent at the resturant?

```SQL
SELECT customer_id, SUM(price) AS total_spent
FROM menu, sales
WHERE sales.product_id = menu.product_id
GROUP BY customer_id
ORDER BY customer_id;
```
| customer_id  | total_spent |
| :----------: |:-----------:|
| A            | 76          |
| B            | 74          |
| C            | 36          |

>#### Steps:
>- **Linked menu and sales together via a common product id**
>- **Used SUM to calcualte the total amount spent by each customer**
>- **Group the results by customer id**
## Links
