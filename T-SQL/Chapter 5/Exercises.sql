-----------------

-- Exercises

-----------------

-- This section provides exercises to help us familiarise ourselves with the concepts of this chapter.

USE TSQLV6;



------------------
-- Exercise 1
------------------

-- The following query attempts to filter orders that were not placed on the last day of the year. It's supposed to return the order ID, order date, customer ID, employee ID, & respective end-of-year date for each order:

SELECT orderid, orderdate, custid, empid,
	DATEFROMPARTS(YEAR(orderdate), 12, 31) AS endofyear
FROM Sales.Orders
WHERE orderdate <> endofyear;

-- When we try to run this query, we get the error, "Invalid column name 'endofyear'". Explain what the problem is, & suggest a valid solution.



-- This query fails because the WHERE clause is evaluated before the SELECT clause. When the WHERE clause runs, the alias `endofyear` hasn't been created yet -- it only exists in the result set produced by the SELECT clause. As a result, SQL Server interprets

-- `endofyear` as a column name from the `Sales.Orders` table, which doesn't exist, & throws an error. To fix the issue, we need to use the full expression directly in the WHERE clause:

SELECT orderid, orderdate, custid, empid,
	DATEFROMPARTS(YEAR(orderdate), 12, 31) AS endofyear
FROM Sales.Orders
WHERE orderdate <> DATEFROMPARTS(YEAR(orderdate), 12, 31);



------------------
-- Exercise 2-1
------------------

-- Write a query that returns the maximum value in the `orderdate` column for each employee in the `Sales.Orders` table:

SELECT empid, MAX(orderdate) AS maxorderdate
FROM Sales.Orders
GROUP BY empid;



------------------
-- Exercise 2-2
------------------

-- Encapsulate the query from Exercise 2-1 in a derived table. Write a join query between the derived table & the `Sales.Orders` table to return the orders with the maximum order date for each employee in the `Sales.Orders` table:

SELECT O1.empid, O1.orderdate, O1.orderid, O1.custid
FROM Sales.Orders AS O1
	INNER JOIN (SELECT empid, MAX(orderdate) AS maxorderdate
				FROM Sales.Orders
				GROUP BY empid) AS O2
		ON O1.empid = O2.empid AND O1.orderdate = O2.maxorderdate;



------------------
-- Exercise 3-1
------------------

-- Write a query that calculates a row number for each order based on `orderdate`, `orderid` ordering:

SELECT orderid, orderdate, custid, empid,
	ROW_NUMBER() OVER (ORDER BY orderdate, orderid) AS rownum
FROM Sales.Orders;



------------------
-- Exercise 3-2
------------------

-- Write a query that returns rows with row numbers 11 through 20 based on the row-number definition in Exercise 3-1. Use a CTE to encapsulate the code from Exercise 3-1:

WITH O AS (
	SELECT orderid, orderdate, custid, empid,
		ROW_NUMBER() OVER (ORDER BY orderdate, orderid) AS rownum
	FROM Sales.Orders
)
SELECT orderid, orderdate, custid, empid, rownum
FROM O
WHERE rownum BETWEEN 11 AND 20;



------------------
-- Exercise 4
------------------

-- Write a solution using a recursive CTE that returns the management chain leading to Patricia Doyle (employee ID 9). Use the `HR.Employees` table:

WITH EmpsRCTE AS (
	SELECT empid, mgrid, firstname, lastname
	FROM HR.Employees
	WHERE empid = 9

	UNION ALL

	SELECT E2.empid, E2.mgrid, E2.firstname, E2.lastname
	FROM EmpsRCTE AS E1
		INNER JOIN (SELECT empid, mgrid, firstname, lastname
				   FROM HR.Employees) AS E2
			ON E1.mgrid = E2.empid
)
SELECT empid, mgrid, firstname, lastname
FROM EmpsRCTE;



------------------
-- Exercise 5-1
------------------

-- Create a view named `Sales.VEmpOrders` that returns the total quantity for each employee & year, using the `Sales.Orders` & `Sales.OrderDetails` tables:

CREATE OR ALTER VIEW Sales.VEmpOrders
AS
SELECT O.empid, YEAR(O.orderdate) AS orderyear, SUM(OD.qty) AS qty
FROM Sales.Orders AS O
	LEFT JOIN Sales.OrderDetails AS OD
		ON O.orderid = OD.orderid
GROUP BY O.empid, YEAR(O.orderdate)
GO

SELECT *
FROM Sales.VEmpOrders
ORDER BY empid, orderyear;



------------------
-- Exercise 5-2
------------------

-- Write a query against `Sales.VEmpOrders` that returns the running total quantities for each employee & year:

SELECT V1.empid, V1.orderyear, V1.qty,
	(SELECT SUM(V2.qty)
	 FROM Sales.VEmpOrders AS V2
	 WHERE V1.empid = V2.empid
		AND V2.orderyear <= V1.orderyear) AS runqty
FROM Sales.VEmpOrders AS V1
ORDER BY V1.empid, V1.orderyear;



------------------
-- Exercise 6-1
------------------

-- Create an inline TVF that accepts as inputs a supplier ID (`@supid AS INT`) & a requested number of products (`@n AS INT`). The function should return `@n` produces with the highest unit prices that are supplied by the specified supplier ID. Use the

-- `Production.Products` table:

CREATE OR ALTER FUNCTION Production.TopProducts
	(@supid AS INT, @n AS INT) RETURNS TABLE
AS
RETURN
SELECT TOP (@n) productid, productname, unitprice
FROM Production.Products
WHERE supplierid = @supid
ORDER BY unitprice DESC;

SELECT * FROM Production.TopProducts(5, 2);



------------------
-- Exercise 6-2
------------------

-- Using the CROSS APPLY operator, the `Production.Suppliers` table, & the function we created in 6-1, return the two most expensive products for each supplier:

SELECT S.supplierid, S.companyname, TP.productid, TP.productname, TP.unitprice
FROM Production.Suppliers AS S
	CROSS APPLY Production.TopProducts(S.supplierid, 2) AS TP;
