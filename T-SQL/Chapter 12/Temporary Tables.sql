------------------------

-- Temporary Tables

------------------------

-- When we need to store data temporarily, it is often undesirable, or unnecessary, to use permanent tables. In many scenarios, we want the data to be visible only within the current session, or even only within the scope of the

-- current batch. A common example is storing intermediate results during data processing. Another situation in which temporary storage is useful is when we do not have permission to create permanent tables in a user database.



-- To address these needs, SQL Server supports several forms of temporary table-like objects that are often more convenient than permanent tables. Specifically, SQL Server provides three kinds of temporary tables: local temporary

-- tables, global temporary tables, & table variables. The following sections describe each of these options & demonstrate their use with code examples.



--------------------------------
-- Local Temporary Tables
--------------------------------

-- We create a local temporary table by prefixing its name with a single number sign (#), for example `#T1`. All three types of temporary tables -- local temporary tables, global temporary tables, & table variables -- are created

-- in the `tempdb` database.



-- A local temporary table is visible only to the session that created it, & only within the creating scope & any inner scopes in the call stack (such as inner stored procedures, triggers, & dynamic SQL batches). SQL Server

-- automatically drops the table when the creating scope goes out of scope.



-- For example, suppose a stored procedure `Proc1` calls `Proc2`, which in turn calls `Proc3`, which then calls `Proc4`. If `Proc2` creates a local temporary table named `#T1` before calling `Proc3`, the table `#T1` is visible

-- to `Proc2`, `Proc3`, & `Proc4`, but not to `Proc1`. The table is automatically destroyed when `Proc2` finishes execution.



-- If a local temporary table is created in an ad hoc batch at the outermost nesting level of a session (that is when the value returned by `@@NESTLEVEL` is 0), the table remains visible to all subsequent batches in that session.

-- In this case, SQL Server drops the table automatically only when the creating session disconnects.



-- One might wonder how SQL Server avoids name conflicts when multiple sessions create local temporary tables with the same name. Internally, SQL Server appends a unique suffix to the table name, ensuring uniqueness within

-- `tempdb`. As developers, we do not need to be concerned with this internal naming. We always refer to the table using the name we defined (for example, `#T1`), & only the creating session can access it.



-- A common use case for local temporary tables is storing intermediate results during processing -- for example, accumulating data inside a loop & querying it later. Another important scenario is when the result of an expensive

-- operation must be reused multiple times.



-- Consider the following examples. Suppose we need to join the `Sales.Orders` & `Sales.OrderDetails` tables, aggregating order quantities by order year, & then join two instances of that aggregated result to compare each year's

-- total quantity with the previous year's total. In the sample database, these tables are small, but in real-world systems, they may contain millions of rows.



-- One option is to use table expressions. However, table expressions are virtual, meaning that the expensive work -- scanning the base tables, performing the join, & aggregating the data -- would need to be performed each time

-- the expression is referenced. Instead, it is often more efficient to perform the expensive work once, store the result in a local temporary table, & then reference that temporary table multiple times. This approach is 

-- especially effective when the aggregated result is small, such as one row per order year.



-- The following code demonstrates his pattern using a local temporary table:

USE TSQLV6;

DROP TABLE IF EXISTS #MyOrderTotalByYear;
GO

CREATE TABLE #MyOrderTotalByYear (
	orderyear	INT NOT NULL PRIMARY KEY,
	qty			INT NOT NULL
);

INSERT INTO #MyOrderTotalByYear(orderyear, qty)
SELECT YEAR(O.orderdate) AS orderyear,
	SUM(OD.qty) AS qty
FROM Sales.Orders AS O
	INNER JOIN Sales.OrderDetails AS OD
		ON O.orderid = OD.orderid
GROUP BY YEAR(orderdate);

SELECT Cur.orderyear, Cur.qty AS curyearqty, Prv.qty AS prvyearqty
FROM #MyOrderTotalByYear AS Cur
	LEFT OUTER JOIN #MyOrderTotalByYear AS Prv
		ON Cur.orderyear = Prv.orderyear + 1;

-- To verify that a local temporary table is visible only to the creating session, try querying it from a different session:

	-- `SELECT orderyear, qty FROM #MyOrderTotalByYear;`

-- This results in the following error: "Invalid object name '#MyOrderTotalByYear'."



-- When you are finished using the temporary table, return to the original session & explicitly drop it:

DROP TABLE IF EXISTS #MyOrderTotalByYear;

-- Although SQL Server will eventually clean up local temporary tables automatically, it is gneerally good practice to release resources explicitly as soon as we are done working with them.



--------------------------------
-- Global Temporary Tables
--------------------------------

-- A global temporary table is visible to all sessions. SQL Server automatically drops a global temporary table when the session that created it disconnects & there are no active references to the table. We create a global

-- temporary table by prefixing its name with two number signs (##), for example `##T1`.



-- Global temporary tables are useful when we need to share temporary data across multiple sessions. No special permissions are required to access them, & all users have full DDL & DML privileges. This is true even if the table

-- is populated using data from sources to which the target users do not have direct permissions.



-- At the same time, this unrestricted access means that any user can modify or even drop the table. For this reason, global temporary tables should be used with care, & alternative approaches should be considered when data 

-- integrity or isolation is important.



-- The following code creates a global temporary table named `##Globals` with two columns, `id` & `val`:

CREATE TABLE ##Globals (
	id	sysname		NOT NULL PRIMARY KEY,
	val	SQL_VARIANT	NOT NULL
);

