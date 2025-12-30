-------------------

-- Outer Joins

-------------------

-- In this section, we'll cover outer joins, starting with their fundamentals & logical processing phases. We'll then discuss additional topics, including handling missing values, filtering columns from the non-preserved side, using outer joins in multi-join

-- queries, & applying the COUNT function with outer joins.



------------------------------
-- Outer Joins, Described
------------------------------

-- Outer joins were introduced in SQL-92 &, unliked inner joins & cross joins, have a single standard syntax: the JOIN keywrod is specified between table names, & the join condition is defined in the ON clause. Outer joins perform the same two logical 

-- processing phases as inner joins -- Cartesian product & ON filter -- plus a third, unique phase called "Adding Outer Rows".



-- In an outer join, a table is marked as preserved using one the keywords LEFT OUTER JOIN, RIGHT OUTER JOIN, or FULL OUTER JOIN (the OUTER keyword is optional).

	-- LEFT preserves all rows from the table on the left side of the JOIN.

	-- RIGHT preserves all rows from the table on the right side.

	-- FULL preserves rows from both tables.

-- The third logical phase identifies rows in the preserved table that have no matching rows in the other table based on the ON predicate. These rows are added to the result set produced by the first two phases, with NULL values used as placeholders for the 

-- attributes from the non-preserved side.



-- A helpful way to understand outer joins is with an example. The following query performs a left outer join between the `Sales.Customers` & `Sales.Orders` tables, matching customers to orders based on `custid`. Because it is a left outer join, the query 

-- returns all customers, including those who have not placed any orders:

USE TSQLV6;

SELECT C.custid, C.companyname, O.orderid
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
		ON C.custid = O.custid;



-- Two customers in the `Sales.Customers` table -- IDs 22 & 57 -- did not place nay orders. In the query output, both customers appear with NULL values for the `O.orderid` column from the `Sales.Orders` table.



-- It can be helpful to think of the result of an outer join as containing two types of rows with respect to the preserved table: inner rows & outer rows.

	-- Inner rows are those that find matching rows on the other side based on the ON predicate.

	-- Outer rows are those that do not have matches on the other side.

-- An inner join returns only inner rows, whereas an outer join returns both inner & outer rows.



-- A common source of confusion with outer joins is whether a predicate should be specified in the ON clause or the WHERE clause.

	-- The ON predicate determines how rows from the preserved side are matched with rows from the non-preserved side. It is not final, meaning it does not control whether a row from the preserved table will appear in the output -- it only controls matching.

	-- The WHERE clause is applied after the outer rows have been produced. Predicates in the WHERE clause are final filters, determining which rows actually appear in the result set.

-- In short, use the ON clause for non-final matching predicates & use the WHERE predicate for final, filtering predicates that apply after all outer rows have been added.



-- Suppose we want to return only customers who did not place any orders -- in other words, we want to return only outer rows. We can build on the previous query by adding a WHERE clause that filters for outer rows. Outer rows can be identified by NULL values 

-- from the non-preserved side of the join. Therefore, we can filter for rows where one of these columns is NULL, as in the following query:

SELECT C.custid, C.companyname
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
		ON C.custid = O.custid
WHERE O.orderid IS NULL;

-- A few important points about this query:

	-- 1. Use IS NULL, not the equality operator (=): Comparisons with NULL using the equality operator always return UNKNOWN, even when comparing two NULL values. 

	-- 2. Choose the correct column to test for NULL: Only columns that can be NULL exclusively for outer rows should be used for filtering. Safe choices include:

		-- Primary key columns: These cannot be NULL in the base table, so a NULL indicates an outer row.

		-- Join columns: If a row has no match, the join column from the non-preserved side will be NULL.

		-- Columns defined as NOT NULL: A NULL value here also indicates an outer row.

-- By using a column that meets one of these criteria, we can reliably filter for outer rows without affecting inner rows.



---------------------------------
-- Including Missing Values
---------------------------------

-- Outer joins can be used to identify & include missing values when querying data. For example, suppose we want to query all orders from the `Sales.Orders` table & ensure that every date in the range January 1, 2020 through Decemeber 31, 2022 appears at least

