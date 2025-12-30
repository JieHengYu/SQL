-----------------

-- Exercises

-----------------

-- This section provides exercises to help you familiarise yourself with the subjects discussed in this lesson.

USE TSQLV6;



-----------------
-- Exercise 1
-----------------

-- Explain the difference between the UNION ALL & UNION operators. In what cases are the two equivalent? When they are equivalent, which one should you use?



-- The UNION ALL operators combines two input queries & returns a single result multiset. This means that it keeps duplicates if there are any. The UNION operator similarly combines two input queries, but returns a single result set. This means that the 

-- UNION operator removes duplicates & returns only distinct results. In cases where combining the two input queries results in an output without any duplicates, UNION ALL & UNION are equivalent. However, in such a case, it's recommended to use UNION ALL

-- so we don't pay the performance cost for distinct processing.



-----------------
-- Exercise 2
-----------------

-- Write a query that generates a virtual auxiliary table of 10 numbers in the range 1 through 10 without using a looping construct or the GENERATE_SERIES() function. We do not need to guarantee any presentation order of the rows in the output of our

-- solution:

SELECT 1 AS n
UNION ALL
SELECT 2 AS n
UNION ALL
SELECT 3 AS n
UNION ALL
SELECT 4 AS n
UNION ALL
SELECT 5 AS n
UNION ALL
SELECT 6 AS n
UNION ALL
SELECT 7 AS n
UNION ALL
SELECT 8 AS n
UNION ALL
SELECT 9 AS n
UNION ALL
SELECT 10 AS n;



-----------------
-- Exercise 3
-----------------

-- Write a query that returns customer & employee pairs that had order activity in January 2022 but not in February 2022, using the `Sales.Orders` table:

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20220101' AND orderdate < '20220201'
EXCEPT
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20220201' AND orderdate < '20220301';



-----------------
-- Exercise 4
-----------------

-- Write a query that returns customer & employee pairs that had order activity in both January 2022 & Febraury 2022, using the `Sales.Orders` table:

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20220101' AND orderdate < '20220201'
INTERSECT
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20220201' AND orderdate < '20220301';




-----------------
-- Exercise 5
-----------------

-- Write a query that returns customer & employee pairs that had order activity in both January 2022 & February 2022, but not in 2021, using the `Sales.Orders` table:

(SELECT custid, empid
 FROM Sales.Orders
 WHERE orderdate >= '20220101' AND orderdate < '20220201'
 INTERSECT
 SELECT custid, empid
 FROM Sales.Orders
 WHERE orderdate >= '20220201' AND orderdate < '20220301')
EXCEPT
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20210101' AND orderdate < '20220101';



-----------------
-- Exercise 6
-----------------

-- You are given the following query:

SELECT country, region, city
FROM HR.Employees

UNION ALL

SELECT country, region, city
FROM Production.Suppliers;

-- You are asked to add logic to the query so that it guarantees that the rows from `HR.Employees` are returned in the output before the rows from `Production.Suppliers`. Also, within each segment, the rows should be sorted by country, region, & city.

SELECT country, region, city
FROM (
	SELECT country, region, city, 0 AS category
	FROM HR.Employees

	UNION ALL

	SELECT country, region, city, 1 AS category
	FROM Production.Suppliers
) AS U
ORDER BY category, country, region, city;