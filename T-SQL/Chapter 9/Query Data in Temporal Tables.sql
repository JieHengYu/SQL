------------------------------------------

-- Querying Data in Temporal Tables

------------------------------------------

-- Querying data from system-versioned temporal tables is both simple & intuitive. If we want to query the current state of the data, we simply query the current table as we would any regular table. If we want to query a past state of the data, we still 

-- query the same current table -- but we add a FOR SYSTEM_TIME clause with a subclause specifying the exact point or period of time we're interested in.



-- Before exploring the different temporal querying options, recreate the `dbo.Employees` & `dbo.EmployeesHistory` tables with the same sample data here:

USE TSQLV6;

IF OBJECT_ID(N'dbo.Employees', N'U') IS NOT NULL
BEGIN
	IF OBJECTPROPERTY(OBJECT_ID(N'dbo.Employees', N'U'), N'TableTemporalType') = 2
		ALTER TABLE dbo.Employees SET (SYSTEM_VERSIONING = OFF);
	DROP TABLE IF EXISTS dbo.EmployeesHistory, dbo.Employees;
END;
GO

CREATE TABLE dbo.Employees (
	empid		INT				NOT NULL
		CONSTRAINT PK_Employees PRIMARY KEY,
	empname		VARCHAR(25)		NOT NULL,
	department	VARCHAR(50)		NOT NULL,
	salary		NUMERIC(10, 2)	NOT NULL,
	validfrom	DATETIME2(0)	NOT NULL,
	validto		DATETIME2(0)	NOT NULL
);

INSERT INTO dbo.Employees (empid, empname, department, salary, validfrom, validto)
VALUES (1, 'Sara', 'IT', 52500.00, '2022-02-16 17:20:02', '9999-12-31 23:59:59'),
	   (2, 'Don', 'HR', 45000.00, '2022-02-16 17:08:41', '9999-12-31 23:59:59'),
	   (3, 'Judy', 'IT', 55000.00, '2022-02-16 17:28:10', '9999-12-31 23:59:59'),
	   (4, 'Yael', 'Marketing', 55000.00, '2022-02-16 17:08:41', '9999-12-31 23:59:59'),
	   (5, 'Sven', 'Sales', 47250.00, '2022-02-16 17:28:10', '9999-12-31 23:59:59');

CREATE TABLE dbo.EmployeesHistory (
	empid		INT				NOT NULL,
	empname		VARCHAR(25)		NOT NULL,
	department	VARCHAR(50)		NOT NULL,
	salary		NUMERIC(10, 2)	NOT NULL,
	validfrom	DATETIME2(0)	NOT NULL,
	validto	DATETIME2(0)	NOT NULL,
	INDEX ix_EmployeesHistory CLUSTERED(validto, validfrom)
		WITH (DATA_COMPRESSION = PAGE)
);

INSERT INTO dbo.EmployeesHistory(empid, empname, department, salary, validfrom, validto)
VALUES (6, 'Paul', 'Sales', 40000.00, '2022-02-16 17:08:41', '2022-02-16 17:15:26'),
	   (1, 'Sara', 'IT', 50000.00, '2022-02-16 17:08:41', '2022-02-16 17:20:02'),
	   (5, 'Sven', 'IT', 45000.00, '2022-02-16 17:08:41', '2022-02-16 17:20:02'),
	   (3, 'Judy', 'Sales', 55000.00, '2022-02-16 17:08:41', '2022-02-16 17:28:10'),
	   (5, 'Sven', 'IT', 47250.00, '2022-02-16 17:20:02', '2022-02-16 17:28:10');

ALTER TABLE dbo.Employees ADD PERIOD FOR SYSTEM_TIME (validfrom, validto);

ALTER TABLE dbo.Employees ALTER COLUMN validfrom ADD HIDDEN;

ALTER TABLE dbo.Employees ALTER COLUMN validto ADD HIDDEN;

ALTER TABLE dbo.Employees
	SET (SYSTEM_VERSIONING = ON
		 (HISTORY_TABLE = dbo.EmployeesHistory,
		  HISTORY_RETENTION_PERIOD = 5 YEARS));

-- This setup ensures that the outputs of your queries will match the examples that follow. Remember that when a query doesn't include an ORDER BY clause, SQL Server doesn't guarantee the order of rows in the result set. Therefore, the order of rows you 

-- see may differ from the example outputs.



-- To query the current state of the data, simply query the current table:

SELECT *
FROM dbo.Employees;

-- Because the period columns (`validfrom`, `validto`) are defined as hidden, the `SELECT *` query doesn't display them. Here, `SELECT *` is used for illustration, but the best practice in production code is to explicitly list the columns we need. The same

-- rule applies to INSERT statements. If we follow this best practice, whether or not the period columns are hidden makes no practical difference to our queries.



-- To view a past state of the data -- accurate to a specific point or period in time -- we query the current table & include the FOR SYSTEM_TIME clause, followed by one of its subclauses. When we use this clause, SQL Server automatically retrieves the 

