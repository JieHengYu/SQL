-----------------

-- Variables

-----------------

-- Variables are used to temporarily store data values for later use within the same batch in which they are declared. A batch is one or more T-SQL statements sent to Microsoft SQL Server for execution as a single unit.



-- Use the DECLARE statement to declare one or more variables, & use the SET statement to assign a value to a single variable. For example, the following code declares a variable named `@i` of type INT & assigns it the value 10: 

USE TSQLV6;

DECLARE @i AS INT;
SET @i = 10;

-- Alternatively, a variable can be declared & initialised in a single statement:

DECLARE @i AS INT = 10;



-- When assigning a value to a scalar variable, the value must be the result of a scalar expression. This expression can be a scalar subquery. For example, the following code declares a variable named `@empname` & assigns it the

-- result of a scalar subquery that returns the full name of the employee with an ID of 3:

DECLARE @empname AS NVARCHAR(61);

SET @empname = (SELECT firstname + N' ' + lastname
				FROM HR.Employees
				WHERE empid = 3);

SELECT @empname AS empname;



-- The SET statement can assign a value to only one variable at a time. As a result, assigning values to multiple variables require multiple SET statements. This can introduce unnecessary overheard when retrieving multiple 

-- attributes from the same row. For example, the following code uses two SET statements to retrieve the first & last name of the employee with an ID of 3:

DECLARE @firstname AS NVARCHAR(20), @lastname AS NVARCHAR(40);

SET @firstname = (SELECT firstname
				  FROM HR.Employees
				  WHERE empid = 3);
SET @lastname = (SELECT lastname
				 FROM HR.Employees
				 WHERE empid = 3);

SELECT @firstname AS firstname, @lastname AS lastname;

-- T-SQL also supports a nonstandard assignment SELECT statement, which allows us to query data & assign multiple values from the same row to multiple variables using a single statement:

DECLARE @firstname AS NVARCHAR(20), @lastname AS NVARCHAR(40);

SELECT @firstname = firstname,
	@lastname = lastname
FROM HR.Employees
WHERE empid = 3;

SELECT @firstname AS firstname, @lastname AS lastname;

-- The assign SELECT behaves predictably when exactly one row qualifies. However, if the query returns more than one row, the statement does not fail. Instead, the assignments occur once per qualifying row, with each row

-- overwriting the previous values. When the statement completes, the variables contain the values from the last row SQL Server happened to process. For example, the following assignment SELECT has two qualifying rows:

DECLARE @empname AS NVARCHAR(61);

SELECT @empname = firstname + N' ' + lastname
FROM HR.Employees
WHERE mgrid = 2;

SELECT @empname AS empname;

-- The value stored in `@empname` depends on the order in which SQL Server accesses the rows. In one execution, the result might be "Sven Mortensen", while in another, it could be "Judy Lew".



-- The SET statement is generally safer than the assignment SELECT because it requires the use of a scalar subquery. A scalar subquery raises a runtime error if it returns more than one value. For example, the following code

-- fails because the subquery returns multiple rows:

DECLARE @empname AS NVARCHAR(61);

SET @empname = (SELECT firstname + N' ' + lastname
				FROM HR.Employees
				WHERE mgrid = 2);

SELECT @empname AS empname;

-- Because the assignment fails, the variable remains NULL, which is the default value for variables that are declared but not initialised. The code returns the following error: "Subquery returned more than 1 value. This is not

-- permitted when the subquery follows =, !=, <, <=, >, >=, or when the subquery is used as an expression.
