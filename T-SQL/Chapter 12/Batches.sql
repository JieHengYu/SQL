---------------

-- Batches

---------------

-- A batch is one or more T-SQL statements sent by a client application to SQL Server for execution as a single unit. SQL Server processes the entire batch through parsing (syntax checking), resolution & binding (verifying the

-- existence of referenced objects & columns, & checking permissions), & optimisation as a single unit.



-- Batches should not be confused with transactions. A transaction is an atomic unit of work, meaning that it either completes entirely or has no effect at all. A batch, by contrast, can contain multiple transactions, & a single

-- transaction can be submitted in parts across multiple batches.



-- If a transaction is cancelled or rolled back, SQL Server reverses all changes made since the beginning of the transaction, regardless of where the batch boundaries occur.



-- Client application programming interfaces (APIs) such as ADO.NET, provide methods for submitting batches of T-SQL code to SQL Server for execution. SQL Server client utilities, such as SQL Server Management Studio (SSMS),

-- Azure Data Student (DS), SQL CMD, & OSQL, also allow users to submit batches interactively. These tools provide a client-side command called GO to signal the end of a batch. It is important to note that GO is not a T-SQL

-- command & is not recognised by SQL Server itself; instead, it is intepreted by the client tool, which then sends the preceding statements to SQL Server as a single batch. Unlike T-SQL statements, which should be terminated

-- with a semicolon as a best practice, the GO command is not terminated with a semicolon, as that is not part of its syntax.



--------------------------------------
-- A Batch as a Unit of Parsing
--------------------------------------

-- A batch is a set of T-SQL statements that SQL Server parses & executes as a single unit. SQL Server first parses the entire batch to check for syntax errors. If parsing succeeds, SQL Server then attempts to execute the batch.

-- If a batch contains a syntax error, the entire batch fails parsing & is not submitted to SQL Server for execution. However, this failure affects only the batch that contains the error; other batches in the script are processed

-- independently. For example, the following script contains three batches. The second batch includes a syntax error (FOM instead of FROM) in the second query:

PRINT 'First batch'; -- (Valid batch)
USE TSQLV6;
GO

PRINT 'Second batch'; -- (Invalid batch)
SELECT custid FROM Sales.Customers;
SELECT orderid FOM Sales.Orders;
GO

PRINT 'Third batch'; -- (Valid batch)
SELECT empid FROM HR.Employees;

-- Because the second batch contains a syntax error, that entire batch is not submitted to SQL Server for execution. The first & third batches pass syntax validation & are therefore submitted & executed successfully.



----------------------------
-- Batches & Variables
----------------------------

-- A variable is local to the batch in which it is declared. If we attempt to reference a variable outside the batch in which it was defined, SQL Server raises an error indicating that the variable is not declared. For example,

-- the following script declares a variable & prints its value in one batch, & then attempts to reference the same variable in the subsequent batch:

DECLARE @i AS INT;
SET @i = 10;
PRINT @i; -- (Successful)
GO       

PRINT @i; -- (Fails)

-- The reference to the variable in the first PRINT statement is valid because it appears in the same batch in which the variable was declared. The second reference appears in a different batch, so the variable is out of scope.

-- As a result, the first PRINT statement outputs the value 10, while the second produces an error.



---------------------------------------------------------------------
-- Statements That Cannot Be Combined in the Same Batch
---------------------------------------------------------------------

-- Certain T-SQL statements must appear as the first statement in a batch & therefore cannot be combined with other statements in the same batch. These include:

	-- CREATE DEFAULT

	-- CREATE FUNCTION

	-- CREATE PROCEDURE

	-- CREATE RULE

	-- CREATE SCHEMA

	-- CREATE TRIGGER

	-- CREATE VIEW

-- For example, the following script places a DROP VIEW statement before a CREATE VIEW statement in the same batch, which makes the batch invalid:

DROP VIEW IF EXISTS Sales.MyView;

CREATE VIEW Sales.MyView
AS
SELECT YEAR(orderdate) AS orderyear, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY YEAR(orderdate);
GO

-- Running this code produces the following error: "'CREATE VIEW' must be the first statement in a query batch." To resolve this issue, separate the DROP VIEW & CREATE VIEW statements into different batches by inserting a GO 

-- command after the DROP VIEW statement.



------------------------------------------
-- A Batch as a Unit of Resolution
------------------------------------------

-- A batch is a unit of resolution (also known as binding). This means that SQL Server checks the existence of referenced objects & columns at the batch level. For this reason, it is important to carefully design batch boundaries.



-- If we apply schema changes to an object & then attempt to manipulate or query that object within the same batch, SQL Server may not yet recognise the schema changes. As a result, the data-manipulation statement can fail during

-- the resolution phase with a binding error. The following example demonstrates this behaviour. First, run the following code to create a table named `dbo.T1` in the current database with a single column, `col1`:

DROP TABLE IF EXISTS dbo.T1;
CREATE TABLE dbo.T1(col1 INT);

-- Next, attempt to add a new column named `col2` & then query it within the same batch:

ALTER TABLE dbo.T1 ADD col2 INT;
SELECT col1, col2 FROM dbo.T1;

-- Although this code appears valid, the batch fails during the resolution phase with the following error: "Invalid column name 'col2'." At the time the SELECT statement is resolved, SQL Server still sees `dbo.T1` as having only

-- one column (`col1`). As a result, the reference to `col2` causes a resolution error. A best practice to avoid this issue is to separate data definition language (DDL) statements from data manipulation language (DML) by placing

-- them in different batches, as shown below:

ALTER TABLE dbo.T1 ADD col2 INT;
GO
SELECT col1, col2 FROM dbo.T1;



-----------------------
-- The GO n Option
-----------------------

-- The GO command is not a T-SQL statement; rather, it is a command recognised by SQL Server client tools -- such as SQL Server Management Studio (SSMS) -- to indicate the end of a batch. Because GO is handled by the client tool

-- & not by SQL Server itself, it can also accept arguments that control how the batch is submitted. One such argument specifies the number of times the preceding batch should be executed. To see how GO with an argument works, 

-- first create a table named `dbo.T1` using the following code:

DROP TABLE IF EXISTS dbo.T1;
CREATE TABLE dbo.T1(col1 INT IDENTITY);

-- The `col1` column automatically generates values using the IDENTITY property. (This demonstration would work equally well if a default constraint were used to generate values from a sequence object.) Next, suppress the default

-- informational messages produced by DML statements that report the number of rows affected:

SET NOCOUNT ON;

-- Finally, define a batch that inserts a row using DEFAULT VALUES, & execute that batch 100 times by supplying an argument to GO:

INSERT INTO dbo.T1 DEFAULT VALUES;
GO 100

SELECT * FROM dbo.T1;

-- The final SELECT statement returns 100 rows, with `col1` containing the values 1 through 100.

