-------------------------

-- Window Functions

-------------------------

-- A window function is a function that computes a scalar value for each row based on a calculation over a subset of rows from the query's result set. This subset of rows is called a window, defined by a window descriptor that determines which rows are

-- included in relation to the current row. The syntax for window functions uses the OVER clause, where we specify the window's definition.



-- In simple terms, a window function performs a calculation over a set of rows & returns a single value per row. A classic example involves aggregate functions such as SUM, COUNT, & AVG, but window functions also include ranking (e.g., ROW_NUMBER, RANK) &

-- offset (e.g., LAG, LEAD) functions. We've already seen a few ways to apply aggregate calculations -- through grouped queries or subqueries -- but both have limitations that window functions elegantly solve.



-- Grouped queries provide aggregate insights but sacrifice detail. Once rows are grouped, all computations occur within the context of those groups, making it impossible to mix aggregate & detailed elements in the same result set. Window functions remove

-- this limitation. They are evaluated per detailed row, applied to a subset of rows from the query's result set, & return a scalar value that becomes another column in the output. Unlike grouped aggregates, window functions preserve the detail rows. For

-- example, suppose we query order values & want to show each order's value along with the percentage it contributes to the customer's total. If we group by customer, we can only compute the total per customer -- we lose the individual orders. With a window

-- function, we can compute both the total order value per customers & the percentage that each order contributes to that total.



-- Subqueries can also perform aggregate calculations, but they operate from a fresh view of the data, independent of the outer query. If the main query includes join, filters, or other operators, those elements don't automatically apply to the subquery. By

-- contrast, a window function operates directly on the result set of the underlying query -- not on a separate view of the data. Any filter, joins, or calculations in the base query automatically affect the window function. If needed, we can still further

-- restrict or refine the window definition.



-- Another advantage of window functions is the ability to define ordering within the calculation. This ordering applies only to the window function's logic, not to have the final results are displayed. In other words, the ORDER BY clause inside the window

-- function defines the calculation order, while a presentation-level ORDER BY (at the end of the query) controls output order. If we omit a presentation ORDER BY, SQL Server does not guarantee any specific order in the results. Even if we include one, it's 

-- ordering may differ from that used in the window function.



-- The following example shows a query against the `Sales.EmpOrders` view in the `TSQLV6` database. It uses a window aggregate function to compute running totals for each employee & month:

USE TSQLV6;

SELECT empid, ordermonth, val,
	SUM(val) OVER (PARTITION BY empid
				   ORDER BY ordermonth
				   ROWS BETWEEN UNBOUNDED PRECEDING
					   AND CURRENT ROW) AS runval
FROM Sales.EmpOrders;

-- A window function's definition can include up to three parts, all specified within the OVER clause:

	-- 1. Window partition

	-- 2. Window order

	-- 3. Window frame

-- An empty OVER() clause represents the entire result set from the underlying query. Anything added to the OVER specification restricts the window to a subset of rows.



-- 1. The window partition (PARTITION BY) clause limits the window to rows that share the same values in the specified partitioning columns as the current row. In the example above, the window is partitioned by `empid`. For a row where `empid = 1`, the 

-- window exposed to the function includes only rows where `empid = 1`.



-- 2. The window order (ORDER BY) clause defines the logical ordering of rows within each partition. This ordering is used for calculation, not for result presentation.

	-- In window aggregate functions, ordering determines how window-frames are applied.

	-- In window ranking functions, ordering defines how ranks are assigned.

-- In our example, the window ordering is based on `ordermonth`.



-- 3. The window-frame (ROWS BETWEEN ... AND ...) clause further narrows the window to a specific subset of rows within the partion, defined by two boundaries (or delimiters). In this case, the frame starts at the first row in the partition (UNBOUNDED

-- PRECEDING) & extends through the current row (CURRENT ROW). This setup produces a running total for each employee by month.



-- By combining partitioning, ordering, & framing, the query computes a running total of `val` for each employee across months.



-- Since a window function operates on the result set produced by the query, & that result set is only available during the SELECT phase of logical query processing, window functions can only appear in the SELECT & ORDER BY clauses. Typically, we use window

-- functions in the SELECT clause. If we need to reference a window function earlier in the query (for example, in a WHERE clause), we can do so by using a table expression such as a derived table or CTE. Define the window function & give it an alias in the 

