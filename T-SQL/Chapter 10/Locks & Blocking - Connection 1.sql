------------------------

-- Locks & Blocking

------------------------

-- By default, the SQL Server box product uses a locking-based concurrency control model to enforce the isolation property of transactions. The following sections describe how SQL Server implements locking & how to troubleshoot

-- blocking scenarios caused by incompatible lock requests.



------------
-- Locks
------------

-- Locks are control resources acquired by a transaction to protect underlying data resources. Their purpose is to prevent conflicting or otherwise incompatible access by other transactions, ensuring data consistency during

-- conccurrent activity.



-- The following sections outline:

	-- 1. The major lock modes supported by SQL Server & their compatibility rules.

	-- 2. The different lockable resource types SQL Server can lock when managing concurrency.



----------------------------------
-- Lock Modes & Compatibility
----------------------------------

-- When learning about transactions & concurrency in SQL Server, the first two lock modes to understand are exclusive (X) & shared (S) locks.



-- When a transaction modifies data, SQL Server always requests an exclusive lock on the target resource, regardless of the isolation level. If granted, the exclusive lock is held until the end of the transaction. In a

-- single-statement implicit transaction, this means the lock remains until the statement completes. In an explicit transaction, it remains until the session issues a COMMIT TRAN or ROLLBACK TRAN.



-- Exclusive locks are "exclusive" because:

	-- An X lock cannot be granted if any other transaction holds any lock mode on the resource.

	-- While a transaction holds an X lock, no other lock mode can be granted on that resource.

-- This behaviour is fixed:

	-- We cannot change the lock mode required for data modification (it is always exclusive).

	-- We cannot shorten its duration (it always lasts to the end of the transaction).

-- In practical terms, if one transaction modifies specific rows, no other transaction can modify those same rows until the first transaction completes. Whether other transactions may read those rows depends on their isolation

-- level.



-- The default read behaviour differs between SQL Server's on-premises product & Azure SQL Database because they use different default isolation levels. SQL Server uses the default READ COMMITTED isolation level, where read 

-- operations request shared locks:

	-- The shared lock is acquired during the read.

	-- It is relesaed as soon as the statement finishes reading the resource.

	-- Multiple transactions can hold S locks on the same resource simultaneously.

-- Unlike modification operations, read behaviour can be changed by selecting a different isolation level (e.g., READ UNCOMMITTED, SNAPSHOT, SERIALIZABLE). Azure SQL Database uses READ COMMITTED SNAPSHOT by default. This

-- isolation level combines locking with row-versioning:

	-- Readers do not acquire shared locks, so they never block or wait for writers.

	-- Readers receive a consistent snapshot representing the last committed version of each row as of the start of the statement.

-- In practical terms:

	-- Under pessimistic READ COMMITTED (on-prem SQL Server), a reader waits if a writer holds an exclusive lock.

	-- Under optimistic READ COMMITTED SNAPSHOT (Azure SQL DB), a reader does not wait & gets a versioned copy of the data.



-- The interaction between different lock modes is known as lock compatibility. The table below shows the compatibility of shared (S) & exclusive (X) locks:

-- | Requested Mode | Granted Exclusive (X) | Granted Shared (S) |
-- | -------------- | --------------------- | ------------------ |
-- | Exclusive      | No                    | No                 |
-- | -------------- | --------------------- | ------------------ |
-- | Shared         | No                    | Yes                |
-- | -------------- | --------------------- | ------------------ |

	-- Yes: The requested lock is compatible & can be greanted immediately.

	-- No: The locks are incompatible; the requesting transaction must wait.



-- In summary:

	-- When one transaction modifies data, other transactions cannot read or modify that data until the first transaction finishes (under the default pessimistic READ COMMITTED in SQL Server).

	-- When one transaction reads data under READ COMMITTED, it acquires shared locks that prevent modifications by other transactions until the READ completes.



--------------------------------
-- Lockable Resource Types
--------------------------------

-- SQL Server can lock several different types of resources. The most common are:

	-- Rows (RID in a heap, or a key in a B-tree index)

	-- Pages

	-- Objects (such as tables)

	-- Databases

-- Rows are stored within pages, & pages are the physical data blocks that hold tables & index data. At more advanced levels, SQL Server can also lock other resource types such as extents, allocation units, heaps, & B-tree

-- structures.



-- To acquire a lock at a given level of granularity, SQL Server must first acquire intent locks of the same mode at higher levels. This structure is called the lock hierarchy, which generally flows:

	-- Database -> Object (Table/Index) -> Page -> Row

