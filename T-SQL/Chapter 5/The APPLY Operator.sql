----------------------------

-- The APPLY Operator

----------------------------

-- The APPLY operator is a table operator that we use in the FROM clause of a query. It allows us to combine each row from one input (the left table) with the results of another table expression (the right table). The right input is usually a derived 

-- table or a table-valued function (TVF).



-- There are two types of APPLY:

	-- CROSS APPLY

	-- OUTER APPLY

-- Like the JOIN operator, APPLY follows logical query processing phases.

	-- CROSS APPLY performs a single phase: it applies the right input to each row from the left input & returns only the matching rows.

	-- OUTER APPLY performs two phases: it returns both the matching rows &, when no match exists, includes the left row with NULL values for the right side (similar to a left outer join).



-- At first glance, CROSS APPLY can look similar to a CROSS JOIN. Both combine rows from two tables. For example, the following two queries produce the same result set:

USE TSQLV6;

SELECT S.shipperid, E.empid
FROM Sales.Shippers AS S
	CROSS JOIN HR.Employees AS E;

SELECT S.shipperid, E.empid
FROM Sales.Shippers AS S
	CROSS APPLY HR.Employees AS E;

-- The difference is that CROSS JOIN works only with two independent tables, while CROSS APPLY allows the right input to depend on each row from the left input. This makes APPLY especially powerful when used with TVFs or correlated subqueries.



-- A regular JOIN treats its two inputs as sets, meaning there is no inherent order between them. Because of this, one side of a JOIN cannot directly reference columns from the other side during evaluation. With APPLY, however, the process is different:

	-- The left input is evaluated first.

	-- The right input is then evaluated once per row from the left. This means the right side can reference attributes from the left side -- these references are essentially correlations. In this sense, we can think of APPLY as a correlated join.
 
-- As an example, the following code uses the CROSS APPLY operator & returns the three most recent orders for each customer:

SELECT C.custid, A.orderid, A.orderdate
FROM Sales.Customers AS C
	CROSS APPLY
		(SELECT TOP(3) O.orderid, O.empid, O.orderdate, O.requireddate
		 FROM Sales.Orders AS O
		 WHERE C.custid = O.custid
		 ORDER BY orderdate DESC, orderid DESC) AS A;

-- Here's what happens step by step:

	-- 1. For each row in `Sales.Customers`, the inner query (`A`) is executed.

	-- 2. The inner query is a derived table that returns the three most recent orders for the current customer (`C.custid`).

	-- 3. Because this derived table depends on the left row, it is a correlated derived table.

	-- 4. The CROSS APPLY operator then combines the customer with their top three orders.

-- In effect, the query returns the three most recent orders for every customer.



-- We can also use the OFFSET-FETCH option instead of TOP to limit the number of rows returned. For example, the following query returns the three most recent orders per customer using OFFSET-FETCH:

SELECT C.custid, A.orderid, A.orderdate
FROM Sales.Customers AS C
	CROSS APPLY
		(SELECT O.orderid, O.empid, O.orderdate, O.requireddate
		 FROM Sales.Orders AS O
		 WHERE O.custid = C.custid
		 ORDER BY orderdate DESC, orderid DESC
		 OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY) AS A;

-- In this query:

	-- The inner query is ordered by `orderdate` (& `orderid` is a tiebreaker).

	-- `OFFSET 0 ROWS` skips no rows.

	-- `FETCH NEXT 3 ROWS ONLY` limits the output to the top three rows for each customer.

-- This is functionally equivalent to using `TOP(3)`.



-- When the right table expression returns an empty set, CROSS APPLY excludes the corresponding row from the left input. For example, since customers 22 & 57 have no orders, the derived table returns an empty set for each of them, so those customers do 

-- not appear in the output. If we want to keep all rows from the left side, even when there are no matches on the right, use OUTER APPLY. This operator has an additional logical phase that:

	-- Preserves all rows from the left input.

	-- Inserts NULL values for columns from the right input when no match exists.

-- In this sense, OUTER APPLY behaves like a LEFT OUTER JOIN. However, because of the way APPLY works (evaluating the right side per left row), there is no equivalent of a RIGHT OUTER JOIN. As an example, run the following code to return the three most 

-- recent orders for each customer & include in the output customers who did not place orders:

SELECT C.custid, A.orderid, A.orderdate
FROM Sales.Customers AS C
	OUTER APPLY
		(SELECT TOP(3) O.orderid, O.empid, O.orderdate, O.requireddate
		 FROM Sales.Orders AS O
		 WHERE O.custid = C.custid
		 ORDER BY orderdate DESC, orderid DESC) AS A;

-- This time, customers 22 & 57 are included in the result set, but their order-related columns (`orderid` & `orderdate`) contain NULL values because no matching rows were found.



-- Sometimes, it's more convenient to use inline table-valued functions (TVFs) instead of derived tables. Inline TVFs make your code easier to read, reuse, & maintain. For example, the following code creates an inline TVF called `dbo.TopOrders`. This

-- function accepts two inputs -- a customer ID (`@custid`) & a number (`@n`) -- & returns the `@n` most recent orders for that customer:

CREATE OR ALTER FUNCTION dbo.TopOrders
	(@custid AS INT, @n AS INT)
	RETURNS TABLE
AS
RETURN
SELECT TOP(@n) orderid, empid, orderdate, requireddate
FROM Sales.Orders
WHERE custid = @custid
ORDER BY orderdate DESC, orderid DESC;

-- With this function in place, we can replace the derived table from earlier examples with a call to the TVF:

SELECT C.custid, C.companyname,
	A.orderid, A.empid, A.orderdate, A.requireddate
FROM Sales.Customers AS C
	CROSS APPLY dbo.TopOrders(C.custid, 3) AS A;

-- From a physical processing perspective, nothing has really changed. SQL Server queries the underlying objects directly -- just as it did when using a derived table.