-- inner query, then reference that alias in the outer query.



-- Although the concept of windowing can take some time to get familiar with, it proves extremely powerful. Beyond traditional analytical calculations, window functions can simplify & optimise a wide range of tasks -- often with more elegance & efficiency

-- than alternative query methods.



---------------------------------
-- Ranking Window Functions
---------------------------------

-- Ranking window functions assign a rank or position to each row relative to others within the defined window. T-SQL supports four ranking functions:

	-- ROW_NUMBER()

	-- RANK()

	-- DENSE_RANK()

	-- NTILE()

-- The following query demonstrates all four:

SELECT orderid, custid, val,
	ROW_NUMBER() OVER (ORDER BY val) AS rownum,
	RANK() OVER (ORDER BY val) AS rank,
	DENSE_RANK() OVER (ORDER BY val) AS dense_rank,
	NTILE(10) OVER (ORDER BY val) AS ntile
FROM Sales.OrderValues
ORDER BY val;



-- The ROW_NUMBER() function assigns sequential integers to rows based on the specified ordering in the OVER clause. In the example, ordering is based on the `val` column -- so as `val` increases, the assigned row number increases as well. However, even 

-- when multiple rows share the same ordering value, ROW_NUMBER() continues numbering sequentially. This means that if the ordering expression isn't unique, the result is nondeterministic -- more than one valid output is possible. In the above example, the 

-- two rows with `val = 36.00` were assigned row numbers 7 & 8. To make the numbering deterministic, include a tiebreaker in the ORDER BY list -- for instance, add `orderid`.



-- Both RANK() & DENSE_RANK() assign the same rank value to rows that share the same ordering value -- unlike ROW_NUMBER(), which always produces unique numbers. The difference lies in how they handle gaps in ranking:

	-- RANK()
		
		-- Skips rank values after ties.
		
		-- The rank of a row equals the number of rows with lower ordering values + 1.

		-- Example: If two rows share the same value ranked as 3, the next row receives rank 5 (not 4).

	-- DENSE_RANK()

		-- Does not skip ranks.

		-- The dense rank of a row equals the number of distict ordering values lower than the current value + 1. Using the same example, the next row after the two tied rows ranked as 3 would receive rank 4.

-- In the output of the above example, a RANK value of 9 indicates eight rows with lower values. A corresponding DENSE_RANK value of 8 indicates seven distinct lower values.



-- The NTILE() function divides the ordered result set into a specified number of tiles (or groups) & assigns a tile number to each row. We specify the desired number of tiles & the ordering expression. In the sample query above, there are 830 rows & we 

-- request 10 tiles:

	-- Each tile therefore contains roughly 83 rows (830 / 10).

	-- Ordering is based on `val`, so the 83 rows with the lowest values go into tile 1, the next 83 into tile 2, & so on.

-- If the total number of rows cannot be divided evenly by the number of tiles, extra rows are distributed one per tile, starting from the first tile. For example, with 102 rows & 5 tiles, the first two tiles would each contain 21 rows, & the remaining three

-- would have 20.



-- Like all window functions, ranking functions can include a window partition clause. Window partitioning limits the calculation to rows that share the same values in the partitioning columns as the current row. For example, the following expression assigns

-- row numbers independently for each customer: `ROW_NUMBER() OVER (PARTITION BY custid ORDER BY val)`. Here's the expression in a full query:

SELECT orderid, custid, val,
	ROW_NUMBER() OVER (PARTITION BY custid
					   ORDER BY val) AS rownum
FROM Sales.OrderValues
ORDER BY custid, val;

-- In this example, each customer's orders are numbered separately based on `val`. The number starts at 1 whenever `custid` changes.



-- It's important to remember that window ordering (inside the OVER clause) is independent of presentation ordering (the query's ORDER BY at the end).

	-- The window-order clause defines the logical ordering used for calculations.

	-- The presentation ORDER BY defines how results are displayed.

-- Window ordering does not alter the relational nature of the result set. If we want to guarantee a particular output order, we must include a presentation-level ORDER BY clause, as shown in the previous examples.



--------------------------------
-- Offset Window Functions
--------------------------------

-- Offset window functions return a value from another row within the window -- either a row at a specific offset from the current one, or the first or last row in a defined frame. T-SQL supports two pairs of offset functions:

	-- LAG() & LEAD()

	-- FIRST_VALUE() & LAST_VALUE()



