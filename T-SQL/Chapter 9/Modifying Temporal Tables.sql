-----------------------------------

-- Modifying Temporal Tables

-----------------------------------

-- Modifying data in a system-versioned temporal table works much like modifying a regular table. We can use the standard DML statements -- INSERT, UPDATE, DELETE, & MERGE -- to change data in the current table. Note that SQL Server 2022 still does not

-- support the TRUNCATE statement for temporal tables. Behind the scenes, SQL Server automatically manages the period columns & moves affected rows to the history table as needed. The period columns record the validity period of each row, always in the

-- UTC time zone.



-- If the period columns were defined as hidden (as in our example), we can ignore them entirely when inserting new rows. If they were not defined as hidden:

	-- As long as we explicitly list the target column names in our INSERT statement (a best practice), we can still omit the period columns.

	-- However, if we omit the column list, we must provide a value for each column -- including the period columns. In that case, use the keyword DEFAULT for those values.



-- In the following example, we'll insert a few rows into the `dbo.Employees` table & examine how SQL Server handles them behind the scenes. Since the `validfrom` & `validto` columns are stored in UTC, it's useful to note the current UTC time before

-- running statements. We can retrieve it using the SYSUTCDATETIME() function:

USE TSQLV6;

SELECT SYSUTCDATETIME();

INSERT INTO dbo.Employees (empid, empname, department, salary)
VALUES (1, 'Sara', 'IT', 50000.00),
	   (2, 'Don', 'HR', 45000.00),
	   (3, 'Judy', 'Sales', 55000.00),
	   (4, 'Yael', 'Marketing', 55000.00),
	   (5, 'Sven', 'IT', 45000.00),
	   (6, 'Paul', 'Sales', 40000.00);

-- After the insert, we can query both the current & history tables to see what SQL Server did automatically:

SELECT empid, empname, department, salary, validfrom, validto
FROM dbo.Employees;

SELECT empid, empname, department, salary, validfrom, validto
FROM dbo.EmployeesHistory;

-- The current table now contains the six newly inserted rows.

	-- The `validfrom` column reflects the time the rows were inserted.

	-- The `validto` column holds the maximum representable datetime value (for the chosen precision).

-- This indicates that the rows are currently valid & have no defined end of validity. At this stage, the history table remains empty since no updates or deletions have occurred yet.



-- When we delete a row from a system-versioned temporal table, SQL Server automatically moves the deleted version of the row to the history table & updates its validity period. Run the following code to delete the row where the employee ID is 6:

SELECT SYSUTCDATETIME();

DELETE FROM dbo.Employees
WHERE empid = 6;

-- SQL Server moves the deleted row to the history table, setting its `validto` value to the deletion time. We can verify this by querying both the current & history tables:

SELECT empid, empname, department, salary, validfrom, validto
FROM dbo.Employees;

SELECT empid, empname, department, salary, validfrom, validto
FROM dbo.EmployeesHistory;

-- At this point:
	
	-- The current table no longer includes the deleted employee (empid = 6).

	-- The history table now contains one row -- the deleted version -- with its `validto` column showing the UTC time when the deletion occurred.



-- When we update a row in a temporal table, SQL Server internally handles it as a delete plus an insert operation:
	
	-- The old version of the row is moved to the history table, with the transaction time as its `validto` (period end) value.

	-- The new version of the row remains in the current table, with the transaction time as its `validfrom` (period start) value & the maximum datetime value (for the chosen precision) as its `validto`.

-- Run the following example, which increases the salary of all employees in the IT department by 5%:

SELECT SYSUTCDATETIME();

UPDATE dbo.Employees
	SET salary *= 1.05
WHERE department = 'IT';

-- After the update, check the current data:

SELECT empid, empname, department, salary, validfrom, validto 
FROM dbo.Employees;

-- Notice that the IT employees now have updated salaries & new `validfrom` timestamps indicating when the change occured. We can also query the history table to see the previous versions of those rows:

SELECT empid, empname, department, salary, validfrom, validto
FROM dbo.EmployeesHistory;

-- Here, you'll find the old `salary` values, with their `validto` columns marking the exact UTC time of the update.



-- The modification times that SQL Server records in the period columns (`validfrom` & `validto`) reflect the transaction start time, not the time the individual statement executes. If a transaction starts at time T1 & ends at T2, SQL Server will record

-- T1 as the modification time for all operations performed within that transaction -- regardless of when each statement is actually run. To demonstrate, run the following example. It opens an explicit transaction, updates two rows several seconds apart,

-- & then commits the changes:

SELECT SYSUTCDATETIME();

BEGIN TRAN;

UPDATE dbo.Employees
	SET department = 'Sales'
WHERE empid = 5;

-- Wait a few seconds, & then run the following code to change the department of employee 3 to IT:

UPDATE dbo.Employees
	SET department = 'IT'
WHERE empid = 3;

COMMIT TRAN;

SELECT SYSUTCDATETIME();

-- Here:

	-- `BEGIN TRAN` starts an explicit transaction.

	-- `COMMIT TRAN` ends the transaction & makes its changes permanent.

-- After running the transaction, check the contents of the current & history tables:

SELECT empid, empname, department, salary, validfrom, validto
FROM dbo.Employees;

-- Following is the content of the history table at this point:

SELECT empid, empname, department, salary, validfrom, validto
FROM dbo.EmployeesHistory;

-- You'll notice that for all modified rows, the modification times recorded in the period columns -- `validfrom` for the current table & `validto` for the history table -- reflect the transaction's start time, not the time of each individual UPDATE.



-- Because modification times correspond to the transaction start time, this can lead to some interesting effects. If we update the same row multiple times with a single transaction, SQL Server will record several historical versions of that row, but the

-- intermediate versions (between the earliest & latest) will have zero-length validity periods -- that is, their `validfrom` & `validto` values will be identical, both set to the transaction's start time. These zero-length validity periods are known as 

-- degenerate intervals. When we query temporal tables using the FOR SYSTEM_TIME clause for time-travel queries, SQL Server automatically filters out rows with degenerate intervals, since they represent transient states that were never valid for any

-- measurable period of time.