-- once in the output. We do not need to do anything special for dates that already have orders, but for dates with no orders, we want NULL values as placeholders for the order attributes.



-- To solve this, we first generate a sequence of all dates in the requested range & then perform a left outer join with the `Sales.Orders` table. This ensures that dates with no orders are included in the result. To create a data sequence, we can use an 

-- auxiliary numbers table. For example, the `TSQLV6` database includes a table called `dbo.Nums` with a column `n` containing a sequence of integers (1, 2, 3, ...). We can generate the sequence of dates by taking the first `n` numbers from `dbo.Nums`, where 

-- `n` is the number of days in the requested range. Using DATEADD, we add `n - 1` days to the start date (`'20200101'`) to produce each date:

SELECT DATEADD(day, n - 1, CAST('20200101' AS DATE)) AS orderdate
FROM dbo.Nums
WHERE n <= DATEDIFF(day, '20200101', '20221231') + 1
ORDER BY orderdate;

-- Next, we extend this query to include a left outer join with the `Sales.Orders` table using the generated dates:

SELECT DATEADD(day, dbo.Nums.n - 1, CAST('20200101' AS DATE)) AS orderdate,
	O.orderid, O.custid, O.empid
FROM dbo.Nums
	LEFT OUTER JOIN Sales.Orders AS O
		ON DATEADD(day, dbo.Nums.n - 1, CAST('20200101' AS DATE)) = O.orderdate
WHERE dbo.Nums.n <= DATEDIFF(day, '20200101', '20221231') + 1
ORDER BY orderdate;

-- In this query, dates that do not appear in the `Sales.Orders` table appear in the output with NULL values for the order attributes.



-- Note that starting with SQL Server 2022, the same result can be achieved more easily using the GENERATE_SERIES function instead of an auxiliary numbers table.



------------------------------------------------------------------------------------------
-- Filtering Attributes from the Nonpreserved Side of an Outer Join
------------------------------------------------------------------------------------------

-- When reviewing code that uses outer joins, one important area to examine is the WHERE clause. If a predicate in the WHERE clause references an attribute from the non-preserved side of the join using a standard comparison (e.g., `<attribute> <operator> 

-- <value>`), it often indicates a bug. This happens because attributes from the non-preserved side are NULL in outer rows. Any comparison of the form `NULL <operator> <value>` evaluates to UNKNOWN (except for special cases like IS NULL or 

-- IS [NOT] DISTINCT FROM). Since the WHERE clause filters out UNKNOWN results, all outer rows are eliminated. As a result, the outer join behaves like an inner join. For example, consider the following query:

SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
		ON C.custid = O.custid
WHERE O.orderdate >= '20220101';

-- The query performs a left outer join between the `Sales.Customers` & `Sales.Orders` tables. Before the WHERE filter is applied, the join returns both inner rows (customers who placed orders) & outer rows (customers who did not), with NULL values in the 

-- order attributes for outer rows. The predicate `O.orderdate >= '20220101'` in the WHERE clause evaluates to UNKNOWN for all outer rows because `O.orderdate` is NULL for those rows. Since the WHERE clause filters out UNKNOWN values, all outer rows are

-- eliminated from the result. The outer join effectively behaves like an inner join, & customers without orders are not returned. This indicates a logical mistake: the programmer either chose the wrong join type or placed the predicate in the WHERE clause

-- instead of the ON clause.



----------------------------------------------------------
-- Using Outer Joins in a Multi-Join Query
----------------------------------------------------------

-- Recall the discussion of all-at-once operations, which refers to the idea that all expressions within the same logical query processing phases are evaluated together, at the same point in time. However, this concept does not apply to the processing of table

-- operators in the FROM phase. Table operators are logically evaluated in the order they are written. Rearranging the order of outer joins can produce different results, so their evaluation order cannot be changed arbitrarily.



-- Some common bugs arise from the logical order in which outer joins are processed. A typical scenario involves a multi-join query where an outer join between two tables is followed by an inner join with a third table. If the ON clause of the subsequent join

