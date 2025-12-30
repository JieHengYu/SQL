----------------------

-- Pivoting Data

----------------------

-- Pivoting data means rotating it from a row-oriented structure into a column-oriented structure -- optionally aggregating values in the process. In many cases, pivoting is handled in the presentation layer (for example, in reports or dashboards). However,

-- there are times when we may want to perform pivoting directly within the database using T-SQL.



-- For the examples in this section, we'll use a sample table named `dbo.Orders`. Run the following script in the `TSQLV6` database to create & populate it:

USE TSQLV6;

DROP TABLE IF EXISTS dbo.Orders;

CREATE TABLE dbo.Orders (
	orderid		INT				NOT NULL
		CONSTRAINT PK_Orders PRIMARY KEY,
	orderdate	DATE			NOT NULL,
	empid		INT				NOT NULL,
	custid		VARCHAR(5)	NOT NULL,
	qty			INT			NOT NULL
);

INSERT INTO dbo.Orders (orderid, orderdate, empid, custid, qty)
VALUES 
	(30001, '20200802', 3, 'A', 10),
	(10001, '20201224', 2, 'A', 12),
	(10005, '20201224', 1, 'B', 20),
	(40001, '20210109', 2, 'A', 40),
	(10006, '20210118', 1, 'C', 14),
	(20001, '20210212', 2, 'B', 12),
	(40005, '20220212', 3, 'A', 10),
	(20002, '20220216', 1, 'C', 20),
	(30003, '20220418', 2, 'B', 15),
	(30004, '20200418', 3, 'C', 22),
	(30007, '20220907', 3, 'D', 30);

SELECT * FROM dbo.Orders;



-- Each pivoting operation involves three logical processing phases, each associated with a specific element:

	-- 1. Grouping phase: defines which rows belong together (the "on rows" element).

	-- 2. Spreading phase: defines which values become new columns (the "on columns" element).

	-- 3. Aggregating phase: defines how to summarise values within each group-column intersection (the aggregation element & function).



-- Let's walk through these phases using our sample table:

	-- 1. Grouping phase:
			
		-- We want one row per employee, so we group by `empid`.
	
	-- 2. Spreading phase:

		-- The table stores customer IDs (`custid`) in a single column. Our goal is to produce a separate result column for each unique customer, showing their total quantities. Here, `custid` is the spreading element.

	-- 3. Aggregating phase:

		-- Because pivoting implies grouping, we must aggregate the numeric values that fall into each employee-customer intersection. The aggregation element is `qty`, & the aggregation function is SUM().



-- To recap, pivoting combines three components:

	-- Group by: `empid`

	-- Spread by: `custid`

	-- Aggregate: `SUM(qty)`

-- Once we've identified these elements, creating a pivot query becomes a matter of plugging them into the appropriate positions in a generic template.



-- T-SQL supports two main approaches for pivoting data:
	
	-- 1. Using an explicit grouped query (with CASE expression & GROUP BY)

	-- 2. Using the PIVOT table operator



---------------------------------------
-- Pivoting with a Grouped Query
---------------------------------------

-- A solution that uses a grouped query handles all three pivoting phases -- grouping, spreading, & aggregation -- in an explicit & straightforward way.

	-- 1. The grouping phase is performed with a GROUP BY clause. In the following example, we group the data by employee ID (`GROUP BY empid`).

	-- 2. The spreading phase occurs in the SELECT clause, where we create a CASE expression for each target column. We must know the possible spreading element values & write a separate CASE expression for each. Because we want to "spread" the quantities of

	-- four customers (A, B, C, & D), we'll use four CASE expressions -- one for each customer. For example, the expression for customer A is `CASE WHEN custid = 'A' THEN qty END`. This expression returns the quantity from the current row only if the order 

	-- is for customer A; otherwise, it returns NULL. If a CASE expression does not include an ELSE clause, SQL Server assumes ELSE NULL by default. As a result, the column for customer A will contain quantities only for that customer, & NULL elsewhere.

	-- 3. Finally, the aggregation phase applies an aggregate function -- SUM() in this case -- to each CASE expression. For example, the column for customer A is produced with `SUM(CASE WHEN custid == 'A' THEN qty END) AS A`. Depending on the request,

	-- we can even use other aggregate functions such as MAX, MIN, or COUNT.

-- Here's a full query that pivots the order data to show total quantities for each employee (rows) & customer (columns):

