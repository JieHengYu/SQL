-----------------

-- Routines

-----------------

-- Routines are programmable database objects that encapsulate code used either to calculate a result or to perform an action. SQL Server supports three types of routines:

	-- User defined functions (UDFs)

	-- Stored procedures

	-- Triggers

-- In SQL Server, routines can be implemented either in T_SQL or in Microsoft .NET code by using CLR integration. In this discussion, we'll focus exclusively on routines in T-SQL.



-------------------------------
-- User-Defined Functions
-------------------------------

-- The purpose of a user-defined function (UDF) is to encapsulate logic that performs a calculation -- optionally based on input parameters -- & returns a result.



-- SQL Server supports two types of UDFs:

	-- Scalar UDFs, which return a single value

	-- Table-valued UDFs, which return a table

-- One key advantage of UDFs is that they can be incorporated directly into queries. Scalar UDF can appear anywhere an expression that returns a single value is allowed (for example, in the SELECT list). Table-valued UDFs can

-- appear in the FROM clause of a query. The example in this section demonstrates a scalar UDF.



-- UDFs are not allowed to have side effects. This clearly means that a UDF cannot modify schema or data in a database. However, other forms of side effects are less obvious. For example, invoking the RAND function to return a 

-- random value or the NEWID function to generate a globally unique identifier (GUID) introduces side effects. When RAND is called without a seed, SQL Server generates a seed based on the previous invocation, requiring the 

-- engine to maintain internal state. Similarly, each call to NEWID relies on system-maintained state to ensure uniqueness across calls. Because both functions rely on such state, they are considered to have side effects & 

-- therefore cannot be used inside UDFs.



-- The following example creates a scalar UDF named `dbo.GetAge`. The function calculates the age of a person based on a specified birth date (`@birthdate`) & an event date (`@eventdate`):

USE TSQLV6;
GO

CREATE OR ALTER FUNCTION dbo.GetAge (
	@birthdate AS DATE,
	@eventdate AS DATE
)
RETURNS INT
AS 
BEGIN
	RETURN
		DATEDIFF(year, @birthdate, @eventdate)
			- CASE WHEN 100 * MONTH(@eventdate) + DAY(@eventdate)
					    < 100 * MONTH(@birthdate) + DAY(@birthdate)
				   THEN 1 ELSE 0
			  END;
	END;
GO

-- This function calculates age as the difference (in years) between the birth year & the event year, minus one year if the event month & day occur earlier in the calendar year than the birth month & day. The expression 

-- `100 * month + day` is a simple technique for combining the month & day into a single integer. For example, February 12 evaluates to 212.



-- Note that a function body can contain more than just a single RETURN statement. It may include flow control elements, intermediate calculations, & other logic. However, every UDF must ultimately return a value using a RETURN

-- clause.



-- The following query demonstrates how to use the `GetAge()` function in a SELECT list. It calculates the current age of each employee in the `HR.Employees` table:

SELECT empid, firstname, lastname, birthdate,
	dbo.GetAge(birthdate, SYSDATETIME()) AS age
FROM HR.Employees;

-- Naturally, the values returned in the `age` column depend on the date on which the query is executed.



---------------------------
-- Stored Procedures
---------------------------

-- Stored procedures are routines that encapsulate code to perform one or more tasks. They can aceept input parameters, return output parameters, & produce result sets from queries. Unlike user-defined functions, stored

-- procedures are allowed to have side effects. They can modify data & apply schema changes within the database.



