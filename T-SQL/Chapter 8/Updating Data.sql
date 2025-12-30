-----------------------

-- Updating Data

-----------------------

-- T-SQL supports the standard UPDATE statement, which is used to modify existing rows in a table. In addition to the standard form, T-SQL also supports several nonstandard variants, including UPDATE statements that use joins & variables. This section 

-- describes the different forms of the UPDATE statement & demonstrates their usage with practical examples.



-- Some of the examples in this section use copies of the `Sales.Orders` & `Sales.OrderDetails` tables, recreated in the `dbo` schema. Run the following code to create & populate these tables:

USE TSQLV6;

DROP TABLE IF EXISTS dbo.OrderDetails, dbo.Orders;

CREATE TABLE dbo.Orders (
	orderid			INT				NOT NULL,
	custid			INT				NULL,
	empid			INT				NOT NULL,
	orderdate		DATE			NOT NULL,
	requireddate	DATE			NOT NULL,
	shippeddate		DATE			NULL,
	shipperid		INT				NOT NULL,
	freight			MONEY			NOT NULL
		CONSTRAINT DFT_Orders_freight DEFAULT(0),
	shipname		NVARCHAR(40)	NOT NULL,
	shipaddress		NVARCHAR(60)	NOT NULL,
	shipcity		NVARCHAR(15)	NOT NULL,
	shipregion		NVARCHAR(15)	NULL,
	shippostalcode	NVARCHAR(10)	NULL,
	shipcountry		NVARCHAR(15)	NOT NULL,
	CONSTRAINT PK_Orders PRIMARY KEY (orderid)
);

CREATE TABLE dbo.OrderDetails (
	orderid			INT				NOT NULL,
	productid		INT				NOT NULL,
	unitprice		MONEY			NOT NULL
		CONSTRAINT DFT_OrderDetails_unitprice DEFAULT(0),
	qty				SMALLINT		NOT NULL
		CONSTRAINT DFT_OrderDetails_qty DEFAULT(1),
	discount		NUMERIC(4, 3)	NOT NULL
		CONSTRAINT DFT_OrderDetails_discount DEFAULT(0),
	CONSTRAINT PK_OrderDetails PRIMARY KEY (orderid, productid),
	CONSTRAINT FK_OrderDetails FOREIGN KEY (orderid)
		REFERENCES dbo.Orders(orderid),
	CONSTRAINT CHK_discount CHECK (discount BETWEEN 0 AND 1),
	CONSTRAINT CHK_qty CHECK (qty > 0),
	CONSTRAINT CHK_unitprice CHECK (unitprice >= 0)
);
GO

INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;
INSERT INTO dbo.OrderDetails SELECT * FROM Sales.OrderDetails;



-- Other examples use two sample tables, `dbo.T1` & `dbo.T2`. Run the following code to create & populate these tables:

DROP TABLE IF EXISTS dbo.T1, dbo.T2;

CREATE TABLE dbo.T1 (
	keycol	INT			NOT NULL
		CONSTRAINT PK_T1 PRIMARY KEY,
	col1	INT			NOT NULL,
	col2	INT			NOT NULL,
	col3	INT			NOT NULL,
	col4	VARCHAR(10)	NOT NULL
);

CREATE TABLE dbo.T2 (
	keycol	INT			NOT NULL
		CONSTRAINT PK_T2 PRIMARY KEY,
	col1	INT			NOT NULL,
	col2	INT			NOT NULL,
	col3	INT			NOT NULL,
	col4	VARCHAR(10)	NOT NULL
);
GO

INSERT INTO dbo.T1(keycol, col1, col2, col3, col4)
VALUES (2, 10, 5, 30, 'D'),
	   (3, 40, 15, 20, 'A'),
	   (5, 17, 60, 12, 'B');

INSERT INTO dbo.T2(keycol, col1, col2, col3, col4)
VALUES (3, 200, 32, 11, 'ABC'),
	   (5, 400, 43, 10, 'ABC'),
	   (7, 600, 54, 90, 'XYZ');
	


-----------------------------
-- The UPDATE Statement
-----------------------------

