----------------

-- Exercises

----------------

-- This section provides exercises to help us familiarise ourselves with the subjects discussed in this lesson. For all exercises in this lesson, make sure to be connected to the `TSQLV6` sample database by running the following

-- code:

USE TSQLV6;



-----------------
-- Exercise 1
-----------------

-- Exercises 1-1 through 1-6 deal with blocking. They assume we're using the isolation level READ COMMITTED (locking). Remember that this is the default isolation level in a SQL Server box product. To perform these exercises on 

-- Azure SQL Database, we need to turn versioning off.



------------------
-- Exercise 1-1
------------------

-- Open three connections in SQL Server Management Studio. This exercise will refer to them as Connection 1, Connection 2, & Connection 3. Run the following code in Connection 1 to open a transaction & update the rows in

-- `Sales.OrderDetails`:

BEGIN TRAN; -- (Connection 1)

UPDATE Sales.OrderDetails
	SET discount = 0.05
WHERE orderid = 10249;



------------------
-- Exercise 1-2
------------------

-- Run the following code in Connection 2 to query `Sales.OrderDetails`. Connection 2 will be blocked:

	-- `SELECT orderid, productid, unitprice, qty, discount -- (Connection 2)
	--  FROM Sales.OrderDetails
	--  WHERE orderid = 10249;`



------------------
-- Exercise 1-3
------------------

-- Run the following code in Connection 3, & identify the locks & session IDs involved in the blocking chain:

	-- `SELECT request_session_id AS sid, -- (Connection 3)
	--		resource_type AS restype,
	--		resource_database_id AS dbid,
	--		resource_description AS res,
	--		resource_associated_entity_id AS resid,
	--		request_mode AS mode,
	--		request_status AS status
	--  FROM sys.dm_tran_locks;`



------------------
-- Exercise 1-4
------------------

-- Replace the session IDs with the ones you found involved in the blocking chain in the previous exercise. Run the following code to obtain connection, session, & blocking information about the processes involved in the blocking

-- chain:

-- Connection Info
-- `SELECT session_id AS sid, -- (Connection 3)
--		connect_time,
--		last_read,
--		last_write,
--		most_recent_sql_handle
-- FROM sys.dm_exec_connections
-- WHERE session_id IN(63, 62);`

-- Session Info:
-- `SELECT session_id AS sid,
--		login_time,
--		host_name,
--		program_name,
--		login_name,
--		nt_user_name,
--		last_request_start_time,
--		last_request_end_time
-- FROM sys.dm_exec_sessions
-- WHERE session_id IN (63, 62);`

-- Blocking Info:
-- `SELECT session_id AS sid,
--		blocking_session_id,
--		command,
--		sql_handle,
--		database_id,
--		wait_type,
--		wait_time,
--		wait_resource
-- FROM sys.dm_exec_requests
-- WHERE blocking_session_id > 0;`



------------------
-- Exercise 1-5
------------------

-- Run the following code to obtain the SQL text of the connections involved in the blocking chain:

-- `SELECT session_id, text -- (Connection 3)
--  FROM sys.dm_exec_connections
--		CROSS APPLY sys.dm_exec_sql_text(most_recent_sql_handle) AS ST
--  WHERE session_id IN (62, 63);`



------------------
-- Exercise 1-6
------------------

-- Run the following code in Connection 1 to roll back the transaction:

ROLLBACK TRAN;



-- Observe in Connection 2 that the SELECT query returned the two order detail rows, & that those rows were not modified -- namely, their discounts remain 0.00. Remember that if we need to terminate the blocker's transaction,

-- we can use the KILL command. Close all connections.



-----------------
-- Exercise 2
-----------------

-- Exercise 2-1 through 2-6 deal with isolation levels.



------------------
-- Exercise 2-1
------------------

-- In this exercise, we'll practice using the READ UNCOMMITTED isolation level. Open two new connections. This exercise will refer to them as Connection 1 & Connetion 2. As a reminder, make sure that we're connected to the sample

-- database `TSQLV6`. Run the following code in Connection 1 to open a transaction, update rows in `Sales.OrderDetails`, & query it:

BEGIN TRAN; -- (Connection 1)

UPDATE Sales.OrderDetails
	SET discount += 0.05
WHERE orderid = 10249;

SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails
WHERE orderid = 10249;



-- Run the following code in Connnection 2 to set the isolation level to READ UNCOMMITTED & query `Sales.OrderDetails`:

	-- `SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;` -- (Connection 2)

	-- `SELECT orderid, productid, unitprice, qty, discount
	--  FROM Sales.OrderDetails
	--  WHERE orderid = 10249;`

-- Notice that you get the modified, uncommitted version of the rows.



-- Run the following code in Connection 1 to rollback the transaction:

ROLLBACK TRAN;



------------------
-- Exercise 2-2
------------------

