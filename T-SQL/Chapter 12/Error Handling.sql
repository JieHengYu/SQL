----------------------

-- Error Handling

----------------------

-- SQL Server provides tools for handling errors in T-SQL code. The primary mechanism for error handling is the TRY...CATCH construct. In addition, SQL Server exposes a set of built-in functions that allow us to retrieve detailed

-- information about an error after it occurs.



-- We'll begin with a basic example that demonstrates how TRY...CATCH works, & then move on to a more detailed example, that uses the error-information functions.



-- To use TRY...CATCH, we place our normal T-SQL code inside a TRY block (between the BEGIN TRY & END TRY) keywords), & we place all error-handling logic inside the adjacent CATCH block (between BEGIN CATCH & END CATCH).

	-- If no error occurs in the TRY block, the CATCH block is skipped.

	-- If an error occurs in the TRY block, control is immediately transferred to the corresponding CATCH block.

	-- If the CATCH block captures & handles the error, then from the caller's perspective, no error occurred unless the error is explicitly re-thrown.



-- Run the following code to demonstrate a TRY block completes successfully:

USE TSQLV6;

BEGIN TRY
	PRINT 10/2;
	PRINT 'No error';
END TRY
BEGIN CATCH
	PRINT 'Error';
END CATCH;

-- All statements in the TRY block execute successfully, so the CATCH block is skipped. Now, run similar code, but this time divide by zero:

BEGIN TRY
	PRINT 10/0;
	PRINT 'No error';
END TRY
BEGIN CATCH
	PRINT 'Error';
END CATCH;

-- When the divide-by-zero error occurs in the first PRINT statement, control immediately passes to the CATCH block. The second PRINT statement in the TRY block is never executed, & the code prints `'Error'`.



-- In practice, error handling usually involves investigating the cause of the error & taking an appropriate action. SQL Server provides several functions that return information about the error that occurred.

	-- ERROR_NUMBER(): returns the integer error number

	-- ERROR_MESSAGE(): returns the error message text

	-- ERROR_SEVERITY(): returns the severity level of the error

	-- ERROR_STATE(): returns the state number of the error

	-- ERROR_LINE(): returns the line number where the error occurred

	-- ERROR_PROCEDURE(): returns the name of the stored procedure in which the error occurred, or NULL if the error did not occur within a procedure

-- We can view the full list of SQL Server error numbers & messages by querying the `sys.messages` catalog view.



-- To demonstrate a more realistic error-handling scenario, first create a table named `dbo.Employees` in the current database:

DROP TABLE IF EXISTS dbo.Employees;

CREATE TABLE dbo.Employees (
	empid	INT			NOT NULL,
	empname VARCHAR(25)	NOT NULL,
	mgrid	INT			NULL,
	CONSTRAINT PK_Employees PRIMARY KEY(empid),
	CONSTRAINT CHK_Employees_empid CHECK(empid > 0),
	CONSTRAINT FK_Employees_Employees
		FOREIGN KEY(mgrid) REFERENCES dbo.Employees(empid)
);

-- The following code attempts to insert a row into `dbo.Employees` inside a TRY block. If an error occurs, the CATCH block inspects the error number & takes different actions depending on the type of error. Errors that are not

-- explicitly handled are re-thrown. The code also prints the values returned by the error functions to illustrate the information available during error handling:

BEGIN TRY
	INSERT INTO dbo.Employees(empid, empname, mgrid)
	VALUES(1, 'Emp1', NULL);
END TRY
BEGIN CATCH
	IF ERROR_NUMBER() = 2627
		BEGIN
			PRINT 'Handling PK violation...';
		END;
	ELSE IF ERROR_NUMBER() = 547
		BEGIN
			PRINT 'Handling CHECK/FK constraint violation...';
		END;
	ELSE IF ERROR_NUMBER() = 515
		BEGIN
			PRINT 'Handling NULL violation...';
		END;
	ELSE IF ERROR_NUMBER() = 245
		BEGIN
			PRINT 'Handling conversion error...';
		END;
	ELSE
		BEGIN
			PRINT 'Re-throwing error...';
			THROW;
		END;

PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
PRINT 'Error Message: ' + ERROR_MESSAGE();
PRINT 'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10));
PRINT 'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10));
PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10));
PRINT 'Error Proc: ' + COALESCE(ERROR_PROCEDURE(), 'Not within proc');
END CATCH;

-- The first time this code runs, the row is inserted successfully, so the CATCH block is skipped. When the code is run a second time, the INSERT fails with a primary key violation, control is transferred to the CATCH block, &

-- the error is identified & handled accordingly.



-- To see a different error, run the same code using the values `(0, 'A', NULL)`:

BEGIN TRY
	INSERT INTO dbo.Employees(empid, empname, mgrid)
	VALUES(0, 'A', NULL);
END TRY
BEGIN CATCH
	IF ERROR_NUMBER() = 2627
		BEGIN
			PRINT 'Handling PK violation...';
		END;
	ELSE IF ERROR_NUMBER() = 547
		BEGIN
			PRINT 'Handling CHECK/FK constraint violation...';
		END;
	ELSE IF ERROR_NUMBER() = 515
		BEGIN
			PRINT 'Handling NULL violation...';
		END;
	ELSE IF ERROR_NUMBER() = 245
		BEGIN
			PRINT 'Handling conversion error...';
		END;
	ELSE
		BEGIN
			PRINT 'Re-throwing error...';
			THROW;
		END;

PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
PRINT 'Error Message: ' + ERROR_MESSAGE();
PRINT 'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10));
PRINT 'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10));
PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10));
PRINT 'Error Proc: ' + COALESCE(ERROR_PROCEDURE(), 'Not within proc');
END CATCH;

-- In these examples, we use PRINT statements to demonstrate how errors can be identified & handled. In real-world scenarios, error handling typically involves logging errors, rolling back transactions, or taking corrective

-- actions.



-- We can encapsulate reusable error-handling logic in a stored procedure. For example:

CREATE OR ALTER PROC dbo.ErrInsertHandler
AS
SET NOCOUNT ON;

IF ERROR_NUMBER() = 2627
	BEGIN
		PRINT 'Handling PK violation...';
	END;
ELSE IF ERROR_NUMBER() = 547
	BEGIN
		PRINT 'Handling CHECK/FK constraint violation...';
	END;
ELSE IF ERROR_NUMBER() = 515
	BEGIN
		PRINT 'Handling NULL violation...';
	END;
ELSE IF ERROR_NUMBER() = 245
	BEGIN
		PRINT 'Handling conversion error...';
	END;

PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
PRINT 'Error Message: ' + ERROR_MESSAGE();
PRINT 'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10));
PRINT 'Error State: ' + CAST(ERROR_STATE() AS VARCHAR(10));
PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10));
PRINT 'Error Proc: ' + COALESCE(ERROR_PROCEDURE(), 'Not within proc');
GO

-- We can then invoke this procedure from a CATCH block. If the error is one we want to handle locally, we execute the procedure; otherwise, we re-throw the error:

BEGIN TRY
	INSERT INTO dbo.Employees(empid, empname, mgrid)
	VALUES(1, 'Emp1', NULL);
END TRY
BEGIN CATCH
	IF ERROR_NUMBER() IN (2627, 547, 515, 245)
		EXEC dbo.ErrInsertHandler
	ELSE
		THROW;
END CATCH;

-- This approach allows us to centralise & maintain reusable error-handling logic in one place, improving consistency & maintainability across our codebase.