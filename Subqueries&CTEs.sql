
USE SampleRetail


--SUBQUERIES

--A subquery is a query nested inside another statement such as SELECT, INSERT, UPDATE or DELETE.
--A subquery must be enclosed in parentheses.
--The inner query can be run by itself.
--The subquery in a SELECT clause must return a single value.
--The subquery in a FROM clause must be used with an alias.
--An ORDER BY clause is not allowed to use in a subquery.
--(unless TOP, OFFSET or FOR XML is also specified)

--OFFSET & FETCH

SELECT product_id, SUM(list_price) total_price
FROM sale.order_item
WHERE quantity=1
GROUP BY product_id
ORDER BY total_price
OFFSET 1 ROWS;

SELECT product_id, SUM(list_price) total_price
FROM sale.order_item
WHERE quantity=1
GROUP BY product_id
ORDER BY total_price
OFFSET 1 ROWS
FETCH NEXT 5 ROWS ONLY;


-- Single-Row Subqueries

SELECT *, (SELECT MAX(list_price) FROM product.product) max_price
FROM product.product

--QUESTION: Write a query that shows all employees in the store where Davis Thomas works.

SELECT store_id
FROM sale.staff
WHERE first_name+last_name='DavisThomas'


SELECT *
FROM sale.staff
WHERE store_id=(SELECT store_id 
				FROM sale.staff
				WHERE first_name+last_name='DavisThomas');

--QUESTION: Write a query that shows the employees for whom Charles Cussona is a first-degree manager.
--(To which employees are Charles Cussona a first-degree manager?)

SELECT *
FROM sale.staff
WHERE manager_id=(
			SELECT staff_id
			FROM sale.staff
			WHERE first_name+last_name='CharlesCussona');


--QUESTION: Write a query that returns the list of products that are more expensive than the product
--named 'Pro-Series 49-Class Full HD Outdoor LED TV (Silver)'.(Also show model year and list price)

SELECT product_id, product_name, model_year, list_price
FROM product.product
WHERE list_price > (SELECT list_price
					FROM product.product
					WHERE product_name='Pro-Series 49-Class Full HD Outdoor LED TV (Silver)')


-- Multiple-Row Subqueries

--They are used with multiple-row operators such as IN, NOT IN, ANY, and ALL.

--QUESTION: Write a query that returns the first name, last name, and order date of customers 
--who ordered on the same dates as Laurel Goldammer.

SELECT first_name, last_name, o.order_date
FROM sale.customer c
	INNER JOIN sale.orders o ON c.customer_id=o.customer_id
WHERE order_date IN (
				SELECT order_date
				FROM sale.customer c
					INNER JOIN sale.orders o ON c.customer_id=o.customer_id
				WHERE first_name='Laurel' AND last_name='Goldammer');


--QUESTION: List the products that ordered in the last 10 orders in Buffalo city.

SELECT DISTINCT b.product_name
FROM sale.order_item a
	INNER JOIN product.product b ON a.product_id=b.product_id
WHERE a.order_id IN (
					SELECT TOP 10 order_id
					FROM sale.customer c
						INNER JOIN sale.orders o
						ON c.customer_id=o.customer_id
					WHERE city='Buffalo'
					ORDER BY order_id DESC);



-- Correlated Subqueries

--A correlated subquery is a subquery that uses the values of the outer query. In other words, the correlated subquery depends on the outer query for its values.
--Because of this dependency, a correlated subquery cannot be executed independently as a simple subquery.
--Correlated subqueries are used for row-by-row processing. Each subquery is executed once for every row
--of the outer query.
--A correlated subquery is also known as repeating subquery or synchronized subquery.

SELECT product_id,product_name,category_id,list_price,
	(SELECT AVG(list_price) FROM product.product) avg_price
FROM product.product;

SELECT category_id, AVG(list_price) avg_price
FROM product.product
GROUP BY category_id;


SELECT product_id,product_name,p.category_id,list_price, a.avg_price
FROM product.product p
	INNER JOIN (
		SELECT category_id, AVG(list_price) avg_price
		FROM product.product
		GROUP BY category_id
		) a 
		ON p.category_id = a.category_id
ORDER BY 1;


