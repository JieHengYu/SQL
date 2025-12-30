----------------------

-- Exercises

----------------------

-- This section provides exercises to help you familiarise yourself with the subjects discussed in this chapter.



-- Note that any given task in SQL can be solved in many different ways. For example, many of the tasks in this cahpter could have been solved either with joins or with subqueries. However, since the chapter focuses on subqueries, the expectation is that you

-- solve the tasks using subqueries.

USE TSQLV6;



------------------
-- Exercise 1
------------------

-- Write a query that returns all orders placed on the last day of activity that can be found in the `Sales.Orders` table:

SELECT O1.orderid, O1.orderdate, O1.custid, O1.empid
FROM Sales.Orders AS O1
WHERE O1.orderdate = (SELECT MAX(O2.orderdate)
				      FROM Sales.Orders AS O2);



------------------
-- Exercise 2
------------------

-- Write a query that returns all orders placed by the customer(s) who placed the highest number of orders. Note that more than one customer might have the same number of orders:

SELECT O1.custid, O1.orderid, O1.orderdate, O1.empid
FROM Sales.Orders AS O1
WHERE O1.custid IN (SELECT TOP (1) O2.custid
				    FROM Sales.Orders AS O2
				    GROUP BY O2.custid
				    ORDER BY COUNT(DISTINCT O2.orderid) DESC);

-- Thank god for the TOP function.



------------------
-- Exercise 3
------------------

-- Write a query that returns employees who did not place orders on or after May 1, 2022, using the tables `HR.Employees` & `Sales.Orders`:

SELECT E.empid, E.firstname, E.lastname
FROM HR.Employees AS E
WHERE E.empid NOT IN (SELECT O.empid
					FROM Sales.Orders AS O
					WHERE O.orderdate >= '20220501');



------------------
-- Exercise 4
------------------

-- Write a query that returns countries where there are customers but not employees, using the tables `Sales.Customers` & `HR.Employees`:

SELECT C.country
FROM Sales.Customers AS C
GROUP BY C.country
HAVING C.country NOT IN (SELECT E.country
					     FROM HR.Employees AS E
					     GROUP BY E.country);



------------------
-- Exercise 5
------------------

-- Write a query that returns for each customer all orders placed on the customer's last day of activity, using the table `Sales.Orders`:

SELECT O1.custid, O1.orderid, O1.orderdate, O1.empid
FROM Sales.Orders AS O1
WHERE O1.orderdate = (SELECT MAX(O2.orderdate)
					  FROM Sales.Orders AS O2
					  WHERE O2.custid = O1.custid)
ORDER BY O1.custid;



------------------
-- Exercise 6
------------------

-- Write a query that returns customers who placed orders in 2021 but not in 2022, using the `Sales.Customers` & `Sales.Orders` tables:

SELECT C.custid, C.companyname
FROM Sales.Customers AS C
WHERE C.custid IN (SELECT O.custid
				   FROM Sales.Orders AS O
				   GROUP BY O.custid
				   HAVING COUNT(CASE WHEN orderdate >= '20210101' AND orderdate < '20220101' THEN 1 ELSE NULL END) > 0
					   AND COUNT(CASE WHEN orderdate >= '20220101' AND orderdate < '20230101' THEN 1 ELSE NULL END) = 0);

-- Checking my work.

SELECT custid,
	COUNT(CASE WHEN orderdate >= '20210101' AND orderdate < '20220101' THEN 1 ELSE NULL END) AS numorders2021,
	COUNT(CASE WHEN orderdate >= '20220101' AND orderdate < '20230101' THEN 1 ELSE NULL END) AS numorders2022
FROM Sales.Orders
GROUP BY custid
HAVING COUNT(CASE WHEN orderdate >= '20210101' AND orderdate < '20220101' THEN 1 ELSE NULL END) > 0
	AND COUNT(CASE WHEN orderdate >= '20220101' AND orderdate < '20230101' THEN 1 ELSE NULL END) = 0;



------------------
-- Exercise 7
------------------

-- Write a query that returns customers who ordered product 12, using the tables `Sales.Customers`, `Sales.Orders` & `Sales.OrderDetails`:

SELECT C.custid, C.companyname
FROM Sales.Customers AS C
WHERE C.custid IN (SELECT O.custid
				   FROM Sales.Orders AS O
				   WHERE O.orderid IN (SELECT OD.orderid
									   FROM Sales.OrderDetails AS OD
									   WHERE OD.productid = 12));



------------------
-- Exercise 8
------------------

-- Write a query that calculates a running-total quantity for each customer & month, using the table `Sales.CustOrders`:

SELECT CO1.custid, CO1.ordermonth, CO1.qty,
	(SELECT SUM(qty)
	 FROM Sales.CustOrders AS CO2
	 WHERE CO2.custid = CO1.custid
		AND CO2.ordermonth <= CO1.ordermonth) AS runqty
FROM Sales.CustOrders AS CO1
ORDER BY CO1.custid, CO1.ordermonth;



------------------
-- Exercise 9
------------------

-- Explain the difference between IN & EXISTS.



-- For IN, the subquery returns a list of values, & the outer query checks if a given value is in that list. It's typically used to compare a single column against a set of values. Here's an example:

SELECT C.custid, C.companyname
FROM Sales.Customers AS C
WHERE C.custid IN (SELECT O.custid
				   FROM Sales.Orders AS O
				   WHERE O.shipcountry = 'France');

-- This finds customers whose `custid` appears in the list of the `custid`s returned from `Sales.Orders`.

	-- IN materialises the list of values first, then performs the comparison.

	-- If the subquery returns a NULL, the result of the IN comparison yields UNKNOWN, & since the WHERE predicate only preserves TRUE, the query will return empty rows.



-- For EXISTS, it checks if at least one row is returned by the subquery for each outer row. It's typically used when we only care about the existence of a related rows, not the actual values. Here's an example:

SELECT C.custid, C.companyname
FROM Sales.Customers AS C
WHERE C.custid EXISTS (SELECT *
					   FROM Sales.Orders AS O
					   WHERE O.custid = C.custid);

-- This checks row-by-row of the outer query: "Does this customer have at least one order?" If yes, then the customer is included in the result.

	-- As soon a matching row is found, EXISTS returns TRUE & stops searching (short circuits).



------------------
-- Exercise 10
------------------

-- Write a query that returns for each order the number of days that passed since the same customer's previous order. To determine recency among orders, use `orderdate` as the primary sort element & `orderid` as the tiebreaker. Use the `Sales.Orders` table:

SELECT O1.custid, O1.orderdate, O1.orderid,
	DATEDIFF(day, (SELECT MAX(O2.orderdate)
				   FROM Sales.Orders AS O2
				   WHERE O2.orderdate < O1.orderdate
					   AND O2.custid = O1.custid), O1.orderdate) AS diff
FROM Sales.Orders AS O1
ORDER BY O1.custid, O1.orderdate, O1.orderid;