-- compares an attribute from the non-preserved side of the outer join with an attribute from the third table, all outer rows are discarded. This happens because outer rows contain NULL values in the non-preserved columns, & any comparison with NULL evaluates

-- UNKNOWN. The ON filter then eliminates these rows, effectively nullifying the outer join & turning it into an inner join. For example:

SELECT C.custid, O.orderid, OD.productid, OD.qty
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
		ON C.custid = O.custid
	INNER JOIN Sales.OrderDetails AS OD
		ON O.orderid = OD.orderid;

-- In general, outer rows are dropped whenever any outer join (left, right, or full) is followed by a subsequent inner join or right outer join -- assuming the join condition compares NULLs from the outer row with values from the other table.



-- There are several ways to handle this problem if we want to include customers with no orders in the output. One approach is to use a left outer join for the second join as well: 

SELECT C.custid, O.orderid, OD.productid, OD.qty
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
		ON C.custid = O.custid
	LEFT OUTER JOIN Sales.OrderDetails AS OD
		ON O.orderid = OD.orderid;

-- With this approach, the outer rows produced by the first join are preserved. However, this solution is often not ideal, because it also preserved all rows from `Sales.Orders`. If some orders do not have matching rows in `Sales.OrderDetails`, & we want to 

-- exclude them, this query would keep those orders. In that case, what we want is an inner join between `Sales.Orders` & `Sales.OrderDetails`.



-- A second approach is to use an inner join between `Sales.Orders` & `Sales.OrderDetails`, & then join the result with the `Sales.Customers` table using a right outer join:

SELECT C.custid, O.orderid, OD.productid, OD.qty
FROM Sales.Orders AS O
	INNER JOIN Sales.OrderDetails AS OD
		ON O.orderid = OD.orderid
	RIGHT OUTER JOIN Sales.Customers AS C
		ON O.custid = C.custid;

-- In this setup, the outer rows are produced by the final join, so customers with no orders are preserved & not filtered out.



-- A third option is to treat the inner join between `Sales.Orders` & `Sales.OrderDetails` as a separate unit, & then perform a left outer join between `Sales.Customers` & that unit. While not strictly required, it is recommended to use parentheses to clearly

-- encapsulate the inner join. The query would look like this:

SELECT C.custid, O.orderid, OD.productid, OD.qty
FROM Sales.Customers AS C
	LEFT OUTER JOIN (
		Sales.Orders AS O
			INNER JOIN Sales.OrderDetails AS OD
				ON O.orderid = OD.orderid
	) ON C.custid = O.custid;

-- This approach effectively nests one join within another. In fact, this technique is often referred to in the SQL community as nested joins.



----------------------------------------------------------
-- Using the COUNT Aggregate with Outer Joins
----------------------------------------------------------

-- Another common issue arises when using COUNT with outer joins. When we group the result of an outer join & use `COUNT(*)`, the aggregate counts all rows, including both inner rows & outer rows. Often, however, we want to count only rows that represent 

-- actual data from the non-preserved side of the join. For example, the following query is intended to return the number of orders per customer:

SELECT C.custid, COUNT(*) AS numorders
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
		ON C.custid = O.custid
GROUP BY C.custid;

-- In this query, customers such as 22 & 57 -- who have not placed any orders -- each have an outer row in the join result. As a result, they appear in the output with a count of 1, which is misleading.



-- The reason is that `COUNT(*)` counts all rows, regardless of whether they contain actual order data. To fix this, we should use `COUNT(<column>)`, specifying a column from the non-preserved side of the join. Outer rows have NULL in such columns, so they are

-- ignored by the aggregate. A safe choice is a column that can only be NULL for outer rows, such as the primary key `orderid`:

SELECT C.custid, COUNT(O.orderid) AS numorders
FROM Sales.Customers AS C
	LEFT OUTER JOIN Sales.Orders AS O
		ON C.custid = O.custid
GROUP BY C.custid;

-- Now, customers 22 & 57 appear with a count of 0, accurately reflecting that they have no orders.