-- Compared to using ad-hoc SQL code, stored procedures offer several important advantages:

	-- Encapsulation of logic:

		-- Stored procedures centralise logic in a single database object. If the implementation needs to change, the modification is made in one place using the ALTER PROC command, & all callers automatically use the updated

		-- version.

	-- Improved security control:

		-- Stored procedures allow fine-grained permission management. A user can be granted permission to execute a procedure without being granted direct permissions on the underlying tables or schema. For example, suppose we

		-- want to allow certain users to delete a customer from the database, but we do not want to grant them directly permission to delete rows from the `Sales.Customers` table. We may also want to ensure that each deletion

		-- request is validated (for example, by checking for open orders & outstanding balances) & audited. By granting users permission to execute a stored procedure that performs these checks, rather than granting direct table

		-- permissions, we ensure that all validation & auditing logic is always enforced. In addition, parameterised stored procedures can help reduce the risk of SQL injection, especially when they replace ad-hoc SQL submitted

		-- from client applications.

	-- Centralised error handling:

		-- Stored procedures allow all error-handling logic to be implemented in one place, enabling corrective actions to be taken silently when appropriate.

	-- Performance benefits:

		-- Stored procedures often yield better peformance than ad-hoc SQL. Queries inside stored procedures are typically parameterised, which increases the likelihood of reusing cached execution plans. Another performnace

		-- benefit is reduced network traffic. The client application sends only the procedure name & its parameters to SQL Server. The server executes the entire procedure & returns only the final results, avoiding unnecessary

		-- back-&-forth communication for intermediate steps.



-- The following example creates a stored procedure named `Sales.GetCustomerOrders`. The procedure accepts a customer ID (`@custid`) & a date range (`@fromdate` & `@todate`) as input parameters. It returns a result set containing

-- orders placed by the specified customer during the requested date range, & it returns the number of qualifying rows via an output parameter (`@numrows`):

CREATE OR ALTER PROC Sales.GetCustomerOrders
	@custid AS INT,
	@fromdate AS DATETIME = '19000101',
	@todate AS DATETIME = '99991231',
	@numrows AS INT OUTPUT
AS
SET NOCOUNT ON;

SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE custid = @custid
	AND orderdate >= @fromdate
	AND orderdate < @todate;

SET @numrows = @@rowcount;
GO

-- If a value is not supplied for `@fromdate`, the procedure uses the default value 19000101. Similarly, if a value is not supplied for `@todate`, the procedure uses the default value 99991231. The OUTPUT keyword indicates that

-- `@numrows` is an output parameter.



-- The SET NOCOUNT ON statement suppresses messages that report the number of rows affected by each statement inside the procedure, such as the SELECT statement. This is commonly used to reduce unnecessary network traffic.



-- The following example executes the procedure to retrieve orders placed by the customer with ID 1 during the year 2021. The output parameter `@numrows` is captured in a local variable (`@rc`) & returned to show how many rows

-- were produced by the query:

DECLARE @rc AS INT;

EXEC Sales.GetCustomerOrders
	@custid = 1,
	@fromdate = '20210101',
	@todate = '20220101',
	@numrows = @rc OUTPUT;

SELECT @rc AS numrows;

--If we execute the proceudre again using a customer ID that does not exist in the `Sales.Orders` table (for example, 100), the output parameter indicates that zero rows qualified:

DECLARE @rc AS INT;

EXEC Sales.GetCustomerOrders
	@custid = 100,
	@fromdate = '20210101',
	@todate = '20220101',
	@numrows = @rc OUTPUT;

SELECT @rc AS numrows;



----------------
-- Triggers
----------------

-- A trigger is a special type of stored procedure that cannot be executed explicitly. Instead, a trigger is bound to a specific event. When that event occurs, the trigger fires & its code is executed automatically.



-- SQL Server supports triggers associated with two categories of events:

	-- Data manipulation language (DML) events, such as INSERT, UPDATE, & DELETE

	-- Data definition langauge(DDL) events, such as CREATE TABLE, ALTER TABLE, & DROP TABLE

-- Triggers can be used for a variety of purposes, including auditing changes, enforcing business or integrity rules that cannot be implemented with constraints, & enforcing policies.



-- A trigger executes as part of the same transaction that caused it to fire. As a result, issuing a ROLLBACK TRAN statement inside a trigger rolls back not only the changes made by the trigger itself, but also changes made by

