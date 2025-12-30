----------------------

-- Inserting Data

----------------------

-- T-SQL offers several statements for inserting data into tables: INSERT VALUES, INSERT SELECT, INSERT EXEC, SELECT INTO, & BULK INSERT. We'll first review these statements, then cover tools for generating keys, including the IDENTITY & SEQUENCE object.



------------------------------------
-- The INSERT VALUES Statement
------------------------------------

-- We use the standard INSERT VALUES statement to insert rows into a table based on explicitly specified values. To practice using this & other insertion statements, we'll work with a table called `dbo.Orders` in the `TSQLV6` database. Run the following

-- code to create the `dbo.Orders` table:

USE TSQLV6;

DROP TABLE IF EXISTS dbo.Orders;

CREATE TABLE dbo.Orders (
	orderid		INT			NOT NULL
		CONSTRAINT PK_Orders PRIMARY KEY,
	orderdate	DATE		NOT NULL
		CONSTRAINT DFT_orderdate DEFAULT(SYSDATETIME()),
	empid		INT			NOT NULL,
	custid		VARCHAR(10) NOT NULL
);



-- The following example demonstrates how to use INSERT VALUES to insert a single row into the `dbo.Orders` table:

INSERT INTO dbo.Orders(orderid, orderdate, empid, custid)
VALUES (10001, '20220212', 3, 'A');



-- Specifying the target column names immediately after the table name is optional, but doing so gives us control over how values map to columns, rather than relying on the order defined in the CREATE TABLE statement. In T-SQL, the INTO keyword is also

-- optional.



-- If a column value is not provided, SQL Server will use a default value if one has been defined. If no default is defined but the column allows NULL, a NULL value is inserted instead. If the column does not allow NULLs, & no default value exists, the 

-- INSERT statement will fail. For example, the following statement omits a value for `orderdate`, which will be populated automatically using the default (`SYSDATETIME()`):

INSERT INTO dbo.Orders(orderid, empid, custid)
VALUES (10002, 5, 'B');



-- T-SQL also supports an enhanced VALUES clause that allows us to insert multiple rows in a single statement, with each row separated by a comma. For example, the following statement inserts four rows into the `dbo.Orders` table:

INSERT INTO dbo.Orders (orderid, orderdate, empid, custid)
VALUES (10003, '20220213', 4, 'B'),
	   (10004, '20220214', 1, 'A'),
	   (10005, '20220213', 1, 'C'),
	   (10006, '20220215', 3, 'C');

-- This statement executes as a single transaction -- if any row fails to insert, none of the rows are inserted. 



-- The enhanced VALUES clause can also serve as a table value constructor for building derived tables:

SELECT *
FROM (VALUES (10003, '20220213', 4, 'B'),
		     (10004, '20220214', 1, 'A'),
		     (10005, '20220213', 1, 'C'),
		     (10006, '20220215', 3, 'C'))
	AS O(orderid, orderdate, empid, custid);

-- After the parentheses containing the table value constructor, we assign a table alias (`O` in this case). Following the table alias, we define the column aliases in parentheses.



------------------------------------
-- The INSERT SELECT Statement
------------------------------------

-- The standard INSERT SELECT statement inserts a set of rows returned by a SELECT query into a target table. Its syntax is similar to INSERT VALUES, but instead of using a VALUES clause, we provide a SELECT query that produces the rows to insert. For

-- example, the following code inserts into the `dbo.Orders` table the result of a query against `Sales.Orders` table, returning only the orders shipped to the United Kingdom:

INSERT INTO dbo.Orders(orderid, orderdate, empid, custid)
	SELECT orderid, orderdate, empid, custid
	FROM Sales.Orders
	WHERE shipcountry = N'UK';

SELECT * FROM dbo.Orders;

-- As with INSERT VALUES, we can specify the target column names explicitly after the table name -- this is recommended for clarity & to ensure correct value-to-column mapping. The behaviour regarding default constraints & column nullability is also 

-- the same:

	-- If a column has a default value & no value is provided, the default is used.

	-- If no default is defined but the column allows NULL, a NULL is inserted.

	-- If neither is possible, the statement fails.

-- The INSERT SELECT statement executes as a single transaction: if any row fails to insert, none of the rows are inserted.



-----------------------------------
-- The INSERT EXEC Statement
-----------------------------------

-- We can use the INSERT EXEC statement to insert a result set returned by a stored procedure or a dynamic SQL batch into a batch table. The INSERT EXEC statement is similar in syntax & concept to INSERT SELECT, but instead of a SELECT query, it executes

-- an EXEC statement. For example, the following code creates a stored procedure named `Sales.GetOrders`, which returns orders shipped to a specified input country (provided through the `@country` parameter):

CREATE OR ALTER PROC Sales.GetOrders
	@country as NVARCHAR(40)
