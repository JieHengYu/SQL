----------------

-- Exercises

----------------

-- This section provides exercises to help us familiarise ourselves with the subjects discussed in this lesson.

USE TSQLV6;



------------------
-- Exercise 1
------------------

-- Write a query against the `dbo.Orders` table that computes both a rank & a dense rank for each customer order, partitioned by `custid` & ordered by `qty`:

SELECT custid, orderid, qty,
	RANK() OVER PO AS rnk,
	DENSE_RANK() OVER PO AS drnk
FROM dbo.Orders
WINDOW PO AS (PARTITION BY custid
			  ORDER BY qty)
ORDER BY custid, qty;



------------------
-- Exercise 2
------------------

-- Earlier in the lesson, in the section "Ranking window functions", we provided the following query against the `Sales.OrderValues` view to return distinct values & their associated row numbers:

SELECT val, ROW_NUMBER() OVER(ORDER BY val) AS rownum
FROM Sales.OrderValues
GROUP BY val;

-- Can you think of an alternative way to achieve the same task?

SELECT val,
	RANK() OVER (ORDER BY val) AS rownum
FROM Sales.OrderValues
GROUP BY val;

SELECT val,
	DENSE_RANK() OVER (ORDER BY val) AS rownum
FROM Sales.OrderValues
GROUP BY val;



------------------
-- Exercise 3
------------------

-- Write a query against the `dbo.Orders` table that computes for each customer order both the difference between the current order quantity & the customer's previous order quantity & the difference between the current order quantity & the customer's next

-- order quantity:

SELECT custid, orderdate, qty,
	LAG(qty) OVER PO AS prevqty,
	LEAD(qty) OVER PO AS nextqty,
	qty - LAG(qty) OVER PO AS diffprev,
	qty - LEAD(qty) OVER PO AS diffnext
FROM dbo.Orders
WINDOW PO AS (PARTITION BY custid
			  ORDER BY orderdate)
ORDER BY custid, orderdate;



------------------
-- Exercise 4
------------------

-- Write a query against the `dbo.Orders` table that returns a row for each employee, a column for each order year, & the count of orders for each employee & order year:

SELECT empid, [2020] AS cnt2020, [2021] AS cnt2021, [2022] AS cnt2022
FROM (SELECT empid, YEAR(orderdate) AS orderyear, qty
      FROM dbo.Orders) AS O
PIVOT(COUNT(qty) FOR orderyear IN ([2020], [2021], [2022])) AS P;



------------------
-- Exercise 5
------------------

-- Run the following code to create & populate the `dbo.EmpYearOrders` table:

USE TSQLV6;

DROP TABLE IF EXISTS dbo.EmpYearOrders;

CREATE TABLE dbo.EmpYearOrders (
	empid	INT	NOT NULL
		CONSTRAINT PK_EmpYearOrders PRIMARY KEY,
	cnt2020 INT NULL,
	cnt2021 INT	NULL,
	cnt2022 INT NULL
);

INSERT INTO dbo.EmpYearOrders (empid, cnt2020, cnt2021, cnt2022)
	SELECT empid, [2020] AS cnt2020, [2021] AS cnt2021, [2022] AS cnt2022
	FROM (SELECT empid, YEAR(orderdate) AS orderyear, qty
		  FROM dbo.Orders) AS O
	PIVOT(COUNT(qty) FOR orderyear IN ([2020], [2021], [2022])) AS P;

SELECT * FROM dbo.EmpYearOrders;

-- Write a query against the `dbo.EmpYearOrders` table that unpivots the data, returning a row for each employee & order year with the number of orders. Exclude rows in which the number of orders is 0 (in this example, employee 3 in the year 2021):

SELECT empid, REPLACE(orderyear, 'cnt', '') AS orderyear, qty
FROM dbo.EmpYearOrders
UNPIVOT(qty FOR orderyear IN (cnt2020, cnt2021, cnt2022)) AS U
WHERE qty > 0
ORDER BY empid, orderyear;



------------------
-- Exercise 6
------------------

-- Write a query against the `dbo.Orders` table that returns the total quantities for each of the following: (employee, customer, & orderyear), (employee & orderyear), & (customer & orderyear). Include a result column in the output that uniquely identifies

-- the grouping set with which the current row is associated:

SELECT GROUPING_ID(empid, custid, YEAR(orderdate)) AS groupingset,
	empid, custid, YEAR(orderdate) AS orderyear, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY GROUPING SETS (
	(empid, custid, YEAR(orderdate)),
	(empid, YEAR(orderdate)),
	(custid, YEAR(orderdate))
);


------------------
-- Exercise 7
------------------

-- Write a query against the `Sales.Orders` table that returns a row for each week, assuming the week starts on a Sunday, with result columns showing when the week started, when the week ended, & the week's order count:

DECLARE
	@bucketwidth AS INT = 7,
	@origin AS DATE = '18991231'; -- December 31, 1899 was a Sunday.

WITH orderbucket AS (
SELECT empid, custid, orderdate, orderid, 
	DATE_BUCKET(day, @bucketwidth, orderdate, @origin) AS startofweek,
	DATEADD(day, @bucketwidth - 1, DATE_BUCKET(day, @bucketwidth, orderdate, @origin)) AS endofweek
FROM Sales.Orders
)
SELECT startofweek, endofweek, COUNT(*) AS numorders
FROM orderbucket
GROUP BY startofweek, endofweek
ORDER BY startofweek;



------------------
-- Exercise 8
------------------

-- Suppose that our organisation's fiscal year runs from July 1 to June 30. Write a query against the `Sales.OrderValues` view that returns the total quantities & values per shipper & fiscal year of the orderdate. The result should have columns for the

-- shipper ID, start date of fiscal year, end date of fiscal year, total quantity, & total value:

DECLARE
	@bucketwidth AS INT = 1,
	@origin AS DATE = '19000701';

WITH fiscalbucket AS (
	SELECT *, DATE_BUCKET(year, @bucketwidth, orderdate, @origin) AS startofyear,
		DATEADD(day, -1, DATE_BUCKET(year, @bucketwidth, orderdate, @origin)) AS endofyear
	FROM Sales.OrderValues
)
SELECT shipperid, startofyear, endofyear,
	SUM(qty) AS sumqty, SUM(val) AS sumval
FROM fiscalbucket
GROUP BY shipperid, startofyear, endofyear
ORDER BY shipperid;