-- the triggering statement.



-- Finally, it is important to note that triggers in SQL Server fire once per statement, not once per affected row.



-------------------
-- DML Triggers
-------------------

-- SQL Server supports two types of DML triggers: AFTER triggers & INSTEAD OF triggers.

	-- An AFTER trigger fires after the associated DML event completes successfully & can be defined only on permanent tables.

	-- An INSTEAD OF trigger fires in place of the associated DML event & can be defined on both permanent tables & views.



-- Inside a DML trigger, SQL server provides access to two special pseudo-tables named `inserted` & `deleted`. These tables contain the rows affected by the modification that causes the trigger to fire:

	-- The `inserted` table contains the new image of affected rows for INSERT & UPDATE operations.

	-- The `deleted` table contains the old image of affected rows for DELETE & UPDATE operations.

-- Remember that INSERT, UPDATE, & DELETE actions can be initiated not only by the corresponding DML statements, but also the MERGE statement.



-- In the case of INSTEAD OF triggers, the `inserted` & `deleted` tables contain the rows that would have been affected by the triggering modification, had SQL Server executed it directly.

		

-- The following example demonstrates a simple AFTER INSERT trigger that audits insert operations on a table. First, run the following code to create a table named `dbo.T1` in the current database, along with a table named 

-- `dbo.T1_Audit` to store audit information for insertions into `dbo.T1`:

DROP TABLE IF EXISTS dbo.T1_Audit, dbo.T1;

CREATE TABLE dbo.T1 (
	keycol	INT			NOT NULL PRIMARY KEY,
	datacol VARCHAR(10) NOT NULL
);

CREATE TABLE dbo.T1_Audit (
	audit_lsn	INT				NOT NULL IDENTITY PRIMARY KEY,
	dt			DATETIME2(3)	NOT NULL DEFAULT(SYSDATETIME()),
	login_name	sysname		NOT NULL DEFAULT(ORIGINAL_LOGIN()),
	keycol		INT				NOT NULL,
	datacol		VARCHAR(10)		NOT NULL
);

-- In the audit table:

	-- The `audit_lsn` column is defined with an IDENTITY property & serves as an audit log serial number.

	-- The `dt` column records the date & time of the insertion using the `SYSDATETIME()` default.

	-- The `login_name` column records the login that performed the insertion using the `ORIGINAL_LOGIN()` function.



-- Next, create an AFTER INSERT trigger named `trg_t1_insert_audit` on the `dbo.T1` table:

CREATE OR ALTER TRIGGER trg_T1_insert_audit ON dbo.T1 AFTER INSERT
AS
SET NOCOUNT ON;

INSERT INTO dbo.T1_Audit(keycol, datacol)
	SELECT keycol, datacol FROM inserted;
GO

-- The trigger simply inserts into the audit table the rows returned from a query against the `inserted` pseudo-table. Columns in `dbo.T1_Audit` that are not listed explicitly in the INSERT statement are populated using their

-- default expressions.



-- To test the trigger, execute the following code:

INSERT INTO dbo.T1(keycol, datacol) VALUES(10, 'a');
INSERT INTO dbo.T1(keycol, datacol) VALUES(30, 'x');
INSERT INTO dbo.T1(keycol, datacol) VALUES(20, 'g');

-- The trigger fires once after every statement. Next, query the audit table:

SELECT audit_lsn, dt, login_name, keycol, datacol
FROM dbo.T1_Audit;

-- The `dt` & `login_name` columns reflect the date & time when each INSERT statement was executed & the login used to connect to SQL Server.



-- When you are finished, run the following code to clean up the objects created for this example:

DROP TABLE dbo.T1_Audit, dbo.T1;



--------------------
-- DDL Triggers
--------------------

-- SQL Server supports DDL triggers, which can be used for purposes such as auditing, policy enforcement, & change management. SQL Server supports the creation of DDL triggers at two different scopes, depending on the scope of 

