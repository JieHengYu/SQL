---------------------

-- Grouping Sets

---------------------

-- A grouping set is a collection of expressions by which data is grouped in a query that includes a GROUP BY clause. The term set emphasizes that the order of the grouping expressions doesn't matter -- only their combination. Traditionally, each grouped

-- query defines a single grouping set. For example, each of the following four queries defines a different grouping set:

USE TSQLV6;

SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid, custid;

SELECT empid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid, custid;

SELECT custid, SUM(qty) AS sumqty
FROM dbo.Orders	
GROUP BY custid;

SELECT SUM(qty) AS sumqty
FROM dbo.Orders;

	-- The first query defines the grouping set `(empid, custid)`.

	-- The second defines `(empid)`.

	-- The third defines `(custid)`.

	-- The fourth defines the empty grouping set () (which aggregates the entire table into one row).

-- Each query returns a separate result set, one per grouping level.



-- Suppose that, for reporting purposes, we want to see all grouping levels in a single unified result set -- instead of running multiple queries separately. One straightforward way to achieve this is to use UNION ALL to combine the results of each query,

-- inserting NULL placeholders for columns that don't appear in certain grouping levels:

SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid, custid

UNION ALL

SELECT empid, NULL, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY empid, custid

UNION ALL

SELECT NULL, custid, SUM(qty) AS sumqty
FROM dbo.Orders	
GROUP BY custid

UNION ALL

SELECT NULL, NULL, SUM(qty) AS sumqty
FROM dbo.Orders;

-- While this approach produces the desired unified output, it has two major drawbacks:

	-- 1. Length & complexity: the code is long & repetitive.

	-- 2. Performance: SQL Server must rescan the source data for each SELECT statement.



-- To simplify & optimises this process, T-SQL supports several standard extensions that allow use to define multiple grouping sets within a single query. These include:

	-- The GROUPING SETS, CUBE, & ROLLUP subclauses of the GROUP BY clause

	-- The GROUPING & GROUPING_ID functions

-- These features are particularly useful in reporting & data analysis, where different aggregation levels are required in the same result set.



-- Because these queries often produce hierarchical or multi-level summarise, the presentation layer typically needs more advanced display controls than a simple data grid -- for example, pivot tables or collapsible hierarchies.



-------------------------------------
-- The GROUPING SETS Subclause
-------------------------------------

-- The GROUPING SETS subclause is a powerful enhancement to the GROUP BY that allows us to define multiple grouping sets within a single query. We specify the desired grouping sets inside parentheses, separated by commas. Each grouping set itself is enclosed

-- in its own parentheses & lists the grouping expressions it includes, also separated by commas. For example, the following query defines four grouping sets `(empid, custid)`, (`empid`), (`custid`), & ():

SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY
	GROUPING SETS(
		(empid, custid),
		(empid),
		(custid),
		()
	);

-- The last grouping set (), is the empty grouping set, which represents the grand total across all rows. This query is logically equivalent to the earlier UNION ALL example that combined four separate grouped queries. However, the GROUPING SETS approach

-- is much shorter & more efficient. SQL Server can optimise this query by performing fewer data scans than the number of grouping sets, since it can compute multiple aggregation levels in a single pass through the data.



--------------------------
-- The CUBE Subclause
--------------------------

-- The CUBE subclause of the GROUP BY clause provides a concise way to define multiple grouping sets. Within the parentheses of the CUBE subclause, we specify a list of grouping columns separated by commas. SQL Server then automatically generates all 

-- possible combinations of those columns as grouping sets. For example, the following expressions are equivalent:

	-- `CUBE(a, b, c)` = `GROUP SETS((a, b, c), (a, b), (b, c), (a), (b), (c), ())`

-- In set theory terms, the CUBE subclause produces the power set -- that is, the set of all possible subsets -- of the specified grouping columns.



-- Instead of explicitly listing the four grouping sets `(empid, custid)`, (`empid`), (`custid`), & (), we can use the much shorter equivalent `CUBE(empid, custid)`:

SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);

-- This single query returns the same unified result set as before, but with cleaner syntax & better maintainability.



----------------------------
-- The ROLLUP Subclause
----------------------------

