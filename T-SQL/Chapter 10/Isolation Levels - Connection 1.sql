-------------------------

-- Isolation Levels

-------------------------

-- Isolation levels determine the degree of data consistency a session receives when reading or modifying data. Under SQL Server's default isolation level in the box product, readers acquire shared (S) locks, & writers acquire

-- exclusive (X) locks. We cannot change the locking behaviour of writers directly, but we can control the locking behaviour of readers -- &, indirectly, influence overall concurrency -- by choosing an appropriate isolation

-- level.



-- Isolation levels can be set:

	-- At the session level:

		-- `SET TRANSACTION ISOLATION LEVEL <isolation_level>`
	
	-- At the query level, using table hints:
		
		-- `SELECT ... FROM <table> WITH (<isolation_level>);`

-- Session settings use spaces in multi-word names (e.g., REPEATABLE READ), whereas query hints do not (REPEATABLEREAD). Some hint names also have synonyms -- for example, NOLOCK is equivalent to READUNCOMMITTED, & HOLDLOCK is

-- equivalent to SERIALIZABLE.



-- SQL Server supports six isolation levels, divided into two categories:

	-- 1. Locking-based isolation levels:

		-- READ UNCOMMITTED

		-- READ COMMITTED (default for SQL Server on-premises box product)

		-- REPEATABLE READ

		-- SERIALIZABLE

	-- 2. Row versioning-based isolation levels:

		-- SNAPSHOT

		-- READ COMMITTED SNAPSHOT (default in Azure SQL DB)

-- SNAPSHOT & READ COMMITTED SNAPSHOT are conceptually the row-versioning counterparts of SERIALIZABLE & READ COMMITTED, respectively. Some texts group READ COMMITTED & READ COMMITTED SNAPSHOT as a single isolation level with two

-- different implementations -- locking-based & versioning-based.



-- Changing the isolation level affects both data consistency & concurrency:

	-- For the four locking-based levels, increasing the isolation level increases consistency but decreases concurrency. Higher isolation levels require stricter & longer-held locks.

	-- Under the two versioning-based levels, SQL Server maintains previous committed row versions in the version store in `tempdb`. Readers do not acquire shared locks & therefore do not block writers. If the current row version 

		-- is not appropriate for the reader, SQL Server returns a suitable older version instead.



-- The following sections describe each of the six isolation levels in detail & illustrate their behaviour with examples.



-----------------------------------------------
-- The READ UNCOMMITTED Isolation Level
-----------------------------------------------

-- READ UNCOMMITTED is the lowest isolation level supported by SQL Server. Under this isolation level, a reader does not request shared (S) locks. Because shared locks are not taken, the reader can never conflict with a writer

-- holding an exclusive (X) lock. As a result:

	-- The reader can return uncommitted changes made by other transactions (also known as dirty reads).

	-- The reader does not block writers, & writers do not block the reader.

	-- A writer can modify data at the same time the READ UNCOMMITTED reader is reading it.

-- This isolation level offers maximum concurrency by the lowest consistency guarantees.



-- To observe a daily read in action, open two query windows (referred to below as Connection 1 & Connection 2). Ensure both use the `TSQLV6` sample database & that nothing else is running on the instance. In Connection 1, start

-- a transaction, update the unitprice of product 2, & then query the modified row:

USE TSQLV6; -- (Connection 1)

BEGIN TRAN;

UPDATE Production.Products
	SET unitprice += 1.00
WHERE productid = 2;

SELECT productid, unitprice
FROM Production.Products
WHERE productid = 2;

-- The transaction remains open, so the row is held exclusively locked by Connection 1. In connection 2, set the isolation level to READ UNCOMMITTED & query the same row:

	-- `SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;`

	-- `SELECT productid, unitprice
	--	FROM Production.Products
	--	WHERE productid = 2;`

-- Because the reader did not request a shared lock, it did not conflict with the exclusive lock held by Connection 1. The query returns the new unit price (20.00), even though the change is still uncommitted.



-- Back in Connection 1, roll back the open transaction:

ROLLBACK TRAN;