-- The LAG() & LEAD() functions return values from rows that are behind & ahead of the current row, respectively. They support window partitions & window ordering, but not window framing, since the offset is always defined relative to the current row.

	-- Syntax: `LAG(<expression>, <offset>, <default>)`
	--		   `LEAD(<expression>, <offset>, <default>)`

-- The first argument (required) is the expression or column to return. The second argument (optional) is the offset (default is 1). The third argument (optional) is a default value to return when no row exists at that offset (default is NULL).



-- As an example, the following query returns order information from the `Sales.OrderValues` view. For each customer order, the query uses the LAG function to return the value of the customer's previous order & the LEAD function to return the value of the 

-- customer's next order:

SELECT custid, orderid, val,
	LAG(val) OVER (PARTITION BY custid
				   ORDER BY orderdate, orderid) AS prevval,
	LEAD(val) OVER (PARTITION BY custid
				    ORDER BY orderdate, orderid) AS nextval
FROM Sales.OrderValues
ORDER BY custid, orderdate, orderid;

-- Because no offset was specified, both functions default to 1:

	-- `LAG(val)` returns the previous order's value for the same customer.

	-- `LEAD(val)` returns the next order's value for the same customer.

	-- When there is no previous or next row, the function returns NULL.

-- To change the `<offset>` or `<default>` value, we can write `LAG(val, 3, 0)`, for example, & this expression returns the value from three rows back, or 0 if no such row exists. 



-- In practice, we often use LAG() & LEAD() as part of a calculation. For example:

	-- `val - LAG(val) OVER (...)` returns the difference from the previous order.

	-- `val - LEAD(val) OVER (...)` returns the difference from the next order.



-- The FIRST_VALUE() & LAST_VALUE() functions return the value from the first or last row in the window frame, respectively. They support window partition, window order, & window frame clauses. Because their results depend on the window frame definition,

-- it's important to specify it explicitly. To return the value from the first row in the partition:

	-- Syntax: `FIRST_VALUE(val) OVER (
	--				PARTITION BY custid
	--              ORDER BY orderdate, orderid
	--              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
	--          )`

-- To return the value from the last row in the partition:

	-- Syntax: `LAST_VALUE(val) OVER (
	--				PARTITION BY custid
	--              ORDER BY orderdate, orderid
	--              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
	--          )`



-- If we specify ORDER BY without a frame extent (like ROWS), SQL Server defaults the frame's bottom delimiter to CURRENT ROW. This can cause LAST_VALUE() to return the current row's value instead of the true last value. For this reason -- & for preformance

-- clarity -- always explicitly define the frame for both FIRST_VALUE() & LAST_VALUE():

