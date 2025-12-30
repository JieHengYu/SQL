--------------------

-- Transactions

--------------------

-- A transaction is a unit of work that can include multiple operations -- queries, data modifications, & even changes to database structure.



-- SQL Server lets us define transaction boundaries either explicitly or implicitly. We explicitly start a transaction with BEGIN TRAN (or BEGIN TRANSACTION) & explicitly end it with either:

	-- COMMIT TRAN (COMMIT TRANSACTION): to make the changes permanent

	-- ROLLBACK TRAN (ROLLBACK TRANSACTION): to undo all changes since the transaction began

-- Here's an example of an explicit transaction wrapping two INSERT statements:

	-- `BEGIN TRAN;
	--  INSERT INTO dbo.T1(keycol, col1, col2) VALUES(4, 101, 'C');
	--  INSERT INTO dbo.T2(keycol, col1, col2) VALUES(4, 201, 'X');
	--	COMMIT TRAN;`



-- If we don't explicitly define the boundaries of a transaction, SQL Server runs in auto-commit mode by default. In this mode, every individual statement is treated as its own transaction -- SQL Server automatically begins the

-- transaction before the statement runs & commits it when the statement completes. We can change this behaviour with the session-level setting IMPLICIT_TRANSACTIONS:

	-- OFF (default): auto-commit mode

	-- ON: SQL Server automatically starts a transaction when the first eligible statement runs, but we must explicitly end the transaction using COMMIT TRAN or ROLLBACK TRAN. A new implicit transaction does not begin until the

		-- previous one has been committed or rolled back.



-- After a transaction -- implicit or explicit -- commits or rolls back, SQL Server will automatically start a new implicit transaction as soon as the next statement is issued (unless another explicit transaction is already open).



-- Transactions have four key properties -- atomicity, consistency, isolation, & durability -- summarised by the acronym ACID:

	-- Atomicity: Atomicity means the transaction executes as an all-or-nothing unit of work: either all changes occur, or none do. If the system fails before the transaction completes (specifically, before the commit record is

		-- written to the transaction log), SQL Server rolls back the changes during recovery.

	-- Consistency: Consistency refers to the guarantee that a transaction moves the database from one valid, rule-compliant state to another. All integrity constraints -- primary keys, unique constraints, foreign keys, check

		-- constraints, & so on -- must remain satisfied once the transaction completes.

	-- Isolation: Isolation ensures that each transaction sees data in a consistent & stable form, even when other transactions are running at the same time. SQL Server supports two broad isolation models for disk-based tables:

		-- 1. Locking-based isolation: the traditional model & the default in on-premises SQL Server.

			-- Readers acquire shared locks.

			-- If data is currently in an inconsistent intermediate state, readers block until the data becomes consistent.

		-- 2. Row-versioning-based isolation: the default in Azure SQL Database

			-- Readers do not acquire shared locks & therefore do not wait for concurrent writers.

			-- If data is in an inconsistent intermediate state, the reader accesses an earlier, transactionally consistent version of the row.

	-- Durability: Durability means that once SQL Server acknowledges the commit, the transaction's changes are guaranteed to persist, even in the event of a crash. A commit is acknowledged when control returns to the application

		-- & the next line of code begins executing. At that point, SQL Server has persisted the commit record to durable storage.



-- As an example, the following code defines a transaction that records a new order in the `TSQLV6` database:

USE TSQLV6;

BEGIN TRAN;

DECLARE @neworderid AS INT;

INSERT INTO Sales.Orders (custid, empid, orderdate, requireddate, shippeddate, shipperid, freight, shipname, shipaddress, shipcity, shippostalcode, shipcountry)
VALUES (85, 5, '20220212', '20220301', '20220216', 3, 32.28, N'Ship to 85-B', N'6789 rue de 1''Abbaye', N'Reims', N'10345', N'France');

SET @neworderid = SCOPE_IDENTITY();

SELECT @neworderid AS neworderid;

INSERT INTO Sales.OrderDetails (orderid, productid, unitprice, qty, discount)
VALUES (@neworderid, 11, 14.00, 12, 0.000),
	   (@neworderid, 42, 9.80, 10, 0.000),
	   (@neworderid, 72, 34.80, 5, 0.000);

COMMIT TRAN;

-- This transaction inserts a new order header into `Sales.Orders` & then inserts several order-line rows into `Sales.OrderDetails`. The `orderid` value is generated automatically because the `orderid` column uses the identity 

-- property. Immediately after inserting the order header, the code captures the newly generated order ID in a local variable using SCOPE_IDENTITY, & that value is then used when inserting the related order-line rows.



-- For testing purposes, the example includes a SELECT statement that returns the newly created order ID.



-- Note that this example does not include any error handling. If an error occurs, the transaction would not roll back automatically. To properly handle failures, we can wrap the transaction in a TRY/CATCH block & explicitly

-- issue a ROLLBACK in the CATCH block.




-- When finished, run the following cleanup code to remove the test data:

DELETE FROM Sales.OrderDetails
WHERE orderid > 12078;

DELETE FROM Sales.Orders
WHERE orderid > 12078;