-- The rollback restores the price to its original value (19.00). The value read earlier by Connection 2 (20.00) was never committed. This is the classic example of a dirty read -- data is read that may later be undone.



-------------------------------------------
-- The READ COMMITTED Isolation Level
-------------------------------------------

-- To prevent readers from accessing uncommitted changes, we need to use a stronger isolation level. The lowest isolation level that avoids dirty readers is READ COMMITTED, which is also the default isolation level in SQL Server. 

-- As the name indicates, this isolation level ensures that readers see only committed data.



-- READ COMMITTED prevents dirty reads by requiring readers to acquire shared (S) locks. If a writer holds an exclusive (X) lock on the target resource, the shared lock request is incompatible, & the reader must wait. Once the

-- writer commits & releases the exclusve lock, the reader can obtain its shared lock & read the committed state.



-- The following steps show that under READ COMMITTED, a reader can only access committed data. In Connection 1, start a transaction, update the price of product 2 & query the row:

BEGIN TRAN;

UPDATE Production.Products
SET unitprice += 1.00
WHERE productid = 2;

SELECT productid, unitprice
FROM Production.Products
WHERE productid = 2;

-- Connection 1 now holds an exclusive lock on product 2's row. In Connection 2, set the isolation level to READ COMMITTED (optional, since this is the default) & attempt to read the same row:

	-- `SET TRANSACTION ISOLATION LEVEL READ COMMITTED;`

	-- `SELECT productid, unitprice
	--	FROM Production.Products
	--	WHERE productid = 2;`

-- Because the reader must acquire a shared lock -- that lock conflicts with the exclusive lock held by Connection 1 -- the SELECT statement blocks.



-- Back in Connection 1, commit the open transaction:

COMMIT TRAN;

-- Once the exclusive lock is released, Connection 2's blocked SELECT completes & returns the committed value.



-- In READ COMMITTED, shared locks acquired by readers are short-lived:

	-- A reader holds the shared lock only for the time needed to read the resource.

	-- The lock is released before the statement finishes executing.

	-- No shared lock is held for the remainder of the transaction.

-- Because shared locks are released so quickly, another transaction can modify the same data between two reads within the same transaction. This can lead to nonrepeatable reads (reading different committed values for the same

-- row in the same transaction), also known as inconsistent analysis. Many applications tolerate this behaviour, but some require stronger isolation levels to avoid it.



-- After completing the test, reset product 2's price:

UPDATE Production.Products
	SET unitprice = 19.00
WHERE productid = 2;

-- Also, ensure that all open transactions in both sessions are properly committed or rolled back.



----------------------------------------------
-- The REPEATABLE READ Isolation Level
----------------------------------------------

-- If we want to ensure that no other transaction can modify data between multiple reads occurring within the same transaction, we need to move to the REPEATABLE READ isolation level. In this isolation level:

	-- Readers stil acquire shared (S) locks.

	-- Shared locks are held until the end of the transaction, not just for the duration of the statement.

-- This means that once a reader acquires a shared lock on a resource, no other transaction can obtain an exclusive lock to modify that resource until the reader commits or rolls back. This guarantees repeatable reads -- the

-- reader will see the same values every time it queries the data during the transaction.



-- To demonstrate repeatable reads, in Connection 1, set the session's isolation level to REPEATABLE READ, start a transaction, & read product 2:

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ; -- (Connection 1)

BEGIN TRAN;

SELECT productid, unitprice
FROM Production.Products
WHERE productid = 2;

-- Because REPEATABLE READ holds shared locks until the end of the transaction, Connection 1 now retains a shared lock on the row for product 2. In Connection 2, attempt to modify the same row:

	-- `UPDATE Production.Products
	--		SET unitprice += 1.00
	--	WHERE productid = 2;`Anote

-- The update attempt blocks. The writer requires an exclusive lock, but that lock is incompatible with the shared lock held by Connection 1. Under lower isolation levels such as READ COMMITTED, the shared lock would already have

-- been released, & the UPDATE would succeed.



-- Return to Connection 1, read the row again, & commit the transaction:

