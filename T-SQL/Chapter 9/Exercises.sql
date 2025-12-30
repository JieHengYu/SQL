----------------

-- Exercises

----------------

-- This section provides exercises to help us familiarise ourselves with the subjects discussed in this lesson.

USE TSQLV6;



--------------------
-- Exercise 1
--------------------

-- In this exercise, we create a system-versioned temporal table & identify it in SSMS.

--------------------
-- Exercise 1-1
--------------------

-- Create a system-versioned temporal called `dbo.Departments` with an associated history table called `dbo.DepartmentsHistory` in the database `TSQLV6`. The table should have the following columns: `deptid INT`, `deptname VARCHAR(25)` & `mgrid INT`, all

-- disallowing NULLs. Also include columns called `validfrom` & `validto` that define the validity period of the row. Define those with precision zero (1 second), & make them hidden. Define a history retention policy of six months:

DROP TABLE IF EXISTS dbo.Departments, dbo.DepartmentsHistory;

CREATE TABLE dbo.Departments (
	deptid		INT				NOT NULL
		CONSTRAINT PK_Departments PRIMARY KEY,
	deptname	VARCHAR(25)		NOT NULL,
	mgrid		INT				NOT NULL,
	validfrom	DATETIME2(0)
		GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,
	validto		DATETIME2(0)
		GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
	PERIOD FOR SYSTEM_TIME (validfrom, validto)
)
WITH (SYSTEM_VERSIONING = ON
	  (HISTORY_TABLE = dbo.DepartmentsHistory,
	   HISTORY_RETENTION_PERIOD = 6 MONTHS));

SELECT * FROM dbo.Departments;

SELECT * FROM dbo.DepartmentsHistory;



--------------------
-- Exercise 1-2
--------------------

-- Browse the object tree in the Object Explorer in SSMS, & identify the `dbo.Departments` table & its associated history table.

-- Can't find it.



--------------------
-- Exercise 2
--------------------

-- In this exercise, we'll modify data in the table `dbo.Departments`. Note the point in time in UTC when we submit each statement & make those as P1, P2, & so on. We can also do so by invoking the SYSUTCDATETIME function in the

-- same batch in which we submit the modification. Another option is to query the `dbo.Departments` table & its associated history table to obtain the point in time from the `validfrom` & `validto` columns.

--------------------
-- Exercise 2-1
--------------------

-- Insert four rows to the table `dbo.Departments` with teh following details & note the time when you apply the insert (call it P1):

	-- `deptid`: 1, `deptname`: HR, `mgrid`: 7

	-- `deptid`: 2, `deptname`: IT, `mgrid`: 5

	-- `deptid`: 3, `deptname`: Sales, `mgrid`: 11

	-- `deptid`: 4, `deptname`: Marketing, `mgrid`: 13

INSERT INTO dbo.Departments(deptid, deptname, mgrid)
VALUES (1, 'HR', 7),
	   (2, 'IT', 5),
	   (3, 'Sales', 11),
	   (4, 'Marketing', 13);

SELECT deptid, deptname, mgrid, validfrom, validto 
FROM dbo.Departments;



--------------------
-- Exercise 2-2
--------------------

-- In one transaction, update the name of department 3 to Sales & Marketing & delete department 4. Call the point in time when the transaction starts P2:

BEGIN TRAN;

UPDATE dbo.Departments
	SET deptname = 'Marketing'
WHERE deptid = 3;

DELETE FROM dbo.Departments
WHERE deptid = 4;

COMMIT TRAN;

SELECT deptid, deptname, mgrid, validfrom, validto
FROM dbo.Departments;

SELECT *
FROM dbo.DepartmentsHistory;



--------------------
-- Exercise 2-3
--------------------

-- Update the manager ID of department 3 to 13. Call the point in time when you apply this update P3:

UPDATE dbo.Departments
	SET mgrid = 13
WHERE deptid = 3;

SELECT deptid, deptname, mgrid, validfrom, validto
FROM dbo.Departments;

SELECT *
FROM dbo.DepartmentsHistory;



--------------------
-- Exercise 3
--------------------

-- In this exercise, you'll query data from the table `dbo.Departments`.

--------------------
-- Exercise 3-1
--------------------

-- Query the current state of the table `dbo.Departments`:

SELECT *
FROM dbo.Departments;



--------------------
-- Exercise 3-2
--------------------

-- Query the state of the table `Departments` at a point in time of our choosing after P2 & before P3:

SELECT deptid, deptname, mgrid
FROM dbo.Departments
FOR SYSTEM_TIME AS OF '2025-11-14 03:09:00';

SELECT * 
FROM dbo.DepartmentsHistory;



--------------------
-- Exercise 3-3
--------------------

-- Query the state of the table `dbo.Departments` in the period between P2 & P3. Be explicit about the column names in the SELECT list, & include the `validfrom` & `validto` columns:

SELECT deptid, deptname, mgrid, validfrom, validto
FROM dbo.Departments
FOR SYSTEM_TIME BETWEEN '2025-11-14 03:08:06' AND '2025-11-14 03:10:34';

SELECT * 
FROM dbo.DepartmentsHistory;



--------------------
-- Exercise 4
--------------------

-- Drop the table `Departments` & its associated history table.

IF OBJECT_ID(N'dbo.Departments', N'U') IS NOT NULL
BEGIN
	IF OBJECTPROPERTY(OBJECT_ID(N'dbo.Departments', N'U'), N'TableTemporalType') = 2
		ALTER TABLE dbo.Departments SET (SYSTEM_VERSIONING = OFF);
	DROP TABLE IF EXISTS dbo.DepartmentsHistory, dbo.Departments;
END;