AS 
SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE shipcountry = @country;
GO

-- To test the stored procedure, execute it with the input country `N'France'`:

EXEC Sales.GetOrders @country = N'France';



-- By using an INSERT EXEC statement, we can insert the result set returned from the procedure into the `dbo.Orders` table:

INSERT INTO dbo.Orders(orderid, orderdate, empid, custid)
EXEC Sales.GetOrders @country = N'France';

SELECT * FROM dbo.Orders;



-----------------------------------
-- The SELECT INTO Statement
-----------------------------------

-- The SELECT INTO statement is a nonstandard T-SQL extension that creates a target table & populates it with the result set of a query. By nonstandard, we mean that is not part of the ISO or ANSI SQL standards. Unlike the other insertion statements,

-- SELECT INTO cannot be used to insert data into an existing table -- it always creates a new one. In terms of syntax, we add the `INTO <target_table_name>` clause immediately before the FROM clause of the SELECT query whose result set we want to use.

-- For example, the following code creates a table named `dbo.Orders` & populates it with all rows with `Sales.Orders`:

DROP TABLE IF EXISTS dbo.Orders;

SELECT orderid, orderdate, empid, custid
INTO dbo.Orders
FROM Sales.Orders;

SELECT * FROM dbo.Orders;

-- The target table's structure & data are derived from the source table. SELECT INTO copies the base structure -- such as column names, data types, nullability, & identity properties -- along with the data itself. However, it does not copy constraints,

-- indexes, triggers, column properties, or permissions from the source. If these are needed in the target table, they must be created manually afterward.



-- If we need to use SELECT INTO with set operations, we place the INTO clause immediately before the FROM clause of the first query in the set operation. For example, the following code creates a table called `dbo.Locations` & populates it with the result

-- of an EXCEPT operation, returning locations that exist for customers but not for employees:

DROP TABLE IF EXISTS dbo.Locations;

SELECT country, region, city
INTO dbo.Locations
FROM Sales.Customers

EXCEPT

SELECT country, region, city
FROM HR.Employees;

SELECT * FROM dbo.Locations;



---------------------------------
-- The BULK INSERT Statement
---------------------------------

-- We use the BULK INSERT statement to load data from a file into a existing table. The statement specifies the target table, the source file, & a set of options that control how the file is read. A variety of options are available, including the data file

-- type (for example, `'char'` or `'native'`), the field terminator, the row terminator, & others -- all of which are documented in full in the SQL Server documentation.



-- For example, the following code bulk inserts the contents of the file "orders.txt" into the `dbo.Orders` table. It specifies that the data file type is `'char'`, the field terminator is a comma, & the row terminator is a newline character:

BULK INSERT dbo.Orders FROM 'C:\Users\yuj22\Desktop\TSQL Fundamentals Lesson Files\Chapter 8\orders.txt'
WITH (
	DATAFILETYPE = 'char',
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n'
);

SELECT * FROM dbo.Orders;

-- If you run this statement, remember to update the file path to match the location of your own "orders.txt" file.



---------------------------------------------------------
-- The Identity Property & the Sequence Object
---------------------------------------------------------

-- SQL Server provides two built-in mechanisms for automatically generating numeric keys: the IDENTITY column property & the SEQUENCE object. The IDENTITY property works well in many scenarios but comes with several limitations. The SEQUENCE object was

-- introduced to address many of these limitations & offers greater flexibility & control.



---------------
-- Identity
---------------

-- The IDENTITY property is a standard column property that enables automatic generation of numeric values. It can be defined on any column that uses a numeric data type with a scale of zero (that is, no fractional part). When defining the property, we can

-- optionally specify a seed (the first value) & an increment (the step value). If we omit these, SQL Server uses a default of 1 for both.



-- This property is most commonly used to generate surrogate keys -- keys that are system-generated rather than derived from application data. For example, the following code creates a table named `dbo.T1`:

DROP TABLE IF EXISTS dbo.T1;

CREATE TABLE dbo.T1 (
	keycol	INT			NOT NULL IDENTITY(1, 1)
		CONSTRAINT PK_T1 PRIMARY KEY,
	datacol VARCHAR(10) NOT NULL
		CONSTRAINT CHK_T1_datacol CHECK(datacol LIKE '[ABCDEFGHIJKLMNOPQRSTUVWXYZ]%')
);

-- The table defines `keycol` as an identity column with a seed & increment of 1. It also includes a column `datacol`, constrained by a CHECK condition requiring values to start with an alphabetical character.



-- When inserting rows, we must omit the identity column entirely. For example, the following code inserts three rows into the table, specifying values only for `datacol`:

INSERT INTO dbo.T1(datacol)
VALUES ('AAAAA'),
	   ('CCCCC'),
	   ('BBBBB');

-- SQL Server automatically generates values for `keycol`. We can verify them by querying the table:

SELECT * FROM dbo.T1;



-- We can refer to the identity column by its name (e.g., `keycol`) or by using the generic `$identity` reference:

SELECT $identity FROM dbo.T1;



-- When SQL Server inserts a new row, it calculates the new identity value based on the current value & the increment. To retrieve the identity value most recently generated in the session, use one of the following functions:

	-- `@@IDENTITY`: returns the last identity value generated by the session, regardless of scope. For example, it includes identity values created in triggers fired by an INSERT.

	-- `SCOPE_IDENTITY()`: returns the last identity value generated in the current scope (for example, the same procedure).

-- Except in rare cases where scope doesn't matter, we should use `SCOPE_IDENTITY()`:

DECLARE @new_key AS INT;

INSERT dbo.T1(datacol) VALUES('AAAAA');

SET @new_key = SCOPE_IDENTITY();

SELECT @new_key as new_key;



-- Both ``@@IDENTITY` & SCOPE_IDENTITY return the last identity value generated in the current session. Inserts from other sessions do not affect these functions. If you need to know the current identity value for a table regardless of session, use

-- `IDENT_CURRENT(<table_name>)`:

SELECT SCOPE_IDENTITY() AS [SCOPE_IDENTITY],
	@@identity as [@@identity],
	IDENT_CURRENT(N'dbo.T1') AS [IDENT_CURRENT];

-- If this query runs in a new session with no inserts, both `@@IDENTITY` & `SCOPE_IDENTITY()` will return NULL, while `IDENT_CURRENT()` will return the current identity value 4.



-- One important behaviour of the identity property is that changes to the current identity value are not rolled back if an INSERT fails or if the transaction is rolled back. For example:

INSERT INTO dbo.T1(datacol) VALUES ('12345');

-- This statement fails because it violated the CHECK constraint. Even so, the identity counter still advances -- from 4 to 5.

INSERT INTO dbo.T1(datacol) VALUES ('EEEEE');

-- Query the table:

SELECT * FROM dbo.T1;

-- Notice a gap between the values 4 & 6 in the output.



-- SQL Server can also introduce gaps in identity values due to identity value caching, which improves performance. If the SQL Server process stops unexpectedly (for example, due to power failure), cached identity values are lost. Because of this, we

-- should use the identity property only when gaps between key values are acceptable. If gaps are unacceptable, we'll need to implement a custom key-generation mechanism.



-- The identity property has some notable limitations:

	-- We cannot add or remove an identity property from an existing column. Making such changes requires an offline operation involving table recreation. 
	
	-- We cannot directly update an identity column.

-- However, we can insert explicit identity values by enabling the IDENTITY_INSERT option for the table:

SET IDENTITY_INSERT dbo.T1 ON;
INSERT INTO dbo.T1(keycol, datacol) VALUES (5, 'FFFFF');
SET IDENTITY_INSERT dbo.T1 OFF;

-- When we turn IDENTITY_INSERT off, SQL Server updates the current identity value only if the explicit value inserted was greater than the existing identity value. Because the current identity value before this insert was 6, & the explicit insert used a

-- lower value, 5, the current identity value remains 6. The next insert will therefore generate the value 7:

INSERT INTO dbo.T1(datacol) VALUES ('GGGGG');

SELECT * FROM dbo.T1;



-- Finally, note that the identity property itself does not enforce uniqueness. Because we can insert explicit identity values with IDENTITY_INSERT, duplicates are possible. To guarantee uniqueness, we must define a PRIMARY KEY or UNIQUE constraint on

-- the identity column.



----------------
-- Sequence
----------------

-- T-SQL supports the standard sequence object as an alternative to identity columns for generating numeric keys. The sequence object is more flexible than identity in several ways, making it the preferred choice in many scenarios.



-- One major advantage of the sequence object is that, unlike identity, it's not tied to a specific column or table -- it's an independent database object. We can invoke it to generate a value whenever needed, even across multiple tables. For example, we

-- could use a single sequence object to maintain nonconflicting keys across several tables.



-- To create a sequence object, use the CREATE SEQUENCE statement. The only required element is the sequence name, though defaults may not always be suitable.



-- If you don't specify a data type, SQL Server defaults to BIGINT. To use a different type, include `AS <type>`. The data type must be a numeric type with a scale of zero (for example, INT, BIGINT, `DECIMAL(10, 0)`).



-- Unlike identity, a sequence supports explicit minimum & maximum values using `MINVALUE <val>` & `MAXVALUE <val>`. If omitted, SQL Server assumes the full range supported by the data type (e.g., -2,147,483,648 to 2,147,483,648 for INT).



-- Another feature unavailable in identity columns is cycling. When cycling is enabled (CYCLE), the sequence restarts at the minimum value after reaching the maximum. By default, sequences are created with NO CYCLE.



-- Like identity, we can specify a starting value (`START WITH <val>`) & an increment (`INCREMENT BY <val>`). If not specified, the defaults are the minimum value & 1, respectively.



-- The following example creates a sequence to geenrate order IDs. It uses an INT data type, starts with 1, increments by 1, & allows cycling:

CREATE SEQUENCE dbo.SeqOrderIDs AS INT
	MINVALUE 1
	CYCLE;

-- Here, we explicitly specified the data type, minimum value, & cycling option because they differ from the defaults. We omitted the maximum, starting, & increment values since we're using their defaults.



-- The sequence object supports a cache option (`CACHE <val> | NO CACHE`), which controls how often SQL Server writes the current value to disk. For example, with `CACHE 10000`, SQL Server writes to disk every 10,000 requests & maintains intermediate values

-- in memory. Caching improves performance but may cause gaps in case of an unexpected server shutdown. SQL Server uses a default cache size of 50 (though this value is undocumented & may change).



-- Use the ALTER SEQUENCE command to modify most sequence properties (except data type):

ALTER SEQUENCE dbo.SeqOrderIDs
	NO CYCLE;

-- Available options include:

	-- MINVALUE / MAXVALUE

	-- RESTART WITH

	-- INCREMENT BY

	-- CYCLE / NO CYCLE

	-- CACHE / NO CACHE



-- To generate a new value, use the `NEXT VALUE FOR <sequence_name>` function:

SELECT NEXT VALUE FOR dbo.SeqOrderIDs;

-- Unlike identity, sequences don't require inserting a row to generate a value. We can store the result in a variable for later use:

DROP TABLE IF EXISTS dbo.T1;

CREATE TABLE dbo.T1 (
	keycol	INT			NOT NULL
		CONSTRAINT PK_T1 PRIMARY KEY,
	datacol	VARCHAR(10)	NOT NULL
);

DECLARE @neworderid AS INT = NEXT VALUE FOR dbo.SeqOrderIDs;
INSERT INTO dbo.T1(keycol, datacol) VALUES (@neworderid, 'a');

SELECT * FROM dbo.T1;



-- If we don't need to generate the value beforehand, we can use the function directly in the INSERT statement:

INSERT INTO dbo.T1(keycol, datacol)
VALUES (NEXT VALUE FOR dbo.SeqOrderIDs, 'b');

SELECT * FROM dbo.T1;

-- We can even use `NEXT VALUE FOR` in an UPDATE statement:

UPDATE dbo.T1
SET keycol = NEXT VALUE FOR dbo.SeqOrderIDs;

SELECT * FROM dbo.T1;



-- To retrieve sequence information, query the `sys.sequences` catalog view. For example, to get the current value of `dbo.SeqOrderIDs`:

SELECT current_value
FROM sys.sequences
WHERE OBJECT_ID = OBJECT_ID(N'dbo.SeqOrderIDs');



-- SQL Server extends the standard sequence functionality with several useful features:

	-- 1. We can control the order of assigned sequence values in a multi-row insert using an OVER clause:

INSERT INTO dbo.T1(keycol, datacol)
SELECT NEXT VALUE FOR dbo.SeqOrderIDs OVER (ORDER BY hiredate),
	LEFT(firstname, 1) + LEFT(lastname, 1)
FROM HR.Employees;

SELECT * FROM dbo.T1;

	-- 2. We can also define a column default based on a sequence:

ALTER TABLE dbo.T1
	ADD CONSTRAINT DFT_T1_keycol
		DEFAULT (NEXT VALUE FOR dbo.SeqOrderIDs)
		FOR keycol;

	-- Now, when we insert rows into the table, we don't have to indicate a value for `keycol`:

INSERT INTO dbo.T1(datacol) VALUES ('c');

SELECT * FROM dbo.T1;



-- Unlike identity, which can't be added or removed from an existing column, a sequence-based default constraint can be easily added or dropped:

ALTER TABLE dbo.T1 DROP CONSTRAINT DFT_T1_keycol;



-- The stored procedure `sp_sequence_get_range` allows allocating a block of sequence values efficiently:

DECLARE @first AS SQL_VARIANT;

EXEC sys.sp_sequence_get_range
	@sequence_name = N'dbo.SeqOrderIDs',
	@range_size = 1000000,
	@range_first_value = @first OUTPUT;

SELECT @first;

-- Running this twice will return two values differing by 1,000,000.



-- As with identity columns, sequences do not guarantee gap-free values. If a transaction rolls back after generating a sequence value, that value is not reused. Additionally, cached sequences can result in gaps if SQL Server stops unexpectedly.



-- When you're done, run the following code for cleanup:

DROP TABLE IF EXISTS dbo.T1;
DROP SEQUENCE IF EXISTS dbo.SeqOrderIDs;