SELECT custid, orderid, val,
	FIRST_VALUE(val) OVER (PARTITION BY custid
						   ORDER BY orderdate, orderid
						   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS firstval,
	LAST_VALUE(val) OVER (PARTITION BY custid
						  ORDER BY orderdate, orderid
						  ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS lastval
FROM Sales.OrderValues
ORDER BY custid, orderdate, orderid;

-- This query returns each customer's:
	
	-- `firstval`: the value of their earliest order

	-- `lastval`: the value of their most recent order



-- As with LAG() & LEAD(), we typically use FIRST_VALUE() & LAST_VALUE() as part of a calculation rather than returning their values directly. For example, we compute the difference between the current order value & the first order value in the partition:

	-- `val - FIRST_VALUE(val) OVER (...)`

-- Or compute the difference between the current order value & the last order value in the partition:

	-- `val` - LAST_VALUE(val) OVER (...)



-- Starting with SQL Server 2022, T-SQL supports the standard NULL treatment clause with offset window functions. The syntax is:

	-- Syntax: `<function>(<expression>) [IGNORE NULLS | RESPECT NULLS] OVER (<specification>)`

-- This clause specifies whether the function should ignore or respect NULL values returned by the input expression.

	-- The RESPECT NULLS option (the default) treats NULL values as ordinary values.

	-- The IGNORE NULLS option tells the function to skip over NULL values when searching for the requested offset or boundary value.

-- In other words, when IGNORE NULLs is specified, the function continues scanning in the ordering direction until it finds a non-NULL value (if one exists). If none exists, the function returns NULL.



-- Consider the following query, which returns shipped dates for orders placed by customers 9, 20, 32, & 73 in or after 2022:

SELECT orderid, custid, orderdate, shippeddate
FROM Sales.Orders
WHERE custid IN (9, 20, 32, 73)
	AND orderdate >= '20220101'
ORDER BY custid, orderdate, orderid;

-- Orders that have not yet shipped contain a NULL value in the `shippeddate` column. Suppose we want to add a column showing the last known shipped date so far for each order (by the same customer, from 2022 onward), based on `orderdate` ordering with 

-- `orderid` as a tiebreaker. Note that the "last known shipped date at that point" is not the same as the maximum shipped date so far. For example, for customer 9, order 11076 has a last known shipped date of March 23, 2022, while the maximum shipped date

-- so far is March 24, 2022 -- we want the former. To achieve this, we can use the LAST_VALUE function with the IGNORE NULLs option:

SELECT orderid, custid, orderdate, shippeddate,
	LAST_VALUE(shippeddate) IGNORE NULLS
		OVER (PARTITION BY custid
			  ORDER BY orderdate, orderid
			  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS lastknownshippeddate
FROM Sales.Orders
WHERE custid IN (9, 20, 32, 73)
	AND orderdate >= '20220101'
ORDER BY custid, orderdate, orderid;

-- Notice that order 11074 (customer 73) gets a NULL as its last known shipped date because it's the customer's only order since 2022 & hasn't shipped yet.



-- Similarly, if we want to return the previously known shipped date for each customer, we can use the LAG() function with the IGNORE NULLS option:

SELECT orderid, custid, orderdate, shippeddate,
	LAG(shippeddate) IGNORE NULLS
		OVER (PARTITION BY custid
			  ORDER BY orderdate, orderid) AS prevknownshippeddate
FROM Sales.Orders
WHERE custid IN (9, 20, 32, 73)
	AND orderdate >= '20220101'
ORDER BY custid, orderdate, orderid;

-- For example, order 11017 for customer 20 returns April 7, 2022 as the previously known shipped date instead of NULL, thanks to the IGNORE NULLS option.



----------------------------------
-- Aggregate Window Functions
----------------------------------

-- Aggregate window functions compute aggregate values over a defined window of rows. They support window-partition, window-order, & window-frame clauses.



-- Starting with a basic example, if we use an OVER() clause with empty parentheses, the window exposed to the function includes all rows from the underlying query's result set:

SELECT orderid, custid, val,
	SUM(val) OVER () AS totalvalue,
	SUM(val) OVER (PARTITION BY custid) AS custtotalvalue
FROM Sales.OrderValues;

	-- `SUM(val) OVER ()` returns the grand total of all values, `totalvalue`.

	-- `SUM(val) OVER (PARTITION BY custid)` returns the total value for the current customer, `custtotalvalue`.

-- Each row in the result includes both the detailed order information & the relevant aggregates.



-- We can also use aggregate window functions to mix detail with calculated percentages, such as showing what percentage each order contributes to the grand total & to the customer total:

SELECT orderid, custid, val,
	100. * val / SUM(val) OVER () AS pctall,
	100. * val / SUM(val) OVER (PARTITION BY custid) AS pctcust
FROM Sales.OrderValues;

-- This query calculates, for each order, the percentage that the current order value represents out of both totals.



-- Aggregate window functions also support window frames, which allow for more sophisticated calculations such as running totals, moving averages, or YTD/MTD calculations. Consider the following example from the `Sales.EmpOrders` view:

SELECT empid, ordermonth, val,
	SUM(val) OVER (PARTITION BY empid
				   ORDER BY ordermonth
				   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS runval
FROM Sales.EmpOrders;

-- Each row in `Sales.EmpOrders` represents order activity for an employee & month. This query returns, for each employee & month:

	-- The monthly order value (`val`)

	-- The running total of values from the start of the employee's activity up to the current month

-- To achieve this:

	-- The partition is defined by `empid`, ensuring calculations are independent per employee.

	-- The ordering is based on `ordermonth`, giving temporal meaning to the frame.

	-- The frame `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` includes all rows from the start of the partition up to the current row.



-- T-SQL supports additional delimiters for the ROWS window-frame unit. For example, the frame, `ROWS BETWEEN 2 PRECEDING AND 1 FOLLOWING`, includes the two rows before the current row & 1 row after. If we don't want an upper bound, we can use

-- `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` or `ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING`, depending on the desired range.



-------------------------
-- The WINDOW Clause
-------------------------

-- The WINDOW clause allows us to name an entire window specification -- or part of one -- within a query & then reuse that name in the OVER clause of multiple window functions in the same query. It's primary purpose is to reduce repitition & make queries

-- more concise when multiple window functions share identical or similar window specifications.



-- Among the major query clauses (SELECT, FROM, WHERE, GROUP BY, HAVING, ORDER BY), the WINDOW clause appears between the HAVING & ORDER BY clauses. 



-- The following query calculates running totals, minimums, maximums, & averages for each employee & month using identical window specifications in each function:

SELECT empid, ordermonth, val,
	SUM(val) OVER (PARTITION BY empid
				   ORDER BY ordermonth
				   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS runsum,
	MIN(val) OVER (PARTITION BY empid
				   ORDER BY ordermonth
				   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS runmin,
	MAX(val) OVER (PARTITION BY empid
				   ORDER BY ordermonth
				   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS runmax,
	AVG(val) OVER (PARTITION BY empid
				   ORDER BY ordermonth
				   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS runavg
FROM Sales.EmpOrders;

-- While this works, the window specification is repeated four times -- making the query verbose & harder to maintain. We can simplify the query by defining the shared window specification once in the WINDOW clause & reusing it by name:

SELECT empid, ordermonth, val,
	SUM(val) OVER W AS runsum,
	MIN(val) OVER W AS runmin,
	MAX(val) OVER W AS runmax,
	AVG(val) OVER W AS runavg
FROM Sales.EmpOrders
WINDOW W AS (PARTITION BY empid
			 ORDER BY ordermonth
			 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW);

-- In this example, the window name `W` represents the entire window specification. When a window name refers to a complete specification (as `W` does here), it is referenced directly after OVER without parentheses.



-- As mentioned earlier, the WINDOW clause can be used not only to name an entire window specification, but also to name part of one. When using a partial window name in an OVER clause, we enclose it in parentheses, followed by any remaining windowing

-- elements we want to add. Here's an example demonstrating this:

SELECT custid, orderid, val,
	FIRST_VALUE(val) OVER (PO
						   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS firstval,
	LAST_VALUE(val) OVER (PO
						  ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS lastval
FROM Sales.OrderValues
WINDOW PO AS (PARTITION BY custid
			  ORDER BY orderdate, orderid)
ORDER BY custid, orderdate, orderid;

-- In this example:

	-- Both FIRST_VALUE & LAST_VALUE share the same partitioning & ordering definitions.

	-- However, each uses a different window frame.

-- To avoid repeating the partitioning & ordering specifications, we assign them the window name `PO`. When referencing `PO` in each function's OVER clause, we enclose it in parentheses & append the frame specification.



-- In this example, both FIRST_VALUE & LAST_VALUE functions have the same window partitioning & ordering specifications, but different window-frame specifications. So we assign the name `PO` to the combination of partitioning & ordering specifications, &

-- use this name as part of the window specifications of both functions. Since here the window name is just part of the specifications of both window functions, we do have parentheses right after the OVER clause, & within the parentheses we start with the

-- window named `PO`, followed by the explicit window-frame specification.



-- In a similar way, we can define multiple window names within the same WINDOW clause & even reuse one window name within another (recursively):

SELECT orderid, custid, orderdate, qty, val,
	ROW_NUMBER() OVER PO AS ordernum,
	MAX(orderdate) OVER P AS maxorderdate,
	SUM(qty) OVER POF AS runsumqty,
	SUM(val) OVER POF AS runsumval
FROM Sales.OrderValues
WINDOW P AS (PARTITION BY custid),
	PO AS (P ORDER BY orderdate, orderid),
	POF AS (PO ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
ORDER BY custid, orderdate, orderid;

-- In this example:

	-- `P` defines a partitioning specification (`PARTITION BY custid`).

	-- `PO` builds on `P`, adding ordering (`ORDER BY orderdate, orderid`).

	-- `POF` builds on `PO`, adding a window frame (`ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`).

-- Each window name can be reused in multiple window functions, greatly simplifying the query. Note that we define the window names within the WINDOW clause does not matter -- SQL Server resolves all window references correctly regardless of order.
