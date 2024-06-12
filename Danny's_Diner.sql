CREATE DATABASE dannys_diner;
USE dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  

-- 1.What is the total amount each customer spent at the restaurant?

SELECT s.customer_id,
CONCAT("$",SUM(m.price)) AS total_amount_Spent
FROM sales s 
JOIN menu m 
ON s.product_id=m.product_id
GROUP BY 1
ORDER BY 1;


-- 2.How many days has each customer visited the restaurant? 

SELECT customer_id,
COUNT(DISTINCT order_date) AS num_days_visited
FROM sales
GROUP BY 1
ORDER BY 1;


-- 3.What was the first item from the menu purchased by each customer?

SELECT customer_id,
First_Item_Purchased
FROM (
	SELECT s.customer_id,
	m.product_name AS First_Item_Purchased,
    ROW_NUMBER() OVER(PARTITION BY s.customer_id) rn
    FROM sales s 
    JOIN menu m 
	ON s.product_id=m.product_id
) t
WHERE t.rn=1;


-- 4.What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT m.product_name,
COUNT(s.product_id) AS order_items
FROM menu m
JOIN sales s 
ON m.product_id=s.product_id
GROUP BY 1
ORDER BY 2 DESC 
LIMIT 1;


-- 5.Which item was the most popular for each customer?

WITH CTE AS(
SELECT s.customer_id,
m.product_name AS popular_item,
COUNT(*) as ordered_count,
DENSE_RANK() OVER( PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) drk 
FROM sales s
JOIN menu m 
ON s.product_id=m.product_id
GROUP BY 1,2)

SELECT customer_id,
popular_item,
ordered_count 
FROM CTE
WHERE drk=1;


-- 6.Which item was purchased first by the customer after they became a member?

WITH CTE AS(
SELECT s.customer_id,
m.product_name,
RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) rk
FROM sales s
JOIN menu m
ON s.product_id=m.product_id
JOIn members mb
ON s.customer_id=mb.customer_id AND mb.join_date <= s.order_date)

SELECT customer_id,
product_name 
FROM CTE
WHERE rk=1;


-- 7.Which item was purchased just before the customer became a member?

WITH CTE AS(
SELECT s.customer_id,
m.product_name,
RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) rk
FROM sales s
JOIN menu m
ON s.product_id=m.product_id
JOIn members mb
ON s.customer_id=mb.customer_id AND mb.join_date > s.order_date)

SELECT customer_id,
product_name 
FROM CTE
WHERE rk=1;


-- 8.What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id,
COUNT(m.product_name) AS total_items,
CONCAT('$',SUM(m.price)) AS amount_spent
FROM sales s
JOIN menu m
ON s.product_id=m.product_id
JOIn members mb
ON s.customer_id=mb.customer_id AND mb.join_date > s.order_date
GROUP BY 1;


-- 9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT s.customer_id,
       SUM(IF(m.product_name = "sushi", 20 * m.price, m.price * 10)) AS total_points
FROM sales AS s
JOIN menu AS m 
ON s.product_id = m.product_id
GROUP BY 1;


-- 10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT s.customer_id,
SUM(CASE
	WHEN s.order_date BETWEEN mb.join_date AND DATE_ADD(mb.join_date, INTERVAL 6 DAY)
	THEN 20*m.price
	WHEN m.product_name="sushi" THEN  20*m.price
	ELSE m.price*10 END) AS total_points 
FROM sales s 
JOIN menu m
ON s.product_id=m.product_id
JOIN members as mb
ON mb.customer_id=s.customer_id
WHERE s.order_date<="2021-01-31" AND s.order_date >=mb.join_date
GROUP BY 1;


-- Creating the Bonus Table

CREATE TABLE IF NOT EXISTS customer_order
SELECT s.customer_id, 
s.order_date,
m.product_name,
m.price,
CASE 
	WHEN mb.join_date IS NULL THEN 'N'
	WHEN s.order_date < mb.join_date THEN 'N'
	ELSE 'Y'
	END AS "member"
FROM sales s
JOIN menu m 
ON s.product_id = m.product_id
LEFT JOIN members mb 
ON s.customer_id = mb.customer_id
ORDER BY 1,2;

SELECT * FROM customer_order;


-- Bonus Solution

SELECT * ,
CASE 
	WHEN member="N" THEN NULL 
	ELSE DENSE_RANK() OVER(PARTITION BY customer_id,member ORDER BY order_date) END AS ranking
FROM customer_order;