-- In this example, the table is intended to mimic the behaviour of global variables, which are not supported in T-SQL. The `id` column uses the `sysname` data type (the data type SQL Server uses internally for identifiers), &

-- the `val` column uses the SQL_VARIANT data type, which can store values of almost any base data type.



-- Because the table is global, any session can insert rows into it. For example, the following code inserts a row representing a variable named `'I'` & initialises it with the integer value 10:

INSERT INTO ##Globals (id, val)
VALUES (N'I', CAST(10 AS INT));

-- Any session can also modify or retrieve data from the table. For instance, the following query returns the current value of the variable `'I'`:

SELECT val 
FROM ##Globals
WHERE id = N'I';



-- Remember that as soon as the session that created the global temporary table disconnects & there are no remaining active references to that table, SQL Server automatically drops it. If needed, any session can explicitly drop

-- the global temporary table using the following statement:

DROP TABLE IF EXISTS ##Globals;



-----------------------
-- Table Variables
-----------------------

-- Table variables share some similarities with local temporary tables, but they also differ from them in important ways. We declare table variables in much the same way as other variables, using the DECLARE statement. Despite

-- a common misconception, table variables do not exist only in memory; like local & global temporary tables, they have a physical presence as tables in the `tempdb` database.



-- As with local temporary tables, table variables are visible only to the session that creates them. However, because table variables are variables, their scope is even more limited: they are visible only within the current

-- batch. Table variables are not visible to inner scopes in the call stack (such as inner stored procedures or dynamical SQL batches), nor are they visible to subsequent batches in the same session.



-- One important difference between table variables & temporary tables relates to transaction handling. If an explicit transaction is rolled back, changes made to temporary tables within that transaction are rolled back as well. 

-- In contrast, changes made to table variables by statements that completed successfully within the transaction are not rolled back. Only changes made by the active statement that failed or was terminated before completion are

-- undone.



-- The distinction can have significant implications when table variables are used inside transactions & should be taken into account during design.



-- The following example revisits the earlier scenario of comparing total order quantities for each order year with the previous year, this time using a table variable instead of a local temporary table:

DECLARE @MyOrderTotalByYear TABLE (
	orderyear	INT NOT NULL PRIMARY KEY,
	qty			INT NOT NULL
);

INSERT INTO @MyOrderTotalByYear(orderyear, qty)
SELECT YEAR(O.orderdate) AS orderyear,
	SUM(OD.qty) AS qty
FROM Sales.Orders AS O
	INNER JOIN Sales.OrderDetails AS OD
		ON O.orderid = OD.orderid
GROUP BY YEAR(orderdate);

SELECT Cur.orderyear, Cur.qty AS curyearqty, Prv.qty AS prvyearqty
FROM @MyOrderTotalByYear AS Cur
	LEFT OUTER JOIN @MyOrderTotalByYear AS Prv
		ON Cur.orderyear = Prv.orderyear + 1;

-- This example is structurally similar to the version that used a local temporary table, with the key difference being the use of a table variable & its batch-level scope. 



-- Note that this particular task does not actually require either a temporary table or a table variable. We can solve it more directly & efficiently by using the LAG window function:

SELECT YEAR(O.orderdate) AS orderyear,
	SUM(OD.qty) AS curyearqty,
	LAG(SUM(OD.qty)) OVER(ORDER BY YEAR(orderdate)) AS prvyearqty
FROM Sales.Orders AS O
	INNER JOIN Sales.OrderDetails AS OD
		ON O.orderid = OD.orderid
GROUP BY YEAR(O.orderdate);



------------------
-- Table Types
------------------

-- A table type allows us to persist a table definition, its metadata, as a reusable database object. Once defined, we can use a table type as the definition for table variables & as the type of input parameters for stored

-- procedures & user-defined functions. Table types are required when working with table-valued parameters (TVPs).



-- The following example creates a table type named `dbo.OrderTotalsByYear` in the current database:

DROP TYPE IF EXISTS dbo.OrderTotalsByYear;

CREATE TYPE dbo.OrderTotalsByYear AS TABLE (
	orderyear	INT NOT NULL PRIMARY KEY,
	qty			INT NOT NULL
);

-- This statement stores the table's schema as a first-class object in the database, allowing it to be reused consistently across multiple modules.



-- Once a table type exists, we can declare table variables based on its definition without repeating the column definitions. Instead, we simply reference the table type by name:

DECLARE @MyOrderTotalsByYear AS dbo.OrderTotalsByYear;

-- This approach promotes consistency & reduces duplication, especially when the same table structure is used in multiple places.



-- The following example demonstrates a complete workflow. It declares a table variable of type `dbo.OrderTotalsByYear`, populates it with the total order quantities by order year, & then queries the results:

DECLARE @MyOrderTotalsByYear AS dbo.OrderTotalsByYear;

INSERT INTO @MyOrderTotalsByYear(orderyear, qty)
SELECT YEAR(O.orderdate) AS orderyear,
	SUM(OD.qty) AS qty
FROM Sales.Orders AS O
	INNER JOIN Sales.OrderDetails AS OD
		ON O.orderid = OD.orderid
GROUP BY YEAR(O.orderdate);

SELECT orderyear, qty FROM @MyOrderTotalsByYear;



-- The value of table types extends beyond code brevity. By centralising table definitions, they help enforce consistent schemas & simplify maintenance. Most importantly, table types enable table-valued parameters, allowing us

-- to pass sets of rows efficiently into stored procedures & functions, something that is not possible with temporary tables or ad hoc table variables alone. 