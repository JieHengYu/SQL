----------------------

-- Deleting Data

----------------------

-- T-SQL provides two primary statements for deleting rows from a table: DELETE & TRUNCATE. This section explains how each statement works & highlights the key differences between them. The examples in this section use copies of the `Sales.Customers` & 

-- `Sales.Orders` tables, created in the `dbo` schema. To set up the sample tables & data, run the following script:

USE TSQLV6;

DROP TABLE IF EXISTS dbo.Orders, dbo.Customers;

CREATE TABLE dbo.Customers (
	custid			INT				NOT NULL,
	companyname		NVARCHAR(40)	NOT NULL,
	contactname		NVARCHAR(30)	NOT NULL,
	contacttitle	NVARCHAR(30)	NOT NULL,
	address			NVARCHAR(60)	NOT NULL,
	city			NVARCHAR(15)	NOT NULL,
	region			NVARCHAR(15)	NULL,
	postalcode		NVARCHAR(10)	NULL,
	country			NVARCHAR(15)	NOT NULL,
	phone			NVARCHAR(24)	NOT NULL,
	fax				NVARCHAR(24)	NULL,
	CONSTRAINT PK_Customers PRIMARY KEY (custid)
);

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
	CONSTRAINT PK_Orders PRIMARY KEY (orderid),
	CONSTRAINT FK_Orders_Customers FOREIGN KEY (custid)
		REFERENCES dbo.Customers(custid)
);
GO

INSERT INTO dbo.Customers SELECT * FROM Sales.Customers;
INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;



----------------------------
-- The DELETE Statement
----------------------------

-- The DELETE statement is the standard command used to remove rows from a table based on an optional filter predicate. A basic DELETE statement includes two clauses:

	-- The FROM clause, which specifies the target table.

	-- The WHERE clause, which specifies the filter condition (predicate).

-- Only the rows for which the predicate evaluates to TRUE will be deleted. For example, the following statement deletes all orders placed before the year 2021 from the `dbo.Orders` table:

DELETE FROM dbo.Orders
WHERE orderdate < '20210101';

-- After executing this command, SQL Server reports that 152 rows were deleted.

SELECT * FROM dbo.Orders
ORDER BY orderdate;



-- It's important to note that DELETE operations can be expensive when removing a large number of rows. This is because DELETE is a fully logged operation -- each row deletion is recorded in the transaction log, ensuring the ability to roll back the

-- transaction if needed, but at the cost of performance.



-------------------------------
-- The TRUNCATE Statement
-------------------------------

-- The TRUNCATE statement removes all rows from a table. Unlike DELETE, it does not support a filtering predicate. For example, to delete all rows from the `dbo.T1` table, we would run:

	-- `TRUNCATE TABLE dbo.T1;`



-- The key advantage of TRUNCATE is that it is minimally logged, whereas DELETE is fully logged. This difference results in significant performance gains -- truncating a table with millions of rows can complete in seconds, while deleting the same rows

-- could take several minutes. That said, "minimally logged" does not mean "unlogged". SQL Server still records which data pages were deallocated so that the operation can be rolled back if necessary. Like DELETE, TRUNCATE is a transactional operation.



-- One important distinction arises when the target table includes an identity column:

	-- TRUNCATE resets the identity value back to its original seed.

	-- DELETE, even when executed without a filter, does not reset the identity value.

-- The SQL standard defines an optional identity restart clause for TRUNCATE, allowing us to choose whether to restart or continue the identity sequence. Unfortunately, this option is not supported in T-SQL.



-- Another key difference is that TRUNCATE cannot be executed on a table referenced by a foreign key constraint, even if:

	-- the referencing table is empty, or

	-- the foreign key is disabled.

-- To truncate such a table, we must first drop the foreign key constraints with `ALTER TABLE ... DROP CONSTRAINT`, truncate the table, & then recreate the constraints with `ALTER TABLE ... ADD CONSTRAINT`.



-- Accidents can happen -- for example, running a TRUNCATE or DROP command against a production database instead of a development one. Because both commands execute so quickly, the transaction may be committed before the mistake is realised. To guard

-- against this, one practical safety measure is to create a dummy table with a foreign key that references the table we want to protect. Even a disabled foreign key constraint will prevent that table from being truncated or dropped, with no performance

-- impact on normal operations.



-- Starting with SQL Server 2016, TRUNCATE can be applied to individual partitions within a partitioned table. We can specify a list of specific partitions or partition ranges using the PARTITIONS clause, with the keyword TO between range boundaries.

-- For example, to truncate positions 1, 3, 5, & 7 through 10 in a partitioned table named `dbo.T1`, we could use:

	-- `TRUNCATE TABLE dbo.T1 WITH (PARTITIONS(1, 3, 5, 7 TO 10));`
	


--------------------------------
-- DELETE Based on a Join
--------------------------------

-- T-SQL supports a nonstandard DELETE syntax that allows joins. In this form, the join serves both as a filtering mechanism & as a way to access attributes from related tables. This makes it possible to delete rows from one table based on conditions

-- that involve data from another table. For example, the following statement deletes all orders placed by customers located in the United States:

DELETE FROM O
FROM dbo.Orders AS O
	INNER JOIN dbo.Customers AS C
		ON O.custid = C.custid
WHERE C.country = N'USA';

-- Much like a SELECT statement, the logical processing order of a DELETE based on a join begins with the FROM clause, followed by the WHERE clause, & finally the DELETE clause. In this example:

	-- 1. SQL Server first joins the `dbo.Orders` table (aliased with `O`) with the `dbo.Customers` table (aliased as `C`) using the matching customer ID (`custid`).

	-- 2. The WHERE clause filters only those orders placed by customers whose country is `'USA'`.

	-- 3. Finally, the qualifying rows from the `O` alias -- that is, from the `dbo.Orders` table -- are deleted.



-- The presence of two FROM clauses can be confusing at first. A useful way to think about it is to develop the statement as if it were a SELECT query:

	-- 1. Start with the FROM clause (including the necessary joins).

	-- 2. Add the WHERE clause to filter the rows.

	-- 3. Finally, instead of a SELECT list, write a DELETE clause specifying the alias of the table we want to delete from.

-- Also note that the first FROM keyword in the DELETE clause is optional -- we can write either `DELETE O` or `DELETE FROM O` in this case.



-- As mentioned earlier, the DELETE-with-join syntax is nonstandard. The standard alternative is to use a subquery:

DELETE FROM dbo.Orders
WHERE EXISTS (SELECT *
			  FROM dbo.Customers AS C
			  WHERE Orders.custid = C.custid
			      AND C.country = N'USA');

-- This statement deletes all rows from `dbo.Orders` where a matching customer from the United States exists in `dbo.Customers`.



-- Internally, SQL Server processed both queries -- the join-based version & the subquery-based version -- in the same way, producing identical execution plans. Therefore, no performance difference should be expected between the two approaches. 



-- As a best practice, it's recommended to use the standard form (the subquery) unless there's a compelling reason to use the T-SQL-specific join syntax, such as a measurable performance benefit in certain scenarios.



-- When you're done experimenting with the examples, run the following code to remove the sample tables:

DROP TABLE IF EXISTS dbo.Orders, dbo.Customers;