SELECT productid, unitprice -- (Connection 1)
FROM Production.Products
WHERE productid = 2;

COMMIT TRAN;

-- The second read returns the same value as the first, demonstrating repeatable reads. Once the transaction commits & releases the shared lock, the blocked update in Connection 2 acquires the exclusive lock & completes.



-- REPEATABLE READ also prevents the lost update anomaly. A lost update occurs when:

	-- 1. Two transactions read the same value.

	-- 2. Each calculates a new value based on what it read.

	-- 3. Each attempts to write back its updated value.

-- Under weaker isolation levels (READ COMMITTED, READ UNCOMMITTED), neither transaction holds a lock after reading, so both the UPDATE statements can proceed, & the last writer overwrites the other's work. Under REPEATABLE READ,

-- each transaction keeps its shared lock after reading. Because both readers retain shared locks, neither can later obtain an exclusive lock to issue an UPDATE. The conflict causes a deadlock, which prevents the lost update

-- scenario.



-- Run the following code to restore the original value:

UPDATE Production.Products
	SET unitprice = 19.00
WHERE productid = 2;



-------------------------------------------
-- The SERIALIZABLE Isolation Level
-------------------------------------------

-- While REPEATABLE READ ensures that rows already read cannot be modified by other transactions, it does not prevent the appearance of new rows in the same query range -- these are called phantom rows, & reading them constitutes

-- a phantom read. Phantom reads occur when another transaction inserts new rows that satisfy the query filter between two reads in the same transaction.



-- To prevent phantom reads, we use the SERIALIZABLE isolation level. This level behaves similarly to REPEATABLE READ in that:

	-- Readers acquire shared (S) locks.

	-- Locks are held until the end of the transaction.

-- The difference is that SERIALIZABLE also locks the entire key range that qualifies for the query's filter. This prevents other transactions from inserting rows that would satisfy the reader's query condition, effectively

-- eliminating phantom reads.



-- To demonstrate the SERIALIZABLE isolation level, in Connection 1, set the session's isolation level to SERIALIZABLE, start a transaction, & query all products in category 1:

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE; -- (Connection 1)

BEGIN TRAN;

SELECT productid, productname, categoryid, unitprice
FROM Production.Products
WHERE categoryid = 1;

-- Connection 1 now holds shared locks on all existing rows in the range & locks the range itself, preventing new qualifying rows from being inserted. In Connection 2, attempt to insert a new product with `categoryid = 1`:

	-- `INSERT INTO Production.Products (productname, supplierid, categoryid, unitprice, discontinued)
	--	VALUES ('Product ABCDE', 1, 1, 20.00, 0);`

-- The insert is blocked. In lower isolation levels, this insertion would succeed. Under SERIALIZABLE, the key-range lock held by Connection 1 prevents phantom rows. Back in Connection 1, query the products in category 1 again

-- & commit:

SELECT productid, productname, categoryid, unitprice
FROM Production.Products
WHERE categoryid = 1;

COMMIT TRAN;

-- The second read returns the same set of rows as the first read, with no phantom rows. After committing, the key-range locks are released. Connection 2 can now complete the blocked insert & commit. A subsequent query in a new

-- transaction will reflect the newly inserted row:

SELECT productid, productname, categoryid, unitprice
FROM Production.Products
WHERE categoryid = 1;



-- Run the following code to restore the original table:

DELETE FROM Production.Products
WHERE productid > 77;

-- Run the following code to reset the isolation level in all connections:

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;



----------------------------------------------------
-- Isolation Levels Based on Row Versioning
----------------------------------------------------

-- With row-versioning technology, SQL Server can store previous versions of committed rows in a version store. The location of the version store depends on the database configuration:

	-- If Accelerated Database Recovery (ADR) is not enabled, the version store resides in the `tempdb` database.

	-- If ADR is enabled, the version store resides in the user database itself.

-- SQL Server supports two isolation levels that rely on row versioning:

	-- 1. SNAPSHOT: logically similar to SERIALIZABLE, providing a high level of consistency.

	-- 2. READ COMMITTED SNAPSHOT: similar to READ COMMITTED, providing committed-only reads without blocking.

