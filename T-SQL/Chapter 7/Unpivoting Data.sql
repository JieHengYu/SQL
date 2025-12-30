------------------------

-- Unpivoting Data

------------------------

-- Unpivoting is the process of rotating data from a column-based structure back into a row-based structure. In practice, this means transforming each source row into multiple result rows -- one for each column that contains related values. A common use case

-- is unpivoting data imported from a spreadsheet into a relational database, so it can be queried & manipulated more easily.



-- Run the following code to create & populate a table called `dbo.EmpCustOrders` in the `TSQLV6` sample database.

USE TSQLV6;

DROP TABLE IF EXISTS dbo.EmpCustOrders;

CREATE TABLE dbo.EmpCustOrders (
	empid INT NOT NULL
		CONSTRAINT PK_EmpCustOrders PRIMARY KEY,
		A VARCHAR(5) NULL,
		B VARCHAR(5) NULL,
		C VARCHAR(5) NULL,
		D VARCHAR(5) NULL
);

INSERT INTO dbo.EmpCustOrders (empid, A, B, C, D)
	SELECT empid, A, B, C, D
	FROM (SELECT empid, custid, qty
		  FROM dbo.Orders) AS D
		PIVOT(SUM(qty) FOR custid IN (A, B, C, D)) AS P;

SELECT * FROM dbo.EmpCustOrders;

-- The resulting table contains one row per employee, with a separate column for each of the four customers (A, B, C, & D). Each cell represents the total order quantity for a given employee -- customer combination. Intersections with no orders are

-- represented by NULL values. 



-- Now, suppose we receive a request to unpivot this data -- to return one row per employee & customer, including the order quantity if it exists. In the following sections, we'll explore two approaches to solving this problem:

	-- 1. Using the APPLY operator

	-- 2. Using the UNPIVOT operator



---------------------------------------------
-- Unpivoting with the APPLY Operator
---------------------------------------------

-- Unpivoting can be thought of as a three-phase logical process:

	-- 1. Producing copies: creating multiple versions of each source row

	-- 2. Extracting values: retrieving the relevant column values for each copy

	-- 3. Eliminating irrelevant rows: filtering out rows that don't contain useful data



-- The first step is to produce multiple copies of each source row -- one for each column we need to unpivot. In this example, that means creating a copy for each of the columns `A`, `B`, `C`, & `D`, which represent customer IDs. We can accomplish this by

-- applying a cross join between `dbo.EmpCustOrders` & a table that has one row per customer. If a customer table already exists in the database, we can use that directly. Otherwise, we can create a virtual table value constructor with the VALUE clause:

SELECT *
FROM dbo.EmpCustOrders
	CROSS JOIN (VALUES('A'), ('B'), ('C'), ('D')) AS C(custid);

-- The VALUES clause defines a set of four rows, each containing a single customer ID. We define this derived table as `C` & name its only column `custid`. The cross join produces four copies for each employee row -- one per customer (A, B, C, & D).



-- Next, we need to extract the appropriate quantity value from the original customer columns (`A`, `B`, `C`, & `D`) & return it as a single column (which we'll call `qty`). The goal is to return the quantity corresponding to the current `custid` value. For

-- instance:

	-- If `custid = 'A'`, `qty` should come from column `A`.

	-- If `custid = 'B'`, `qty` should come from column `B`, & so on.

-- You might initially think to define `qty` directly within the VALUES clause, like this:

SELECT empid, custid, qty
FROM dbo.EmpCustOrders
	CROSS JOIN (VALUES('A', A), ('B', B), ('C', C), ('D', D)) AS C(custid, qty);

-- However, this approach fails because a join treats its two inputs as independent sets. The right side of the join cannot reference columns from the left side `(A, B, C, D)`, so SQL Server raises an error.



-- The solution is to use the CROSS APPLY operator instead of CROSS JOIN. While both operators conceptually combines rows from two inputs, CROSS APPLY evaluates the left side first & then applies the right side to each left-side row. This makes columns from

-- the left side available to the right side expression -- exactly what we need. Here's the correct implementation:

SELECT empid, custid, qty
FROM dbo.EmpCustOrders
	CROSS APPLY(VALUES('A', A), ('B', B), ('C', C), ('D', D)) AS C(custid, qty);

-- This query produces one row per employee -- customer combination, returning the appropriate `qty` value for each.



-- Finally, in the original table, NULL values indicate irrelevant intersections -- cases where an employee had no orders for a customer. Typically, we don't want to include these in the result. Because the `qty` column is created in the FROM clause (via

-- CROSS APPLY), it can be referenced in the WHERE clause. We can therefore filter out irrelevant rows like this:

SELECT empid, custid, qty
FROM dbo.EmpCustOrders
	CROSS APPLY (VALUES('A', A), ('B', B), ('C', C), ('D', D)) AS C(custid, qty)
WHERE qty IS NOT NULL;

-- This final query returns only meaningful employee-customer combinations where an actual order quantity exists.



----------------------------------------------
-- Unpivoting with the UNPIVOT Operator
----------------------------------------------

-- Unpivoting data transforms multiple source columns into two result columns:

	-- one column to hold the source column names (as strings), &

	-- another to hold the source column values.

-- In this example, we'll unpivot the source columns `A`, `B`, `C`, & `D` to produce two result columns:

	-- `custid` for customer IDs (source column names)

	-- `qty` for order quantities (source column values)



-- Like the PIVOT operator, T-SQL provides an UNPIVOT operator that performs this transformation directly:

	-- Syntax: `SELECT ...
	--          FROM <input_table>
	--              UNPIVOT(<values_column> FOR <names_column> IN (<source_columns>)) AS <result_table_alias>
	--          WHERE ...;`

-- The UNPIVOT operator is a table operator, meaning it appears in the FROM clause & operates on a source table or table expression (in our case, `dbo.EmpCustOrders`). Within the parentheses of the UNPIVOT clause, we specify:

	-- the name of the values column (`qty` in this example)

	-- the name of the names column (`custid`)

	-- the list of source columns to unpivot `(A, B, C, D)`

-- Finally, we assign an alias to the resulting table produced by the operator. Here's the query that performs the unpivot:

SELECT empid, custid, qty
FROM dbo.EmpCustOrders
	UNPIVOT(qty FOR custid IN (A, B, C, D)) AS U;



-- The UNPIVOT operator performs the same logical processing phases described earlier:

	-- 1. Generating copies: one for each unpivoted column

	-- 2. Extracting values: retrieving each column's name & value

	-- 3. Eliminating NULL intersections: removing rows where the unpivoted value is NULL

-- Unlike the APPLY-based solution, the third phase (filtering out NULL rows) is not optional with UNPIVOT. The operator automatically excludes any rows where the source column value is NULL.



-- When you're done experimenting, clean up the table with:

DROP TABLE IF EXISTS dbo.EmpCustOrders;