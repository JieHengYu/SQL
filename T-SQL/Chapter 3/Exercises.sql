-----------------

-- Exercises

-----------------

-- This section provides exercises to helps us familiarise ourselves with the subjects discussed in this chapter.

USE TSQLV6;



--------------------
-- Exercise 1-1
--------------------

-- Write a query that generates five copies of each employee row using the tables `HR.Employees` & `dbo.Nums`:

SELECT E.empid, E.firstname, E.lastname, N.n
FROM HR.Employees AS E
	CROSS JOIN dbo.Nums AS N
WHERE N.n <= 5;



--------------------
-- Exercise 1-2
--------------------

-- Write a query that returns a row for each employee & day in the range June 12, 2022 through June 16, 2022 using the tables `HR.Employees` & `dbo.Nums`:

SELECT E.empid, N.dt
FROM HR.Employees AS E
	CROSS JOIN (SELECT n, CAST(DATEADD(day, n - 1, '20220612') AS DATE) AS dt
				FROM dbo.Nums
				WHERE DATEADD(day, n - 1, '20220612') <= '20220616') AS N
ORDER BY E.empid, N.dt;



--------------------
-- Exercise 2
--------------------

-- Explain what's wrong in the following query, & provide a correct alternative.

SELECT Customers.custid, Customer.companyname, Orders.orderid, Orders.orderdate
FROM Sales.Customers AS C
	INNER JOIN Sales.Orders AS O
		ON Customers.custid = Orders.custid;

-- Since the tables are aliased in the FROM clause, we should not use the full table name when referencing qualifying columns. Instead, we should use the alias.

SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
	INNER JOIN Sales.Orders AS O
		ON C.custid = O.custid



--------------------
-- Exercise 3
--------------------

-- Return US customers, & for each customer return the total number of orders & total quantities, using the tables `Sales.Customers`, `Sales.Orders`, & `Sales.OrderDetails`:

SELECT C.custid, OD.numorders, OD.totalqty
FROM Sales.Customers AS C
	LEFT OUTER JOIN (
		SELECT O.custid, COUNT(DISTINCT O.orderid) AS numorders, SUM(OD.qty) AS totalqty
		FROM Sales.Orders AS O
 			INNER JOIN Sales.OrderDetails AS OD
				ON O.orderid = OD.orderid
		GROUP BY O.custid
	) AS OD
		ON C.custid = OD.custid
WHERE country = 'USA';



--------------------
-- Exercise 4
--------------------

-- Return customers & their orders, including customers who placed no orders, using the tables `Sales.Customers` & `Sales.Orders` tables:

SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
		ON C.custid = O.custid
ORDER BY CASE WHEN O.orderid IS NULL THEN 1 ELSE 0 END, O.orderdate;



--------------------
-- Exercise 5
--------------------

-- Return customers who placed no orders, using the tables `Sales.Customers` & `Sales.Orders`:

SELECT C.custid, C.companyname
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
		ON C.custid = O.custid
WHERE O.orderid IS NULL;



--------------------
-- Exercise 6
--------------------

-- Return customers with orders placed on February 12, 2022, along with their orders, using the tables `Sales.Customers` & `Sales.Orders`:

SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Orders AS O
	LEFT OUTER JOIN Sales.Customers AS C
		ON O.custid = C.custid
WHERE orderdate = '20220212';	



--------------------
-- Exercise 7
--------------------

-- Write a query that returns all customers, but matches them with their respective orders only if they were placed on February 12, 2022, using the `Sales.Customers` & `Sales.Orders` tables:

SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
	LEFT OUTER JOIN (
		SELECT *
		FROM Sales.Orders
		WHERE orderdate = '20220212'
	) AS O
		ON C.custid = O.custid
ORDER BY C.companyname;



--------------------
-- Exercise 8
--------------------

-- Explain why the following query isn't a correct solution query for Exercise 7:

SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
		ON C.custid = O.custid
WHERE O.orderdate = '20220212'
	OR O.orderid IS NULL;

-- The where clause is applied after the result of the join is produced, so it will not return all customers. It will return customers who placed orders on February 12, 2022, or customers who did not place any orders at all. The prompt is to return all

-- customers, so we cannot have any final WHERE filter that removes customers.



--------------------
-- Exercise 9
--------------------

-- Return all customers, & for each return a Yes/No value depending on whether the customer placed orders on February 12, 2022. Use the tables `Sales.Customers` & `Sales.Orders`:

SELECT C.custid, C.companyname,
	CASE COUNT(CASE WHEN O.orderdate = '20220212' THEN 1 ELSE NULL END)
		WHEN 1 THEN 'Yes'
		ELSE 'No' 
		END AS HasOrderOn20220212
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
		ON C.custid = O.custid
GROUP BY C.custid, C.companyname;

-- To check my work:

SELECT C.custid, C.companyname, O.orderdate, O.orderid
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
		ON C.custid = O.custid
ORDER BY C.custid, O.orderdate;