-- The UPDATE statement is a standard SQL command used to modify existing rows in a table. Typically, we update only a subset of rows, identified by a condition in the WHERE clause. The column assignments are defined in the SET clause, with each

-- assignment separated by commas. For example, the following statement increases the discount of all order details for product 51 by five percent:

UPDATE dbo.OrderDetails
	SET discount = discount + 0.05
WHERE productid = 51;

-- We can run a SELECT query before & after executing the UPDATE to verify the changes:

SELECT * FROM dbo.OrderDetails;



-- T-SQL supports compound assignment operators, which provide a shorthand form for updating column values. Common operators include += (add & assign), -= (subtract & assign), *= (multiply & assign), /= (divide & assign), & %= (modulo & assign). Using a 

-- compound operator, the previous example can be rewritten as:

UPDATE dbo.OrderDetails
	SET discount += 0.05
WHERE productid = 51;

SELECT * FROM dbo.OrderDetails;

-- This expression is equivalent to `discount = discount + 0.05`, but more concise.



-- A key concept in SQL updates is that all assignments in the same logical phase are evaluated as a set, meaning all expressions are computed based on the same original row values. In other words, column assignments in an UPDATE statement occur all at

-- once, not sequentially from left to right. Consider the following example:

UPDATE dbo.T1
	SET col1 = col1 + 10, 
		col2 = col1 + 10;

-- Suppose a row in `dbo.T1` has `col1 = 100` before the update. At first glance, it might seem that `col1` will be updated to 110 & then `col2` to 120. However, because both assignments are evaluated simultaneously, both use the original value of `col1`

-- (100). As a result, after the update, both `col1` & `col2` will have the value 110.

SELECT * FROM dbo.T1;



-- The all-at-once behaviour also means that we can perform operations that would normally require a temporary variable in procedural languages. For example, to swap the values of `col1` & `col2`, we can simply write:

UPDATE dbo.T1
	SET col1 = col2, 
		col2 = col1;

-- Both assignments reference the original values of `col1` & `col2` before the update, so there's no need for an intermediate variable. This is a direct consequence of SQL's set-based, all-at-once evaluation model.



-------------------------------
-- UPDATE Based on a Join
-------------------------------

-- Similar to the DELETE statement, the UPDATE statement in T-SQL also supports a nonstandard form based on joins. As with joined DELETE statements, the join serves two purposes:

	-- 1. It filters the rows to be updated.

	-- 2. It provides access to columns from related tables that can be used in the update.

-- The syntax is similar to that of a SELECT statement that uses a join. The FROM & WHERE clauses work the same way, but instead of a SELECT clause, we specify an UPDATE clause. The UPDATE keyword is followed by the alias of the target table -- the one

-- whose rows will actually be updated. Note that we can update only one table per statement. The following example increases the discount by 5 percent for all order details belonging to orders placed by customer 1:

UPDATE OD
	SET discount += 0.05
FROM dbo.OrderDetails AS OD
	INNER JOIN dbo.Orders AS O
		ON OD.orderid = O.orderid -- (Sample query 8-1)
WHERE O.custid = 1;



-- In terms of logical processing, the statement works as follows:

	-- 1. The FROM clause forms the joined table between `dbo.OrderDetails` (aliased as `OD`) & `dbo.Orders` (aliased as `O`).

	-- 2. The WHERE clause filters the joined rows to include only those where `O.custid = 1`.

	-- 3. The UPDATE clause identifies `OD` as the target table & increases its `discount` by 5 percent.

-- If you prefer, you can specify the full table name (`dbo.OrderDetails`) instead of the alias after UPDATE.



-- The same task can be expressed using standard SQL by using a subquery instead of a join:

UPDATE dbo.OrderDetails
	SET discount += 0.05
WHERE EXISTS
	(SELECT * FROM dbo.Orders AS O
	 WHERE O.orderid = OrderDetails.orderid
		AND O.custid = 1);

-- Here, the WHERE clause filters only those order details where a related order exists for customer 1. For this particular task, SQL Server produces the same execution plan for both versions, so there should be no performance difference. As a best

-- practice, use standard SQL syntax unless there's a strong reason to use the T-SQL specific join form.