-- the event:

	-- Database scope

	-- Server scope

-- Azure SQL Database currently supports only database-scoped DDL triggers.



-- We create a database-scoped DDL trigger for events that occur at the database level, such as CREATE TABLE. We create a server-scoped DDL trigger for events that occur at the server level, such as CREATE DATABASE. SQL Server

-- supports only AFTER DDL triggers; it does not support INSTEAD OF DDL triggers.



-- Inside a DDL trigger, we can obtain information about the event that causes the trigger to fire by calling the EVENTDATA() function. This function returns an XML instance containing detailed information about the triggering

-- event. We can use XQuery expressions to extract specific attributes from this XML, such as the event post time, event type, login name, schema name, & object name.



-- The following example creates a table named `dbo.AuditDDLEvents` to store audit information about DDL events:

DROP TABLE IF EXISTS dbo.AuditDDLEvents;

CREATE TABLE dbo.AuditDDLEvents (
	audit_lsn			INT				NOT NULL IDENTITY,
	posttime			DATETIME2(3)	NOT NULL,
	eventtype			sysname			NOT NULL,
	loginname			sysname			NOT NULL,
	schemaname			sysname			NOT NULL,
	objectname			sysname			NOT NULL,
	targetobjectname	sysname			NULL,
	eventdata			XML				NOT NULL,
	CONSTRAINT PK_AuditDDLEvents PRIMARY KEY(audit_lsn)
);

-- Notice that the table includes a column named `eventdata` with the XML data type. In addition to storing individual event attributes in separate columns, the table also stored the complete XML event payload for later

-- inspection for troubleshooting.



-- Next, create a database-scoped DDL trigger named `trg_audit_ddl_events` using the event group `DDL_DATABASE_LEVEL_EVENTS`, which represent all DDL events at the database level:

CREATE OR ALTER TRIGGER trg_audit_ddl_events
	ON DATABASE FOR DDL_DATABASE_LEVEL_EVENTS
AS
SET NOCOUNT ON;

DECLARE @eventdata AS XML = eventdata();

INSERT INTO dbo.AuditDDLEvents(
	posttime, eventtype, loginname, schemaname,
	objectname, targetobjectname, eventdata
)
VALUES (@eventdata.value('(/EVENT_INSTANCE/PostTime)[1]', 'VARCHAR(23)'),
	@eventdata.value('(/EVENT_INSTANCE/EventType)[1]', 'sysname'),
	@eventdata.value('(/EVENT_INSTANCE/LoginName)[1]', 'sysname'),
	@eventdata.value('(/EVENT_INSTANCE/SchemaName)[1]', 'sysname'),
	@eventdata.value('(/EVENT_INSTANCE/ObjectName)[1]', 'sysname'),
	@eventdata.value('(/EVENT_INSTANCE/TargetObjectName)[1]', 'sysname'),
	@eventdata);
GO

-- The trigger code first stores the XML returned by the EVENTDATA() function in the `@eventdata` variable. It then inserts a row into the audit table, extracting individual attributes from the XML using XQuery expressions with

-- the `.value()` method, while also storing the complete XML payload.



-- To test the trigger, run the following DDL statements:

CREATE TABLE dbo.T1(col1 INT NOT NULL PRIMARY KEY);
ALTER TABLE dbo.T1 ADD col2 INT NULL;
ALTER TABLE dbo.T1 ALTER COLUMN col2 INT NOT NULL;
CREATE NONCLUSTERED INDEX idx1 ON dbo.T1(col2);

-- Next, query the audit table to view the captured events:

SELECT * FROM dbo.AuditDDLEvents;

-- You should see one row for each DDL statement, along with detailed metadata describing the event.



-- When you are finished, clean up the objects created for this example:

DROP TRIGGER IF EXISTS trg_audit_ddl_events ON DATABASE;
DROP TABLE IF EXISTS dbo.AuditDDLEvents, dbo.T1;