-- Examples:

	-- To obtain an exclusive lock (X) on a row, SQL Server must first acquire intent exclusive (IX) locks on the table & page containing that row.

	-- To acquire a shared lock (S) on a row or page, SQL Server must acquire intent shared (IS) locks on the higher-level resources.

-- Intent locks serve two purposes:

	-- 1. Efficient conflict detection: They allow SQL Server to quickly determine whether a lock request for a higher-level resource conflicts with locks already held at lower levels.

	-- 2. Protection against incompatible higher-level locks: For example, if one transaction holds a row lock, another transaction cannot acquire an incompatible page or table lock because the intent locks mark the lower-level

		-- resources as in use.



-- The table below expands the earlier compatibility table to include intent exclusive (IX) & intent shared (IS) locks:

-- | Requested Mode   | Granted Exclusive (X) | Granted Shared (S) | Granted Intent Exclusive (IX) | Granted Intent Shared (IS) |
-- | ---------------- | --------------------- | ------------------ | ----------------------------- | -------------------------- |
-- | Exclusive        | No                    | No                 | No                            | No                         |
-- | ---------------- | --------------------- | ------------------ | ----------------------------- | -------------------------- |
-- | Shared           | No                    | Yes                | No                            | Yes                        |
-- | ---------------- | --------------------- | ------------------ | ----------------------------- | -------------------------- |
-- | Intent Exclusive | No                    | No                 | Yes                           | Yes                        |
-- | ---------------- | --------------------- | ------------------ | ----------------------------- | -------------------------- |
-- | Intent Shared    | No                    | Yes                | Yes                           | Yes                        |
-- | ---------------- | --------------------- | ------------------ | ----------------------------- | -------------------------- |



-- SQL Server dynamically decides which resource types to lock. Ideally, it locks only what is necessary (e.g., rows) to maximise concurrency. However, locks consume memory & processing overhead, so SQL Server balances:

	-- Concurrency goals: favor smaller locks

	-- Resource usage: favor larger locks when too many fine-grained locks accumulate.

-- Typical patterns:

	-- For small sets of affected rows, SQL Server uses row locks.

	-- For larger sets of affected rows, SQL Server may use page locks.

	-- SQL Server may acquire lower-level locks first (row/page) & later escalate them to a table or partition lock.

-- Lock escalation in SQL Server's mechanism for replacing many fine-grained locks with a single coarser lock conserves memory & reduces lock-tracking overhead.

-- Key points:

	-- Lock escalation is triggered when a single statement acquires rougly 5,000 locks on a single object.

	-- SQL Server checks for escalation when a transaction reaches 2,500 locks, & again every 1,250 additional locks.

	-- Escalation typically replaces row/page locks with a table lock.

	-- In partitioned tables, escalation can target a partition-level lock instead of the entire table.

-- We can control escalation behaviour using the table option LOCK_ESCALATION via ALTER TABLE> Options include:

	-- TABLE (default): escalate to a table-level lock

	-- AUTO: allow partition-level escalation when applicable

	-- DISABLE: prevent lock escaltion (intended for special scenarious; use with caution)



---------------------------------
-- Troubleshooting Blocking
---------------------------------

-- When one transaction holds a lock on a data resource & another transaction requests an incompatible lock on that same resource, the same request enters a wait state. By default, the blocked request waits indefinitely until the

-- blocking transaction releases the lock.



-- Blocking is normal as long as blocked requests complete within a reasonable time. However, excessive blocking -- or blocking that leads to long latencies -- requires investigation. Common causes include:

	-- Long-running transctions, which holds locks longer than necessary

	-- Application bugs that leave transactions open

	-- Poorly designed units of work, where operations that do not belong in a transaction are included inside one

-- In such cases, we want to troubleshoot the blocking scenario & determine whether corrective action is needed.



-- Assuming the default isolation level READ COMMITTED, open three query windows in SSMS (Connection 1, Connection 2, & Connection 3), & connect each to the sample database `TSQLV6`:

USE TSQLV6; -- (Connection 1)

BEGIN TRAN;

UPDATE Production.Products
	SET unitprice += 1.00
WHERE productid = 2;

