----------------------------------

-- Creating Temporal Tables

----------------------------------

-- When creating a system-versioned temporal table in T-SQL, the table definition must include the following elements:

	-- A primary key -- required to uniquely identify rows.

	-- Two DATETIME2 columns (with any precision) that are non-nullable & represent the start & end of each row's validity period (in UTC time).

		-- A start column marked with GENERATED ALWAYS AS ROW START

		-- A end column marked with GENERATED ALWAYS AS ROW END

	-- A period definition using `PERIOD FOR SYSTEM_TIME (<startcol>, <endcol>)`

	-- The table option `SYSTEM_VERSIONING = ON`

	-- A linked history table to store past versions of modified rows (SQL Server can create this automatically).

-- Optionally, we can mark the period columns as HIDDEN so that:

	-- They are omitted from `SELECT *` queries, &

	-- They're automatically ignored during INSERT operations.



-- Starting with SQL Server 2017, we can define a history retention policy using the HISTORY_RETENTION_PERIOD subclause of the SYSTEM_VERSIONING option. We can specify the retention period in DAYS, WEEKS, MONTHS, YEARS, or INFINITE. If omitted, the 

-- retention defaults to INFINITE. When a finite retention period is set, SQL Server automatically deletes expired rows (based on the end period column) in batches through a background cleanup task.



-- The following example creates a temporal table named `dbo.Employees` & a linked history table named `dbo.EmployeesHistory`:

USE TSQLV6;

DROP TABLE IF EXISTS dbo.Employees, dbo.EmployeesHistory;

CREATE TABLE dbo.Employees (
	empid		INT				NOT NULL
		CONSTRAINT PK_Employees PRIMARY KEY,
	empname		VARCHAR(25)		NOT NULL,
	department	VARCHAR(50)		NOT NULL,
	salary		NUMERIC(10, 2)	NOT NULL,
	validfrom	DATETIME2(0)
		GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,
	validto		DATETIME2(0)
		GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
	PERIOD FOR SYSTEM_TIME (validfrom, validto)
)
WITH (SYSTEM_VERSIONING = ON
	  (HISTORY_TABLE = dbo.EmployeesHistory,
	   HISTORY_RETENTION_PERIOD = 5 YEARS));

-- Review the required elements in this code:

	-- Primary key: `empid`

	-- Period columns: `validfrom`, `validto`

	-- Period definition: `PERIOD FOR SYSTEM_TIME`

	-- System versioning: `SYSTEM_VERSIONING = ON`

	-- Optional features: hidden period columns & a 5-year retention policy

-- If the specified history table (`dbo.EmployeesHistory`) does not exist, SQL Server creates it automatically. If no history table name is given, SQL Server assigns one in the format `MSSQL_TemporalHistoryFor_<object_id>`.



-- SQL Server creates the history table with a schema that mirrors the current table, but with a few differences:

	-- No primary key

	-- A clustered index on `(endcol, startcol)`

	-- Period columns are not marked as generated or hidden

	-- No `PERIOD FOR SYSTEM_TIME` declaration

	-- No `SYSTEM_VERSIONING` option

-- If we reference an existing history table when enabling system versioning, SQL Server validates that:

	-- 1. The schema matches the expected temporal structure, &

	-- 2. There are no overlapping validity periods in the data.

-- If either check fails, SQL Server raises an error & cancels the DDL operation.



-- In the SSMS Object Explorer, we'll see:

	-- `dbo.Employees` marked as (System-Versioned)

	-- `dbo.EmployeesHistory` marked as (History) underneath it



-- We can convert an existing, non-temporal table into a temporal one. Suppose `dbo.Employees` already exists -- we can alter it as follows (don't actually run this code if the table is already temporal):

	-- `ALTER TABLE dbo.Employees ADD
	--      validfrom DATETIME2(0) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL
	--			CONSTRAINT DFT_Employees_validfrom DEFAULT('19000101'),
	--		validto DATETIME2(0) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL
	--			CONSTRAINT DFT_Employees_validto DEFAULT('99991231 23:59:59'),
	--		PERIOD FOR SYSTEM_TIME(validfrom, validto);`

-- These defaults define the validity period for existing rows:

	-- The start time is set to a fixed past value ("1900-01-01")

	-- The end time is set to the maximum supported datetime value

-- Then, enable system versioning & link a history table:

	-- ALTER TABLE dbo.Employees
	-- 	   SET (SYSTEM_VERSIONING = ON
	-- 		    (HISTORY_TABLE = dbo.EmployeesHistory,
	--  		 HISTORY_RETENTION_PERIOD = 5 YEARS));



-- If we marked the period columns as hidden, a simple query such as:

SELECT *
FROM dbo.Employees;

-- will not include them in the result set. To include them, specify the columns explicitly:

SELECT empid, empname, department, salary, validfrom, validto
FROM dbo.Employees;



-- SQL Server allows schema changes on temporal tables without disabling system versioning first. Any schema modification to the current table is automatically applied to its history table as well. For example, to add a non-nullable column `hiredate`

-- with a default value:

ALTER TABLE dbo.Employees
	ADD hiredate DATE NOT NULL
		CONSTRAINT DFT_Employees_hiredate DEFAULT('19000101');

-- After running this, the `hiredate` column appears in both the current & history tables.

SELECT * FROM dbo.Employees;

SELECT * FROM dbo.EmployeesHistory;

-- The default constraint; however, is only applied to the current table -- but if any rows existed in the history table, SQL Server would fill the column with the default value. To drop this column: 

ALTER TABLE dbo.Employees
	DROP CONSTRAINT DFT_Employees_hiredate;

ALTER TABLE dbo.Employees
	DROP COLUMN hiredate;

-- SQL Server removes the column from both the current & history tables.



-- Before dropping a system-versioned temporal table, we must first disable system versioning:

	-- `ALTER TABLE dbo.Employees
	-- 	   SET (SYSTEM_VERSIONING = OFF);`

-- Then drop both table manually:

	-- `DROP TABLE dbo.Employees, dbo.EmployeesHistory;`



---------------
-- Summary
---------------

-- Temporal tables automatically track historical versions of rows.

-- Required elements include a primary key, two DATETIME2 columns, a period definition, & `SYSTEM_VERSIONING = ON`.

-- Optional features include hidden period columns & a retention policy.

-- Schema changes are automatically mirrored to the history table.

-- Always disable versioning before dropping the tables.