-- There are cases where the join form of UPDATE is more convenient or efficient. In addition to filtering, the join allows us to reference attributes from other tables directly in the SET clause. With the subquery approach, we would need one subquery per

-- column assignment -- & potentially separate subqueries for filtering -- which results in multiple accessories to the same table. For example, consider the following nonstandard UPDATE statement that uses a join:

UPDATE dbo.T1
	SET col1 = T2.col1,
		col2 = T2.col2,
		col3 = T2.col3
FROM dbo.T1 FULL OUTER JOIN dbo.T2
	ON T1.keycol = T2.keycol
WHERE T2.col4 = 'ABC';

-- This statement joins `dbo.T1` & `dbo.T2` on matching key columns (`keycol`). The WHERE clause filters rows where `T2.col4 = 'ABC'`. The UPDATE clause identifies `dbo.T1` as the target table & assigns it `col1`, `col2`, & `col3` columns the corresponding

-- values from `dbo.T2`.



-- An equivalent query using standard SQL syntax with subqueries would look like this:

UPDATE dbo.T1
	SET col1 = (SELECT col1 FROM dbo.T2
				WHERE T1.keycol = T2.keycol),
		col2 = (SELECT col2 FROM dbo.T2
				WHERE T1.keycol = T2.keycol),
		col3 = (SELECT col3 FROM dbo.T2
				WHERE T1.keycol = T2.keycol)
WHERE EXISTS
	(SELECT * FROM dbo.T2
	 WHERE T1.keycol = T2.keycol
		AND T2.col4 = 'ABC');

-- This version is clearly more verbose. Each subquery independently accesses `dbo.T2`, making it less efficient than the join-based form, which accesses the joined table only once.



-- When you're finished experimenting with this example, you can remove the sample tables with the following statement:

DROP TABLE IF EXISTS dbo.T1, dbo.T2;



-------------------------
-- Assignment UPDATE
-------------------------

-- T-SQL supports a proprietary form of the UPDATE statement that allows us to both update data in a table & assign values to variables at the same time. This syntax eliminates the need to use separate UPDATE & SELECT statements to accomplish the same task.



-- A common use case for this syntax is maintaining a custom sequence or autonumbering mechanism in scenarios where the IDENTITY property or the SEQUENCE object isn't suitable. For example, suppose we need to guarantee that no gaps appear in the sequence 

-- of numbers -- something that IDENTITY or SEQUENCE cannot guarantee if transactions roll back. In such cases, we could store the last used value in a table &, whenever we need a new value, use the special UPDATE syntax to both increment the stored value 

-- & assign it to a variable in a single step.



-- The following code creates a table named `dbo.MySeqeunces` with a column `val`, then inserts a single row initialised to 0 -- one less than the first value we want to use.

DROP TABLE IF EXISTS dbo.MySequences;

CREATE TABLE dbo.MySequences (
	id	VARCHAR(10)	NOT NULL
		CONSTRAINT PK_MySequences PRIMARY KEY (id),
	val	INT			NOT NULL
);

INSERT INTO dbo.MySequences VALUES('SEQ1', 0);

-- To obtain the next value in the sequence, run the following code:

DECLARE @nextval AS INT;

UPDATE dbo.MySequences
	SET @nextval = val += 1
WHERE id = 'SEQ1';

SELECT @nextval;

-- Here's what happens:

	-- 1. A local variable `@nextval` is declared.

	-- 2. The UPDATE statement increments the column `val` by 1 & assigns the new value to the variable `@nextval`. 

	-- 3. Finally, the SELECT statement returns the variable's value.

-- In logical terms, `val` is first updated to `val + 1`, & then that result (`val + 1`) is assigned to `@nextval`.



-- This special UPDATE syntax runs as part of a single transaction & is generally more efficient than using separate UPDATE & SELECT statements, because it accesses the target table only once. However, not an important distinction:

	-- The data modification is transactional -- if the transaction rolls back, the update to the table is undone.

	-- The variable assignment is not transactional -- if the transaction rolls back after the assignment, the variable's value remains changed.



-- When you're finished, remove the sample table with the following statement:

DROP TABLE IF EXISTS dbo.MySequences;