-- relevant data from both the current & history tables as needed to reconstruct the requested time slice. Conveniently, we can also use the FOR SYSTEM_TIME clause when querying views -- the clause's definition is automatically propagated to all underlying

-- tables. The general syntax is:

	-- `SELECT ... 
	--  FROM <table_or_view> 
	--  FOR SYSTEM_TIME <subclause> AS <alias>;`

-- The FOR SYSTEM_TIME clause supports five subclauses, each specifying a different way to filter data by time. The one you'll likely use most often is AS OF. The AS OF subclause lets us view the data as it existed at a specific point in time. It's syntax

-- is:

	-- `FOR SYSTEM_TIME AS OF <datetime2 value>`

-- The `<datetime2_value>` can be a constant, a variable, or a parameter. Conceptually, the query returns all rows where the specified point in time falls within the row's validity period -- that is `validfrom <= @datetime AND validto > @datetime`. In

-- other words, the row was valid at the specified time.

-- Run the following code to see the state of the `dbo.Employees` table as of 2022-02-16 17:00:00:

SELECT *
FROM dbo.Employees FOR SYSTEM_TIME AS OF '2022-02-16 17:00:00';

-- This query returns no rows, because the first insert into the table occured later -- at 2022-02-16 17:08:41. Now, query the table again as of 2022-02-16 17:10:00:

SELECT *
FROM dbo.Employees FOR SYSTEM_TIME AS OF '2022-02-16 17:10:00';

-- This time, we'll see rows representing the data that was valid at that exact UTC timestamp.



-- We can also query multiple instances of the same temporal table to compare data states at different points in time. For example, the following query returns the percentage increase in salary for employees whose salaries increase between two points in 

-- time:

SELECT T2.empid, T2.empname,
	CAST((T2.salary / T1.salary - 1.0) * 100.0 AS NUMERIC(10, 2)) AS pct
FROM dbo.Employees FOR SYSTEM_TIME AS OF '2022-02-16 17:10:00' AS T1
	INNER JOIN dbo.Employees FOR SYSTEM_TIME AS OF '2022-02-16 17:25:00' AS T2
		ON T1.empid = T2.empid
			AND T2.salary > T1.salary;



-- The subclause `FOR SYSTEM_TIME FROM @start TO @end` returns rows that satisfy the predicate:

	-- `validfrom < @end AND validto > @start`

-- This means it returns rows whose validity period overlaps the input time interval:

SELECT empid, empname, department, salary, validfrom, validto
FROM dbo.Employees
	FOR SYSTEM_TIME BETWEEN '2022-02-16 17:15:26' AND '2022-02-16 17:20:02';



-- The subclause `FOR SYSTEM_TIME CONTAINED IN (@start, @end)` returns rows that satisfy:

	-- `validfrom >= @start AND validto <= @end`

-- This returns rows whose validity period is entirely contained within the input interval:

SELECT empid, empname, department, salary, validfrom, validto
FROM dbo.Employees
	FOR SYSTEM_TIME CONTAINED IN('2022-02-16 17:00:00', '2022-02-16 18:00:00');



-- The subclause `FOR SYSTEM_TIME ALL` returns all rows from both the current & history tables, regardless of their validity period:

SELECT empid, empname, department, salary, validfrom, validto
FROM dbo.Employees FOR SYSTEM_TIME ALL
WHERE empid = 5;



-- The period columns (`validfrom` & `validto`) represent the validity period of each row as DATETIME2 values in the UTC time zone. To display these values in a specific time zone, we can use the AT TIME ZONE function. This function must be applied twice:

	-- 1. First, to convert the UTC DATETIME2 value to a DATETIMEOFFSET value by specifying `'UTC'`.

	-- 2. Second, to convert that UTC offset value to the target time zone.

-- For example:

	-- `validfrom AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time'

-- If we use only one AT TIME ZONE conversion directly on the target zone, SQL Server assumes the source value is already in that time zone & therefore won't perform the correct conversion.



-- For the `validto` column, when its value equals the maximum value of the data type (`'9999-12-31 23:59:59'`), it's best to treat it as remaining in UTC to avoid overflow during conversion. Otherwise, we can convert it to the target time zone the same

-- way as the `validfrom` column. A CASE expression is typically used to handle this logic. The following query returns all rows from both the current & history tables, with the period columns converted to Pacific Standard Time (PST):

SELECT empid, empname, department, salary,
	validfrom AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time' AS validfrom,
	CASE
		WHEN validto = '9999-12-31 23:59:59'
			THEN validto AT TIME ZONE 'UTC'
		ELSE validto AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time'
	END AS validto
FROM dbo.Employees FOR SYSTEM_TIME ALL;



-- When you're done experimenting with the data, run the following code for cleanup:

IF OBJECT_ID(N'dbo.Employees', N'U') IS NOT NULL
BEGIN
	IF OBJECTPROPERTY(OBJECT_ID(N'dbo.Employees', N'U'), N'TableTemporalType') = 2
		ALTER TABLE dbo.Employees SET (SYSTEM_VERSIONING = OFF);
	DROP TABLE IF EXISTS dbo.EmployeesHistory, dbo.Employees;
END;
