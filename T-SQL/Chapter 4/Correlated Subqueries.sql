-------------------------------

-- Correlated Subqueries

-------------------------------

-- Correlated subqueries are subqueries that refers to attributes from the tables that appear in the outer query. This means the subquery is dependent on the outer query & cannot be invoked as a standalone query. Logically, the subquery is evaluated separately

-- for each outer row in the logical query processing step in which it appears. For example, the query below returns orders with the maximum order ID for each customer.

USE TSQLV6;

SELECT O1.custid, O1.orderid, O1.orderdate, O1.empid -- (Sample Query 4-1)
FROM Sales.Orders AS O1
WHERE O1.orderid = (SELECT MAX(O2.orderid)
					FROM Sales.Orders AS O2
					WHERE O2.custid = O1.custid);

-- The outer query is scanning `Sales.Orders` & calling it `O1`. For each row in `O1`, SQL runs the subquery:

	-- SELECT MAX(O2.orderid)
	-- FROM Sales.Orders AS O2
	-- WHERE O2.custid = O1.custid;

-- Notice `O1.custid` inside the subquery -- that's the correlation. This tells the subquery: "look at all orders (`O2`) that belong to the same customer as the current `O1` row, & return the maximum order ID for that customer."

-- The outer WHERE then checks `O1.orderid = (that maximum order ID)`, so only the rows where the current order is the customer's latest (highest ID) order will pass.



-- Because of the dependency on the outer query, correlated subqueries are usually harder to figure out than self-contained subqueries. To simplify things, we can focus our attention on a single row in the outer table & think about the logical processing that

-- takes place in the inner query for that row. For example, focus your attention on the following row from the table in the outer query, which has an order ID `10248`:

SELECT O1.custid, O1.orderid, O1.orderdate, O1.empid
FROM Sales.Orders AS O1
WHERE O1.orderid = 10248;

-- When the subquery is evaluated for this row, the correlation to `O1.custid` means `85`. If we substitute the correlation manually with `85`, we get the following:

SELECT MAX(O2.orderid)
FROM Sales.Orders AS O2
WHERE O2.custid = 85;

-- This query returns the order id `10739`. The outer row's order ID -- 10248 -- is compared with the inner one -- 10739 -- & because there's no match in this case, the outer row is filtered out. The subquery returns the same value for all rows in `O1` with

-- the same customer ID, & only in one case is there a match -- when the outer row's order ID is the maximum for the current customer. Thinking in such terms will make it easier for use to grasp the concept of correlated subqueries.



-- The fact that correlated subqueries are dependent on the outer query makes it harder to troubleshoot problems with them compared to self-contained subqueries. We can't just highlight the subquery portion & run it. For example, if we try to highlight & run

-- the subquery portion in sample query 4-1, we'll get an identifier error.

SELECT MAX(O2.orderid)
FROM Sales.Orders AS O2
WHERE O2.custid = O1.custid;

-- This error indicates that the identifier `O1.custid` cannot be bound to any object in the query, because `O1` is not defined in the query. It is defined only in the context of the outer query. To troubleshoot correlated subqueries, we need to substitute 

-- the correlation with a constant, & after ensuring the code is correct, substitute the constant with the correlation.



-- As another example, suppose we need to query the `Sales.OrderValues` view & return for each order the percentage of the current order value of the customer total. We can write an outer query against one instance of the `Sales.OrderValues` view called `O1`.

-- In the SELECT list, divide the current value by the result of a correlated subquery against a second instance of `Sales.OrderValues` called `O2` that returns the current customer's total. Here's the complete solution query:

SELECT O1.orderid, O1.custid, O1.val,
	CAST(100.0 * val / (SELECT SUM(O2.val)
						FROM Sales.OrderValues AS O2
						WHERE O2.custid = O1.custid)
		 AS NUMERIC(5, 2)) AS pct
FROM Sales.OrderValues AS O1
ORDER BY O1.custid, O1.orderid;



-----------------------------
-- The EXISTS Predicate
-----------------------------

-- T-SQL supports a predicate called EXISTS, which accepts a subquery as input & returns TRUE if the subquery returns any rows & FALSE otherwise. For example, the following query returns customers from Spain who placed orders:

SELECT C.custid, C.companyname
FROM Sales.Customers AS C
WHERE C.country = N'Spain'
	AND EXISTS (SELECT * FROM Sales.Orders AS O
				WHERE O.custid = C.custid);

-- The outer query against the `Sales.Customers` table filters only customers from Spain for whom the EXIST predicate returns TRUE. The EXISTS predicate returns TRUE if the current customer has related orders in the `Sales.Orders` table.



-- One of the benefits of using the EXISTS predicate is that we can intuitively phrase queries that sound like English. For example, this query can be read just as we would say it in ordinary English: "Return customers from Spain if they have any orders where 

-- the order's customer ID is the same as the customer's customer ID."



-- As with other predicates, we can negate the EXISTS predicate with the NOT operator. For example, the following query returns customers from Spain who did not place orders:

SELECT C.custid, C.companyname
FROM Sales.Customers AS C
WHERE country = N'Spain'
	AND NOT EXISTS (SELECT * FROM Sales.Orders AS O
					WHERE O.custid = C.custid);



-- Even though this lesson's focus is on logical query processing & not performance, the EXISTS predicate lends itself to good optimisation. That is, the database engine knows that it's enough to determine whether the subquery returns at least one row or none

-- & it doesn't need to process all qualifying rows. We can think of this capability as a kind of short-circuit evaluation. The same applies to the IN predicate.



-- Even though in most cases, the use of the star (*) is considered a bad practice, with EXISTS it isn't. The predicate cares only about the existence of matching rows, regardless of what you have in the SELECT query's SELECT list. Some minor extra cost might 

-- be incurred in the resolution process, where SQL Server expands the * against the metadata info -- for example, to check if we have permissions to query all columns. But this cost is so minor that it is barely noticable. Queries should be natural & 

-- intuitive unless there's a compelling reason to sacrifice this aspect of the code. The form `EXISTS(SELECT * FROM ...)` may be more intuitive than `EXISTS(SELECT 1 FROM ...)` for some. Saving the minor extra cost associated with the resolution of * is not 

-- worth the cost of sacrificing readability of the code.



-- Finally, another aspect of EXISTS that is worth mentioning is that, unlike most predicates in T-SQL, EXISTS uses two-valued logic & not three-valued logic. If we think about it, there's no situation where it's unknown whether a query returns any rows.