SELECT product_id, product_name, category_id, list_price,
	(SELECT AVG(list_price) FROM product.product WHERE category_id=p.category_id) avg_price
FROM product.product p
ORDER BY 1;


--EXISTS / NOT EXISTS

--QUESTION: Write a query that returns a list of States where 'Apple - Pre-Owned iPad 3 - 32GB - White'
--product is not ordered

SELECT state
FROM sale.customer c
	INNER JOIN sale.orders o ON c.customer_id=o.customer_id
	INNER JOIN  sale.order_item i ON i.order_id=o.order_id
	INNER JOIN product.product p ON p.product_id=i.product_id
WHERE product_name = 'Apple - Pre-Owned iPad 3 - 32GB - White'

--SOLUTION USING BY NOT IN
SELECT DISTINCT state
FROM sale.customer
WHERE state NOT IN(
		SELECT state
		FROM sale.customer c
			INNER JOIN sale.orders o ON c.customer_id=o.customer_id
			INNER JOIN  sale.order_item i ON i.order_id=o.order_id
			INNER JOIN product.product p ON p.product_id=i.product_id
		WHERE product_name = 'Apple - Pre-Owned iPad 3 - 32GB - White')

--SOLUTION USING BY NOT EXISTS
SELECT DISTINCT state
FROM sale.customer sc
WHERE NOT EXISTS 
	(
		SELECT state
		FROM sale.customer c
			INNER JOIN sale.orders o ON c.customer_id=o.customer_id
			INNER JOIN  sale.order_item i ON i.order_id=o.order_id
			INNER JOIN product.product p ON p.product_id=i.product_id
		WHERE product_name = 'Apple - Pre-Owned iPad 3 - 32GB - White'
		AND state=sc.state
	)


--QUESTION: Write a query that returns stock information of the products in Davi techno Retail store.
--The BFLO Store hasn't got any stock of that products.

--The BFLO Store's stock
SELECT a.store_id, a.store_name, b.product_id, b.quantity
FROM sale.store a, product.stock b
WHERE a.store_id=b.store_id
AND a.store_name = 'The BFLO Store'
AND b.quantity > 0


SELECT s.store_id, s.store_name, i.product_id, i.quantity
FROM sale.store s, product.stock i
WHERE s.store_id=i.store_id
AND s.store_name = 'Davi techno Retail'
AND NOT EXISTS (
				SELECT a.store_id, a.store_name, b.product_id, b.quantity
				FROM sale.store a, product.stock b
				WHERE a.store_id=b.store_id
				AND a.store_name = 'The BFLO Store'
				AND b.quantity > 0
				AND i.product_id=b.product_id)


SELECT s.store_id, s.store_name, i.product_id, i.quantity
FROM sale.store s, product.stock i
WHERE s.store_id=i.store_id
AND s.store_name = 'Davi techno Retail'
AND I.product_id NOT IN (
				SELECT b.product_id
				FROM sale.store a, product.stock b
				WHERE a.store_id=b.store_id
				AND a.store_name = 'The BFLO Store'
				AND b.quantity > 0)



--Subquery in SELECT Statement

--QUESTION: Write a query that creates a new column named "total_price" calculating 
--the total prices of the products on each order.

SELECT order_id, SUM(list_price) total_price
FROM sale.order_item
GROUP BY order_id;

SELECT order_id,
	(SELECT SUM(list_price)  FROM sale.order_item WHERE order_id=i.order_id) total_price
FROM sale.order_item i
GROUP BY order_id;


--QUESTION: List the products whose list price is higher than the average price of the products in the category.

SELECT p.product_id,p.product_name,p.list_price
FROM product.product p
WHERE list_price>(SELECT AVG(list_price) FROM product.product WHERE category_id=p.category_id) 


--CTE's (Common Table Expression)

--Common Table Expression exists for the duration of a single statement. That means 
--they are only usable inside of the query they belong to.
--It is also called "with statement".
--CTE is just syntax so in theory it is just a subquery. But it is more readable.
--An ORDER BY clause is not allowed to use in a subquery.
--(unless TOP, OFFSET or FOR XML is also specified)
--Each column must have a name.

