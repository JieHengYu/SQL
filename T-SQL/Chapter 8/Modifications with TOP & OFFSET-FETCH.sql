---------------------------------------------------

-- Modifications with TOP & OFFSET-FETCH

---------------------------------------------------

-- T-SQL supports the use of the TOP option directly in INSERT, UPDATE, DELETE, & MERGE statements. When we apply TOP in a modification statement, SQL Server stops processing the operation as soon as the specified number (or percentage) of rows has been

-- affected.



-- However, unlike with the SELECT statement, modification statements do not support an ORDER BY clause when used with TOP. This means we have no control over which rows are affected -- SQL Server simply modifies whichever rows it happens to access first,

-- based on factors such as physical data layout & query optimisation choices. The OFFSET-FETCH filter, on the other hand, cannot be used directly in modification statements. This is because OFFSET-FETCH requires an ORDER BY clause, & modification 

-- statements do not allow one.



-- A common scenario for using TOP in modification statements is when performing large operations that we want to break into smaller, manageable batches -- for example, deleting a large volumne of rows in chunks to reduce looking & transaction log pressure.

-- The following example uses a table named `dbo.Orders`, created & populated as follows:

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
GO

INSERT INTO dbo.Orders 
SELECT * FROM Sales.Orders;



-- The following example demonstrates deleting 50 rows from `dbo.Orders`:

DELETE TOP(50) FROM dbo.Orders;

-- Because no ORDER BY clause is allowed, SQL Server deletes which 50 rows it accesses first. The specific rows removed depend on the data's physical storage & the optimiser's plan. Similarly, we can use TOP in an UPDATE statement:

UPDATE TOP(50) dbo.Orders
	SET freight += 10.00;

-- Again, there's no control over which 50 rows are updated -- they're simply the first rows SQL Server processes.



-- In most practical cases, we do care which rows are modified. To control this, we can take advantage of the ability to modify data throught table expressions. We can define a table expression that includes an ORDER BY clause within a SELECT TOP or

-- OFFSET-FETCH query, & then perform the modification against that table expression. For example, to delete the 50 orders with the lowest order IDs:

WITH C AS (
	SELECT TOP(50) *
	FROM dbo.Orders
	ORDER BY orderid
)
DELETE FROM C;

-- To update the 50 orders with the highest order IDs, increasing their freight by 10:

WITH C AS (
	SELECT TOP(50) *
	FROM dbo.Orders
	ORDER BY orderid DESC
)
UPDATE C
	SET freight += 10.00;

-- Alternatively, we can use the OFFSET-FETCH filter instead of TOP:

WITH C AS (
	SELECT *
	FROM dbo.Orders
	ORDER BY orderid DESC
	OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY
)
UPDATE C
	SET freight += 10.00;



-- In summary:

	-- TOP can be used directly in INSERT, UPDATE, DELETE, & MERGE statements.
	
	-- ORDER BY is not allowed directly in modification statements.

	-- OFFSET-FETCH cannot appear in modification statements because it requires ORDER BY.

	-- To control which rows are modified, define a table expression (CTE or derived table) that includes an ORDER BY with TOP or OFFSET-FETCH, & then issue the modification against that expression.