-- In this exercise, we'll practice using the READ COMMITTED isolation level. Run the following in Connection 1 to open a tranasction, update rows in `Sales.OrderDetails`, & query it:

BEGIN TRAN; -- (Connection 1)

UPDATE Sales.OrderDetails
	SET discount += 0.05
WHERE orderid = 10249;

SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails
WHERE orderid = 10249;



-- Run the following code in Connection 2 to set the isolation level to READ COMMITTED & query `Sales.OrderDetails`:

	-- `SET TRANSACTION ISOLATION LEVEL READ COMMITTED;` -- (Connection 2)

	-- `SELECT orderid, productid, unitprice, qty, discount
	--  FROM Sales.OrderDetails
	--  WHERE orderid = 10249;`

-- Notice that we're now blocked.



-- Run the following code in Connection 1 to commit the transaction:

COMMIT TRAN;

-- Go to Connection 2 & notice that we get the modified, committed version of the rows.



-- Run the following code for cleanup:

UPDATE Sales.OrderDetails
	SET discount = 0.00
WHERE orderid = 10249;



-------------------
-- Exercise 2-3
-------------------

-- In this exercise, we'll practice using the REPEATABLE READ isolation level. Run the following code in Connection 1 to set the isolation level to REPEATABLE READ, open a transaction, & read data from `Sales.OrderDetails`:

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ; -- (Connection 1)

BEGIN TRAN;

SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails
WHERE orderid = 10249;

-- We get two rows with discount values of 0.00.



-- Run the following code in Connection 2, & notice that you're blocked:

	-- `UPDATE Sales.OrderDetails -- (Connection 2)
	--		SET discount += 0.05
	--	WHERE orderid = 10249;`



-- Run the following code in Connection 1 to read the data again & commit the transaction:

SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails
WHERE orderid = 10249;

COMMIT TRAN;

-- We get two rows with discount values of 0.00 again, giving us repeatable reads. Note that if our code was running under a lower isolation level (such as READ UNCOMMITTED or READ COMMITTED), the UPDATE statement wouldn't be

-- blocked & we would get nonrepeatable reads.



-- Go to Connection 2 & notice the update has finished.



-- Run the following code for cleanup:

UPDATE Sales.OrderDetails
	SET discount = 0.00
WHERE orderid = 10249;



-------------------
-- Exercise 2-4
-------------------

-- In this exercise, we'll practice using the SERIALIZABLE isolation level. Run the following code in Connection 1 to set the isolation level to SERIALIZABLE & query `Sales.OrderDetails`:

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE; -- (Connection 1)

BEGIN TRAN;

SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails
WHERE orderid = 10249;



-- Run the following code in Connection 2 to attempt to insert a row to `Sales.OrderDetails` with the same order ID that is filtered by the previous query, & notice that we're blocked:

-- `INSERT INTO Sales.OrderDetails (orderid, productid, unitprice, qty, discount) -- (Connection 2)
--  VALUES (10249, 2, 19.00, 10, 0.00);`

-- Note that in lower isolation levels (such as READ UNCOMMITTED, READ COMMITTED, or REPEATABLE READ), this INSERT statement wouldn't be blocked.



-- Run the following code in Connection 1 to query `Sales.OrderDetails` again & commit the transaction:

SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails
WHERE orderid = 10249;

COMMIT TRAN;

-- We get the same result set we got from the previous query in the same transaction, & because the INSERT statement was blocked, we get no phantom reads.



-- Go back to Connection 2, & notice that the INSERT statement has finished.



-- Run the following code for cleanup:

DELETE FROM Sales.OrderDetails
WHERE orderid = 10249
	AND productid = 2;

-- Also, run the following code in both Connection 1 & Connection 2 to set the isolation level to the default:

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;



-------------------
-- Exercise 2-5
-------------------

-- In this exercise, we'll practice using the SNAPSHOT isolation level. Run the following code to allow the SNAPSHOT isolation level in the `TSQLV6` database:

ALTER DATABASE TSQLV6 SET ALLOW_SNAPSHOT_ISOLATION ON;



-- Run the following code in Connection 1 to open a transaction, update rows in `Sales.OrderDetails` & query it:

BEGIN TRAN; -- (Connection 1)

UPDATE Sales.OrderDetails
	SET discount += 0.05
WHERE orderid = 10249;

SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails
WHERE orderid = 10249;



-- Run the following code in Connection 2 to set the isolation level to SNAPSHOT & query `Sales.OrderDetails`. Notice that we're not blocked -- instead, we get an earlier, consistent version of the data that was available when

-- the transaction started (with discount values of 0.00):

	-- `SET TRANSACTION ISOLATION LEVEL SNAPSHOT;` -- (Connection 2)

	-- `BEGIN TRAN;`

	-- `SELECT orderid, productid, unitprice, qty, discount
	--  FROM Sales.OrderDetails
	--  WHERE orderid = 10249;`



-- Go to Connection 1 & commit the transaction:

COMMIT TRAN;



-- Go to Connection 2 & query the data again; notice that we still get discount values of 0.00:

	-- `SELECT orderid, productid, unitprice, qty, discount
	--	FROM Sales.OrderDetails
	--	WHERE orderid = 10249;`

-- In Connection 2, commit the transaction & query the data again; notice that now we get discount values of 0.05:

	-- `COMMIT TRAN;`

	-- `SELECT orderid, productid, unitprice, qty, discount
	--	FROM Sales.OrderDetails
	--	WHERE orderid = 10249;`



-- Run the following code for cleanup:

UPDATE Sales.OrderDetails
	SET discount = 0.00
WHERE orderid = 10249;

-- Close all connections.



-------------------
-- Exercise 2-6
-------------------

-- In this exercise, we'll practice using the READ COMMITTED SNAPSHOT isolation level. Turn on READ_COMMITTED_SNAPSHOT in the `TSQLV6` database by running the following code in any connection:

ALTER DATABASE TSQLV6 SET READ_COMMITTED_SNAPSHOT ON; -- (Connection 1)



-- Open two connections. This exercise will refer to them as Connection 1 & Connection 2. Run the following code in Connection 1 to open a tranasction, update rows in `Sales.OrderDetails` & query it:

BEGIN TRAN;

UPDATE Sales.OrderDetails
	SET discount += 0.05
WHERE orderid = 10249;

SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails
WHERE orderid = 10249;



-- Run the following code in Connection 2, which is now running under the READ COMMITTED SNAPSHOT isolation level because the database flag READ_COMMITTED_SNAPSHOT is turned on. Notice that we're not blocked -- instead we get

-- an earlier, consistent version of the data that was available when the statement started (with discount values of 0.00):

	-- `BEGIN TRAN;` -- (Connection 2)

	-- `SELECT orderid, productid, unitprice, qty, discount
	--  FROM Sales.OrderDetails
	--  WHERE orderid = 10249;`



-- Go to Connection 1 & commit the transaction:

COMMIT TRAN;



-- Go to Connection 2, query the data again, & commit the transaction. Notice that we get the new discount values of 0.05:

	-- `SELECT orderid, productid, unitprice, qty, discount
	--  FROM Sales.OrderDetails
	--  WHERE orderid = 10249;`

	-- `COMMIT TRAN;`



-- Run the following code for cleanup:

UPDATE Sales.OrderDetails
	SET discount = 0.00
WHERE orderid = 10249;

-- Close all connections. Change the database flags back to the defaults in the box product, disabling isolation levels based on row versioning (This can take a while):

	-- `ALTER DATABASE TSQLV6 SET ALLOW_SNAPSHOT_ISOLATION OFF; -- (Connection 3)
	--  ALTER DATABASE TSQLV6 SET READ_COMMITTED_SNAPSHOT OFF;`

-- Note that if we want to change these settings back to the defaults in Azure SQL Database, we'll need to set both to ON.



-----------------
-- Exercise 3
-----------------

-- Exercise 3 (steps 1 through 7) deal with deadlocks. It assumes that versioning is turned off.



-------------------
-- Exercise 3-1
-------------------

-- Open two new connections. This exercise will refer to them as Connection 1 & Connection 2.



--------------------
-- Exercise 3-2
--------------------

-- Run the following code in Connection 1 to open a tranasction & update the row for product 2 in `Production.Products`:

BEGIN TRAN;

UPDATE Production.Products
	SET unitprice += 1.00
WHERE productid = 2;



--------------------
-- Exercise 3-3
--------------------

-- Run the following code in Connection 2 to open a tranasction & update the row for product 3 in `Production.Products`:

	-- `BEGIN TRAN;` -- (Connection 2)

	-- `UPDATE Production.Products
	--		SET unitprice += 1.00
	--  WHERE productid = 3;`



--------------------
-- Exercise 3-4
--------------------

-- Run the following code in Connection 1 to query product 3. We will be blocked.

SELECT productid, unitprice
FROM Production.Products
WHERE productid = 3;

COMMIT TRAN;



--------------------
-- Exercise 3-5
--------------------

-- Run the following code in Connection 2 to query product 2. We will be blocked, & a deadlock error will be generated either in Connection 1 or Connection 2:

-- `SELECT productid, unitprice -- (Connection 2)
--  FROM Production.Products
--  WHERE productid = 2;`

-- `COMMIT TRAN;`



--------------------
-- Exercise 3-6
--------------------

-- Can you suggest a way to prevent this deadlock?

-- We can use the READ COMMITTED SNAPSHOT isolation level to prevent deadlocks by read/write conflicts, which is what this is.



--------------------
-- Exercise 3-7
--------------------

-- Run the following code for cleanup:

UPDATE Production.Products
	SET unitprice = 19.00
WHERE productid = 2;

UPDATE Production.Products
	SET unitprice = 10.00
WHERE productid = 3;