-- Unlike locking-based isolation levels, readers in row-versioning-based isolation levels:

	-- Do not acquire shared (S) locks.

	-- Do not block writers, & writers do not block readers.

	-- Always see a consistent version of the data. If the current row version is not the one the reader should see, SQL Server returns an older committed version from the version store.



-- How versioning affects DML operations:

	-- DELETE & UPDATE operations must copy the original row version to the version store before making changes.

	-- INSERT operations do not write to the version store, since no previous version exists.

-- Enabling row-versioning-based isolation levels can impact performance:

	-- Writes (UPDATE/DELETE) may become slightly slower due to versioning overhead.

	-- Reads usually improve, sometimes dramatically, because readers do not wait for locks & can access the appropriate row version immediately.



--------------------------------------
-- The SNAPSHOT Isolation Level
--------------------------------------

-- Under the SNAPSHOT isolation level, a transaction always sees the last committed version of a row that was available when the transaction started. This guarantees:

	-- Committed reads

	-- Repeatable reads

	-- No phantom reads

-- just as in the SERIALIZABLE isolation level. The difference is that SNAPSHOT achieves this without using shared locks, relying entirely on row versioning.



-- Row versioning introduces a performance overhead, especially for UPDATE & DELETE operations, because the original row version must be copied to the version store. To use SNAPSHOT isolation in a SQL Server box product (enabled

-- by default in Azure SQL Database), we must enable it at the database level:

ALTER DATABASE TSQLV6 SET ALLOW_SNAPSHOT_ISOLATION ON;



-- To demonstrate the SNAPSHOT isolation level, modify a row in `Production.Products` in Connection 1:

BEGIN TRAN; -- (Connection 1)

UPDATE Production.Products
	SET unitprice += 1.00
WHERE productid = 2;

SELECT productid, unitprice
FROM Production.Products
WHERE productid = 2;

-- The output shows the updated price 20.00. Even though Connection 1 may be running under READ COMMITTED, SQL Server stores the original row version (price = 19.00) in the version store because SNAPSHOT isolation is enabled at 

-- the database level. Read the row in Connection 2 using SNAPSHOT isolation:

	-- `SET TRANSACTION ISOLATION LEVEL SNAPSHOT;`

	-- `BEGIN TRAN;`

	-- `SELECT productid, unitprice
	--  FROM Production.Products
	--  WHERE productid = 2;`

-- The transaction sees the last committed version available when it started (price = 19.00). Unlike SERIALIZABLE, this query does not block, even though Connection 1 holds an exclusive lock.



-- Commit the modifying transaction in Connection 1:

COMMIT TRAN;

-- At this point, the current version of the row is 20.00. If Connection 2 reads again within the same transaction, it still sees 19.00, because SNAPSHOT isolation always provides a consistent view from the start of the

-- transaction:

	-- `SELECT productid, unitprice
	--  FROM Production.Products
	--  WHERE productid = 2;`

	-- `COMMIT TRAN;`

-- Start a new transaction in Connection 2 & read the row:

	-- `BEGIN TRAN;`

	-- `SELECT productid, unitprice
	--	FROM Production.Products
	--	WHERE productid = 2;`

	-- `COMMIT TRAN;`

-- The new transaction now sees the current committed version (price = 20.00). Once no transactions reference the older version (price = 19.00), SQL Server's cleanup thread can remove it from the version store. Note that very

-- long transactions can prevent cleanup & cause the version store to grow significantly.



-- Run the following code to restore the original value:

UPDATE Production.Products
	SET unitprice = 19.00
WHERE productid = 2;



---------------------------
-- Conflict Detection
---------------------------

-- Under the SNAPSHOT isolation level, SQL Server prevents lost updates, just as REPEATABLE READ & SERIALIZABLE do. However, the enforcement mechanism is different.

	-- REPEATABLE READ & SERIALIZABLE prevent lost updates by holding locks. If two transactions attempt conflicting updates, SQL Server may resolve the situation by generating a deadlock, & one transaction is chosen as the

		-- deadlock victim.

	-- SNAPSHOT, however, uses row versioning rather than locks to guarantee consistent reads. Because of this, it can detect the specific case where a transaction attempts to update data that has changed since it was read. When

		-- that happens, SQL Server raises a specific update conflict error, not a general deadlock error.

