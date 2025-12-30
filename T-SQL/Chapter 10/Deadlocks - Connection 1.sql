-----------------

-- Deadlocks

-----------------

-- A deadlock occurs when two or more sessions permanently block each other. The simplest case is a two-session deadlock:

	-- Session A blocks Session B, &

	-- Session B blocks Session A.

-- Deadlocks can also involve more than two sessions (e.g., A blocks B, B blocks C, & C blocks A). In all cases, none of the sessions can continue, so SQL Server detects the deadlock & resolves it by terminating one of the

-- transactions. Without intervention, the sessions would remain blocked indefinitely.



-- By default, SQL Server terminates the transaction that performed the least amount of work, measured by activity recorded in the transaction log. This minimises the cost of rolling back. We can override this behaviour using

-- the DEADLOCK_PRIORITY session setting, which accepts 21 values from -10 through 10.

	-- The session with the lowest priority becomes the deadlock victim.

	-- If multiple sessions have the same priority, SQL Server falls back to the cost-based method.

	-- If work estimates are identical, the victim is chosen randomly.



-- The following example shows a deadlock scenario & how SQL Server handles it. Open two connections to the `TSQLV6` database. In Connection 1, update product 2 in `Production.Products` & leave the transaction open:

USE TSQLV6; -- (Connection 1)

BEGIN TRAN;

UPDATE Production.Products
	SET unitprice += 1.00
WHERE productid = 2;

-- Connection 1 now holds an exclusive (X) lock on product 2 in `Production.Products`. Now, in Connection 2, update product 2 in `Sales.OrderDetails & leave the transaction open:

	-- `BEGIN TRAN;`

	-- `UPDATE Sales.OrderDetails
	--		SET unitprice += 1.00
	--  WHERE productid = 2;`

-- Connection 2 now holds exclusive lock on product 2 rows in `Sales.OrderDetails`. Both updates succeed; no blocking has occurred yet.



-- In Connection 1, we can attempt to read `Sales.OrderDetails`:

SELECT orderid, productid, unitprice
FROM Sales.OrderDetails
WHERE productid = 2;

COMMIT TRAN;

-- This read requires a shared (S) lock on the same rows that Connection 2 is exclusively locking. Connection 1 becomes blocked, but this is still only blocking -- not a deadlock. Connection 2 could still commit & release its

-- locks. Next, read product 2 in the `Production.Products` table in Connection 2 & commit the transaction:

	-- `SELECT productid, unitprice
	--  FROM Production.Products
	--  WHERE productid = 2;`

	-- `COMMIT TRAN;`

-- Connection 2 now needs a shared lock on the product row that Connection 1 is exclusively locking. At this point:

	-- Connection 1 is waiting on a lock held by Connection 2

	-- Connection 2 is waiting on a lock held by Connection 1

-- This is a deadlock. SQL Server detects it (usually within seconds) & terminates one transaction. In this example, SQL Server terminates Connection 1, but either connection could have been chosen since both performed similar

-- amounts of work & neither set a custom DEADLOCK_PRIORITY.



-- Deadlocks are expensive because SQL Server must roll back the victim transaction, & application-level logic usually needs to retry the work. Frequent deadlocks reduce throughput & increase latency. Long-running transactions 

-- hold locks longer, increasing the chance of deadlock. Avoid transactions that wait for user input or perform long-running operations.



-- A common deadlock pattern -- often called a deadly embrace -- occurs when two transactions access the same resources but in reverse order. In the example:

	-- Connection 1 accesses `Production.Products`, then `Sales.OrderDetails`

	-- Connection 2 accesses `Sales.OrderDetails`, then `Production.Products`

-- If both transactions accessed the table in the same order, this particular deadlock would not occur (assuming that reordering does not logically change the application's behaviour).



-- Deadlocks frequently happen even when there is no logical conflict, simply because SQL Server must scan & lock many rows when proper indexes are not available. For example, if Connection 2's statements filter `productid = 5`,

-- & Connection 1 operates on `productid = 2`, there should be no conflict. But if the `productid` column lacks useful indexes, SQL Server may perform table scans that lock many rows, increasing the likelihood of deadlocks. Good

-- indexing significantly reduces "false" deadlocks caused by large scans.




-- The deadlock in this example arises because SELECT statements require shared locks under READ COMMITTED. If we enable READ COMMITTED SNAPSHOT, readers use row versions instead of acquiring shared locks. This prevents deadlocks

-- caused solely by read/write conflicts.



-- Run these statements in either connection to restore original values:

UPDATE Production.Products
	SET unitprice = 19.00
WHERE productid = 2;

UPDATE Sales.OrderDetails
	SET unitprice = 19.00
WHERE productid = 2
	AND orderid >= 10500;

UPDATE Sales.OrderDetails
	SET unitprice = 15.20
WHERE productid = 2
	AND orderid < 10500;