SELECT empid,
	SUM(CASE WHEN custid = 'A' THEN qty END) AS A,
	SUM(CASE WHEN custid = 'B' THEN qty END) AS B,
	SUM(CASE WHEN custid = 'C' THEN qty END) AS C,
	SUM(CASE WHEN custid = 'D' THEN qty END) AS D
FROM dbo.Orders
GROUP BY empid;

-- When this query runs, SQL Server may display the following message in the "Messages" pane: "Warning: Null value is eliminated by an aggregate or other SET operations." This simply means that the aggregate functions ignore NULL values during computation.



-------------------------------------------
-- Pivoting with the PIVOT Operator
-------------------------------------------

-- The solution using an explicit grouped query is the standard way to perform pivoting. However, T-SQL also provides a proprietary table operator called PIVOT, which lets us achieve the same result more concisely. PIVOT is used in the FROM clause -- just

-- like other table operators such as JOIN. It takes a source table or table expression as its input, pivots the data & returns a result table. Although it uses less code, PIVOT still performs the same three logical phases described earlier: grouping,

-- spreading, & aggregation. Here's the general syntax:

	-- Syntax: `SELECT ...
	--          FROM <input_table>
	--          PIVOT(<agg_function>(<aggregation_elements>)
	--                FOR <spreading_element> IN (<list_of_target_columns>)) AS <result_table_alias>
	--          WHERE ...;`

-- Inside the parentheses, we specify:

	-- The aggregation function (e.g., SUM)
	
	-- The aggregation element (`qty`)

	-- The spreading element (`custid`)

	-- The list of target columns `(A, B, C, D)`

-- After the parentheses, we must provide an alias for the result table.



-- Unlike the grouped-query method, PIVOT does not require an explicit GROUP BY clause. Instead, it determines the grouping columns implicitly by elimination. The grouping elements are all columns from the input table except those used as the spreading 

-- element or aggregation element. This means the input to PIVOT should contain only the grouping, spreading, & aggregation columns. To ensure this, we typically use a table expression (such as a derived table) that includes only the necessary attributes.



-- Here's the query that uses the PIVOT operator to produce the same result as our earlier grouped-query example:

SELECT empid, A, B, C, D
FROM (SELECT empid, custid, qty
	  FROM dbo.Orders) AS D
	PIVOT(SUM(qty) for custid IN (A, B, C, D)) AS P;

-- In this query:

	-- The derived table `D` supplies only the required columns: `empid`, `custid`, & `qty`.

	-- `custid` is the spreading element.

	-- `qty` is the aggregation element.

	-- The remaining column, `empid`, is the implied grouping element.



-- If we apply the PIVOT operator directly to the `dbo.Orders` table, the results change because `dbo.Orders` contains additional columns (`orderid`, `orderdate`, etc.):

SELECT empid, A, B, C, D
FROM dbo.Orders
	PIVOT(SUM(qty) FOR custid IN (A, B, C, D)) AS P;

-- Here, `orderid`, `orderdate`, & `empid` are all treated as grouping elements. As a result, the query returns one row per order, not per employee. The logical equivalent using the grouped-query approach would be:

SELECT empid,
	SUM(CASE WHEN custid = 'A' THEN qty END) AS A,
	SUM(CASE WHEN custid = 'B' THEN qty END) AS B,
	SUM(CASE WHEN custid = 'C' THEN qty END) AS C,
	SUM(CASE WHEN custid = 'D' THEN qty END) AS D
FROM dbo.Orders
GROUP BY orderid, orderdate, empid;



-- Best practices when using the PIVOT operator include:

	-- Using a table expression as the input to the PIVOT operator. Even if our table currently has only the relevant columns, future schema changes could introduce extra columns that alter the query's behaviour.

	-- Explicitly listing columns in both the table expression (inner query) & the outer query. This helps maintain predictable results & readability.



-- Suppose we want to reverse the layout -- showing customers on rows & employees on columns. In this case:

	-- The grouping element is `custid`.

	-- The spreading element is `empid`.

	-- The aggregation remains `SUM(qty)`.

-- Here's the query:

SELECT custid, [1], [2], [3]
FROM (SELECT empid, custid, qty
	  FROM dbo.Orders) AS D
	PIVOT(SUM(qty) FOR empid IN ([1], [2], [3])) AS P;

-- Once you understand the template for a pivoting solution (whether with a grouped query or with PIVOT), it's simply a metter of pluggin the correct elements into their places.