-- This makes SNAPSHOT particularly useful when we want precise detection & handling of update conflicts.



-- The following example demonstrates a scenario with no update conflict, followed by an example of a scenario with an update conflict. Run the following code in Connection 1 to enable SNAPSHOT for the session, start a

-- transaction, & read product 2:

SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

BEGIN TRAN;

SELECT productid, unitprice
FROM Production.Products
WHERE productid = 2;

-- Assume we perform some calculations based on the value read. Then, update the price to 20.00 & commit:

UPDATE Production.Products
	SET unitprice = 20.00
WHERE productid = 2;

COMMIT TRAN;

-- No other transactions modified the row between the read & write, so SQL Server allows the update with no conflict. Reset the price:

UPDATE Production.Products
	SET unitprice = 19.00
WHERE productid = 2;

-- Next, as an example of a scenario with an update conflict, run the following code in Connection 1, again, to start a new transaction & read product 2:

BEGIN TRAN;

SELECT productid, unitprice
FROM Production.Products
WHERE productid = 2;

-- The value returned is 19.00. From Connection 2, update the row to a different value:

	-- `UPDATE Production.Products
	--		SET unitprice = 25.00
	--  WHERE productid = 2;`

-- Back in Connection 1, attempt to update the same row based on the earlier read.

UPDATE Production.Products
	SET unitprice = 20.00
WHERE productid = 2;

-- Because the data changed after Connection 1 read it, SNAPSHOT detects the conflict & aborts the transaction with an error such as: "Snapshot isolation transaction aborted due to update conflict. You cannot use snapshot 

-- isolation to access table 'Production.Products' directly or indirectly in database 'TSQLV6' to update, delete, or insert the row that has been modified or deleted by another transaction. Retry the transaction or change the 

-- isolation level for the update/delete statement."



-- Unlike REPEATABLE or SERIALIZABLE, this is not a deadlock -- it's a targeted update conflict error. In real applications, we can catch this error & retry the transaction. 



-- Restore the original values:

UPDATE Production.Products
	SET unitprice = 19.00
WHERE productid = 2;

-- Close all open connections. If any session remains active -- especially one holding a SNAPSHOT transaction -- the results of the following section may differ because old versions cannot yet be cleaned up.



-----------------------------------------------------
-- The READ COMMITTED SNAPSHOT Isolation Level
-----------------------------------------------------

-- The READ COMMITTED SNAPSHOT isolation level is also based on row versioning, but it differs from SNAPSHOT in an important way:

	-- SNAPSHOT provides a transactional-level consistent view.

	-- READ COMMITTED SNAPSHOT provides a statement-level consistent view.

-- In other words, each statement sees the last committed version of each row as the moment the statement begins -- not as of when the transaction begins. READ COMMITTED SNAPSHOT does not detect update conflicts. This means the

-- logical behaviour is similar to standard READ COMMITTED, except:

	-- readers do not acquire shared locks

	-- readers do not block writers

	-- readers do not wait if the requested rows are exclusively locked

-- If, under READ COMMITTED SNAPSHOT, we do want a reader to acquire shared locks, we must use the table hint READCOMMITEDLOCK, for example:

	-- `SELECT * 
	--  FROM dbo.T1 WITH (READCOMMITTEDLOCK)`.



-- In the SQL Server box product (where it is not enabled by default), we must enable the READ_COMMITTED_SNAPSHOT option at the database level:

ALTER DATABASE TSQLV6 SET READ_COMMITTED_SNAPSHOT ON;

-- Exclusive access to the database is required for this operation. A key point -- Enabling this flag changes the semantics of the READ COMMITTED isolation level. After turning it on, standard READ COMMITTED behaves as 

-- READ COMMITTED SNAPSHOT unless the session explicitly selects a different isolation level.