WITH cte AS 
	(
		SELECT 1 AS n -- anchor member
        UNION ALL
        SELECT n + 1 -- recursive member
        FROM   cte
        WHERE  n < 10
	)
SELECT n
FROM cte;


--QUESTION: List customers who have an order prior to the last order date of a customer named 
--Jerald Berray and are residents of the city of Austin. 

WITH t1 AS
	(
		SELECT MAX(order_date) oldest_order
		FROM sale.customer c, sale.orders o
		WHERE c.customer_id=o.customer_id
		AND first_name+last_name = 'JeraldBerray'
	)
SELECT  a.customer_id, a.first_name, a.last_name, a.city, b.order_date
FROM sale.customer a, sale.orders b, t1
WHERE a.customer_id=b.customer_id
AND b.order_date < oldest_order
AND a.city = 'Austin'


--QUESTION: List the stores whose turnovers are under the average store turnovers in 2018.

--First solution
WITH t1 AS
(
SELECT a.store_id, store_name,
	SUM(quantity*list_price*(1-discount)) turnovers
FROM sale.orders a
	INNER JOIN sale.order_item b ON a.order_id=b.order_id
	INNER JOIN sale.store c ON a.store_id=c.store_id
WHERE YEAR(order_date)=2018
GROUP BY store_name, a.store_id
), t2 AS
(SELECT AVG(turnovers) avg_turnover
FROM t1)
SELECT *
FROM t1, t2
WHERE turnovers<avg_turnover

--Second solution
WITH t1 AS
(
SELECT store_id, 
	SUM(quantity*list_price*(1-discount)) turnovers
FROM sale.orders a
	INNER JOIN sale.order_item b
	ON a.order_id=b.order_id
WHERE YEAR(order_date)=2018
GROUP BY store_id
), t2 AS
(SELECT AVG(turnovers) avg_turnover
FROM t1
)
SELECT s.store_name, 
	CAST(turnovers AS DECIMAL(10,2)) turnovers, 
	CONVERT(DECIMAL(10,2), avg_turnover) avg_turnover
FROM t1, t2, sale.store s
WHERE t1.store_id=s.store_id
AND turnovers<avg_turnover

--Third solution(making currency)
WITH t1 AS
(
SELECT a.store_id, store_name,
	SUM(quantity*list_price*(1-discount)) turnovers
FROM sale.orders a
	INNER JOIN sale.order_item b ON a.order_id=b.order_id
	INNER JOIN sale.store c ON a.store_id=c.store_id
WHERE YEAR(order_date)=2018
GROUP BY store_name, a.store_id
), t2 AS
(SELECT AVG(turnovers) avg_turnover
FROM t1)
SELECT store_id, store_name, FORMAT(turnovers,'C'), FORMAT(avg_turnover,'C3')
FROM t1, t2
WHERE turnovers<avg_turnover

--FORMAT
--How to format numbers as currency?
SELECT 
FORMAT(999.9998, 'C') Normal,
FORMAT(999.9998, 'C3') DecimalPlace,
FORMAT(999.9998, 'C', 'pl-PL') Poland,
FORMAT(999.9998, 'C', 'en-US') USA,
FORMAT(999.9998, 'C', 'tr-TR') Turkiye,
FORMAT(999.9998, 'C', 'de-De') Germany;


--QUESTION: Write a query that returns the net amount of their first order for customers who placed 
--their first order after 2019-10-01.

SELECT customer_id, MIN(order_date) first_order
FROM sale.orders
GROUP BY customer_id
HAVING MIN(order_date) > '2019-10-01';

WITH t1 AS
(
		SELECT customer_id, MIN(order_date) first_order
		FROM sale.orders
		GROUP BY customer_id
)
SELECT a.customer_id, first_name, last_name, a.order_id,
	SUM(quantity*list_price*(1-discount)) net_price
FROM sale.orders a
	INNER JOIN sale.order_item b ON a.order_id=b.order_id
	INNER JOIN sale.customer c ON a.customer_id=c.customer_id
	INNER JOIN t1 ON a.customer_id = t1.customer_id 
WHERE t1.first_order > '2019-10-01'
GROUP BY a.customer_id, first_name, last_name, a.order_id
ORDER BY 1;