-- The ROLLUP subclause of the GROUP BY clause provides another shorthand method for defining multiple grouping sets. Unlike the CUBE subclause, which produces all possible combinations of the specified columns, ROLLUP assumes a hierarchical relationship

-- among its input columns. It generates only those grouping sets that represent progressively higher levels of aggregation along that hierarchy. For example:

	-- `CUBE(a, b, c)` produces 8 grouping sets (all possible combiantions).

	-- `ROLLUP(a, b, c)` produces only 4, based on the implied hierarchy a > b > c.

-- In other words, `ROLLUP(a, b, c)` is equivalent to `GROUPING SETS((a, b, c), (a, b), (a), ())`.



-- Suppose that we want to compute total quantities across different levels of a time hierarchy:

	-- by year,

	-- by year & month

	-- by year, month, & day

	-- a grand total

-- We could define these grouping sets explicitly using the GROUPING SETS subclause:

	-- `GROUPING SETS(
	--  (YEAR(orderdate), MONTH(orderdate), DAY(orderdate)),
	--  (YEAR(orderdate), MONTH(orderdate)),
	--  (YEAR(orderdate)),
	--  ())`

-- However, the same logic can be expressed much more concisely using ROLLUP:

SELECT YEAR(orderdate) AS orderyear,
	MONTH(orderdate) AS ordermonth,
	DAY(orderdate) AS orderday,
	SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY ROLLUP(YEAR(orderdate), MONTH(orderdate), DAY(orderdate));

-- This query returns subtotals at each level of the date hierarchy (date, month, year) & a final grand total, all in a single unified result set.



------------------------------------------------
-- The GROUPING & GROUPING_ID Functions
------------------------------------------------

-- When a query defines multiple grouping sets, we often need a way to identify which result rows belong to which grouping set. As long as all grouping columns are defined as NOT NULL, this is straightforward. For example:

SELECT empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);

-- Because both `empid` & `custid` are defined as NOT NULL in the `dbo.Orders` table, any NULL values that appear in the result set can only be placeholders, indicating that the column did not participate in the current grouping set.

	-- Rows where both `empid` & `custid` are not NULL correspond to the grouping set `(empid, custid)`.

	-- Rows where `empid` is NOT NULL & `custid` is NULL correspond to (`empid`).

	-- Rows where `empid` is NULL & `custid` is NOT NULL correspond to (`custid`).

	-- Rows where both are NULL correspond to the grand total ().



-- If any of the grouping columns allow NULLs in the base table, we can no longer tell whether a NULL in the result came from the data itself or is a placeholder. To solve this, we use the GROUPING() function. `GROUPING(<column_name>)` returns:

	-- `0` if the column is part of the current grouping set (a detail element), &

	-- `1` if the column is not part of the current grouping set (an aggregate element).

-- For example:

SELECT GROUPING(empid) AS grpemp,
	GROUPING(custid) AS grpcust,
	empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);

-- Now we can use the `grpemp` & `grpcust` indicators instead of relying on NULLs:

	-- `(grpemp, grpcust) = (0, 0)` -> `(empid, custid)`

	-- `(0, 1)` -> (`empid`)

	-- `(1, 0)` -> (`custid`)

	-- `(1, 1)` -> ()



-- The GROUPING_ID function provides a more compact way to identify grouping sets. It accepts all grouping elements as input -- for example, `GROUPING_ID(a, b, c, d)` -- & returns an integer bitmap where each bit represents whether a corresponding column

-- is aggregated (`1`) or detailed (`0`). The rightmost input column corresponds to the rightmost bit in the binary value. For instance:

	-- `(a, b, c, d)` -> binary 0000 -> integer 0

	-- `(a, c)` -> binary 0101 -> integer 5

-- This makes it easy to map result rows to their grouping sets using a single numeric value:

SELECT GROUPING_ID(empid, custid) AS groupingset,
	empid, custid, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY CUBE(empid, custid);

-- In this case:

	-- 0 (binary 0000) -> `(empid, custid)`

	-- 1 (binary 0001) -> (`empid`)

	-- 2 (binary 0010) -> (`custid`)

	-- 3 (binary 0011) -> ()



-- Using GROUPING & GROUPING_ID together gives us a precise & efficient way to distinguish between detail, subtotal, & grand total rows when working with queries that produce multiple grouping sets via CUBE, ROLLUP, & GROUPING SETS.