-- To demonstrate statement-level consistency under the READ COMMITTED SNAPSHOT isolation level, open two connections. In Connection 1, start a transaction, update product 2, & read it:

USE TSQLV6;

BEGIN TRAN;

UPDATE Production.Products
	SET unitprice += 1.00
WHERE productid = 2;

SELECT productid, unitprice
FROM Production.Products
WHERE productid = 2;

-- The output shows the new value (20.00). The transaction remains open. In Connection 2, start a transaction & read product 2:

	-- `BEGIN TRAN;`

	-- `SELECT productid, unitprice
	--	FROM Production.Products
	--  WHERE productid = 2;`

-- Even though Connection 1 is holding an exclusive lock, this SELECT does not block. READ COMMITTED SNAPSHOT provides the last committed version at the start of the statement, 19.00.



-- Commit the transaction in Connection 1:

COMMIT TRAN;

-- In Connection 2, read the row again, & commit:

	-- `SELECT productid, unitprice
	--	FROM Production.Products
	--  WHERE productid = 2;`

	-- `COMMIT TRAN;`

-- This time, the value returned is 20.00. Under SNAPSHOT, the second read would have returned 19.00 because SNAPSHOT guarantees transaction-level consistency. But READ COMMITTED SNAPSHOT guarantees only statement-level

-- consistency, so the statement sees the latest committed version available when it starts. This behaviour is an example of a nonrepeatable read (or inconsistent analysis).



-- Reset the price for cleanup:

UPDATE Production.Products
	SET unitprice = 19.00
WHERE productid = 2;

-- Close all open connections. To disable row-versioning-based isolation levels, open a new connection, & run the following code:

	-- ALTER DATABASE TSQLV6 SET ALLOW_SNAPSHOT_ISOLATION OFF;
	-- ALTER DATABASE TSQLV6 SET READ_COMMITTED_SNAPSHOT OFF;



-----------------------------------
-- Summary of Isolation Levels
-----------------------------------

-- The table below summarises which logical consistency anomalies are possible in each isolation level. It also indicates whether the isolation level performs automatic update-conflict detection & whether it relies on row

-- versioning.

-- | Isolation Level | Allows      | Allows        | Allows lost | Allows  | Detects update | Uses row    |
-- |                 | uncommitted | nonrepeatable | updates?    | phantom | conflicts?     | versioning? |
-- |                 | reads?      | reads?        |             | reads?  |                |             |
-- | --------------- | ----------- | ------------- | ----------- | ------- | -------------- | ----------- |
-- | READ            | Yes         | Yes           | Yes         | Yes     | No             | No          |
-- | UNCOMMITTED     |             |               |             |         |                |             |
-- | --------------- | ----------- | ------------- | ----------- | ------- | -------------- | ----------- |
-- | READ COMMITTED  | No          | Yes           | Yes         | Yes     | No             | No          |
-- | --------------- | ----------- | ------------- | ----------- | ------- | -------------- | ----------- |
-- | READ COMMITTED  | No          | Yes           | Yes         | Yes     | No             | Yes         |
-- | SNAPSHOT        |             |               |             |         |                |             |
-- | --------------- | ----------- | ------------- | ----------- | ------- | -------------- | ----------- |
-- | REPEATABLE READ | No          | No            | No          | Yes     | No             | No          |
-- | --------------- | ----------- | ------------- | ----------- | ------- | -------------- | ----------- |
-- | SERIALIZE       | No          | No            | No          | No      | No             | No          |
-- | --------------- | ----------- | ------------- | ----------- | ------- | -------------- | ----------- |
-- | SNAPSHOT        | No          | No            | No          | No      | Yes            | Yes         |
-- | --------------- | ----------- | ------------- | ----------- | ------- | -------------- | ----------- |



-- Legend of anomalies:

	-- Uncommitted reads: Reading data modified by a transaction that has not yet committed (dirty reads)

	-- Nonrepeatable reads: Re-reading a row & getting a different value because another transaction modified it

	-- Lost updates: Two concurrent updates overwrite each other without detection

	-- Phantom reads: Re-running a query & seeing new or missing rows because another transaction inserted or deleted data