-- This update acquires an exclusive lock (X) on the target row, & because the transaction remains open (no COMMIT or ROLLBACK yet), the lock remains held. Run the following code in Connection 2 to try to query the same row:

	-- `SELECT productid, unitprice
	--  Production.Products
	--  WHERE productid = 2;

-- To read the row, the session needs a shared lock (S). Because S & X locks are incompatible, Connection 2 becomes blocked.



-- When troubleshooting a blocking situation, use Connection 3 to run DMV queries that help identify:

	-- Which sessions are holding locks

	-- Which sessions are waiting

	-- What resources are involved

	-- What SQL text each session is running

-- To view lock information, query the dynamic management view (DMV) `sys.dm_tran_locks` in Connection 3:

	-- `SELECT request_session_id AS sid,
	--		resource_type AS restype,
	--		resource_database_id AS dbid,
	--		DB_NAME(resource_database_id) AS dbname,
	--		resource_description AS res,
	--		resource_associated_entity_id AS resid,
	--		request_mode AS mode,
	--		request_status AS status
	--	FROM sys.dm_tran_locks;`

-- This DMV shows, for each session:

	-- The locked resource type (e.g., KEY for an index row)

	-- Database ID (convert to name using DB_NAME)

	-- Resource identifiers (`res` & `resid`)

	-- The lock mode

	-- Whether the session's request is granted or waiting

-- By comparing `res` & `resid`, we can identify when two sessions are contending for the same row. Moving up the lock hierarchy (e.g., examining object-level intent locks) helps determine the table involved. Use

-- `SELECT OBJECT_NAME(<object_id>, <database_id>)` to translate object IDs to table names.



-- To retrieve information about participating connections, query `sys.dm_exec_connections` (Use your actual session IDs):

SELECT session_id AS sid,
	connect_time,
	last_read,
	last_write,
	most_recent_sql_handle
FROM sys.dm_exec_connections
WHERE session_id IN (52, 64);

-- This view shows:

	-- Connection time

	-- Last read/write times

	-- The SQL handle for the last batch the session executed

-- To retrieve the SQL text for those batches, use CROSS APPLY with `sys.dm_exec_sql_text` (run in Connection 3):

		-- `SELECT session_id, text
		--  FROM sys.dm_exec_connections
		--		CROSS APPLY sys.dm_exec_sql_text(most_recent_sql_handle) AS ST
		--	WHERE session_id IN (52, 64);

-- The blocked session typically shows the query currently waiting. The blocking may show the statement responsible -- or a later statement if the session continued running. When we run this query, we'll get an output showing the 

-- last batch of code invoked by each connection involved in the blocking chain.



-- For a more accurate retrieval of the last statement submitted:

SELECT session_id, event_info
FROM sys.dm_exec_connections
	CROSS APPLY sys.dm_exec_input_buffer(session_id, NULL) AS IB
WHERE session_id IN (52, 64);



-- We can also find a lot of additional session information by querying `sys.dm_exec_sessions`:

SELECT session_id AS sid,
	login_time,
	host_name,
	program_name,
	login_name,
	nt_user_name,
	last_request_start_time,
	last_request_end_time
FROM sys.dm_exec_sessions
WHERE session_id IN (52, 64);

-- This DMV provides context such as:

	-- Host & program name

	-- Login information

	-- When the session last issued a request

-- This helps identify the client responsible for the blocking.



-- Another useful DMV for identifying blocked requests is by querying `sys.dm_exec_requests`:

SELECT session_id AS sid,
	blocking_session_id,
	command,
	sql_handle,
	database_id,
	wait_type,
	wait_time,
	wait_resource
FROM sys.dm_exec_requests
WHERE blocking_session_id > 0;

-- This view shows:

	-- The blocked session

	-- It's blocker

	-- The command it's running

	-- The wait type, wait duration (in milliseconds), & the resource being waited on

-- Alternatively, we can query the DMV, `sys.dm_os_waiting_tasks`, which includes only currently waiting tasks, & provides more granular wait details.



-- If a transaction remains open due to an application error or cannot otherwise be resolved, we may need to terminate the blocker (Don't do so yet.):

	-- `KILL <session_id>`

-- This forces a rollback of the blocking transaction & releases its locks.



--  By default, a session waits indefinitely for locks (`LOCK_TIMEOUT = -1`). To limit how long a session waits:

SET LOCK_TIMEOUT 5000;

SELECT productid, unitprice
FROM Production.Products
WHERE productid = 2;

-- If the lock cannot be acquired within 5 seconds, SQL Server cancels the statement & returns an error. Note:

	-- Lock timeouts do not roll back transactions

	-- To set LOCK_TIMEOUT back to unlimited, run the following code in Connection 1:

SET LOCK_TIMEOUT -1;

SELECT productid, unitprice
FROM Production.Products
WHERE productid = 2;



-- Terminate the update transaction from Connection 1 by issuing the following from Connection 3:

	-- `KILL 52;`

-- The rollback releases the exclusive lock. Connection 2 can now acquire the shared lock & successfully read the original value.