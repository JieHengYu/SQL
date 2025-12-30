------------------------------

-- Querying Metadata

------------------------------

-- SQL Server provides tools for getting information about the metadata of objects, such as information about tables in a database & columns in a table. Those tools include catalog views, information schema views, & system stored procedures & functions.



---------------------
-- Catalog Views
---------------------

-- Catalog views provide detailed information about objects in the database, including information that is specific to SQL Server. For example, if we want to list the tables in a database along with their schema names, we can query the `sys.tables` view as 

-- follows:

USE TSQLV6;

SELECT SCHEMA_NAME(schema_id) AS table_schema_name,
	name AS table_name
FROM sys.tables;

-- The SCHEMA_NAME function is used to convert the schema ID integer to its name.



-- To get information about columns in a table, we can query the `sys.column` tabe. For example, the following code returns information about coluumns in the `Sales.Orders` table, including column names, data types (with the system type ID translated to a name

-- by using the TYPE_NAME function), maximum length, collation name, & nullability:

SELECT name as column_name,
	TYPE_NAME(system_type_id) AS column_type,
	max_length,
	collation_name,
	is_nullable
FROM sys.columns;



----------------------------------
-- Information Schema Views
----------------------------------

-- SQL Server supports a set of views that reside in a schema called INFORMATION_SCHEMA & provide metadata information in a standard manner. That is, the views are defined in the SQL standard, so naturally they don't cover metadata aspects or objects specific

-- to SQL Server (such as indexing).



-- For example, the following query against the INFORMATION_SCHEMA.TABLES view lists the base tables in the current database along with their schema names:

SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = N'BASE TABLE';

-- The following query against the INFORMATION_SCHEMA.COLUMNS view provides most of the available information about columns in the `Sales.Orders` table:

SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, COLLATION_NAME, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = N'Sales'
	AND TABLE_NAME = N'Orders';



----------------------------------------------
-- System Stored Procedures & Functions
----------------------------------------------

-- System stored procedures & functions internally query the system catalog & return more "digested" metadata information. Here are a few examples.



-- The `sys.sp_tables` stored procedure returns a list of objects (such as tables & views) that can be queries in the current database:

EXEC sys.sp_tables;



-- The `sys.sp_help` procedure accepts an object name as input & returns multiple result sets with general information about the object, & also information about columns, indexes, constraints, & more. For example, the following code returns detailed information

-- about the `Sales.Orders` table:

EXEC sys.sp_help
	@objname = N'Sales.Orders';



-- The `sys.sp_columns` procedure returns information about columns in an object. For example, the following code returns information about columns in the `Sales.Orders` table:

EXEC sys.sp_columns
	@table_name = N'Orders',
	@table_owner = N'Sales';



-- The `sys.sp_helpconstraint` procedure returns information about constraints in an object. For example, the following code returns information about constraints in the `Sales.Orders` table:

EXEC sys.sp_helpconstraint 
	@objname = N'Sales.Orders';



-- One set of functions returns infromation about properties of entities, such as the SQL Server instance, database, object, column, & so on. The SERVERPROPERTY function returns the requested property of the current instance. For example, the following code

-- returns the collation of the current instance:

SELECT SERVERPROPERTY('Collation');



-- The DATABASEPROPERTYEX function returns the requested property of the specified database name. For example, the following code returns the collation of the `TSQLV6` database:

SELECT DATABASEPROPERTYEX(N'TSQLV6', 'Collation');



-- The OBJECTPROPERTY function returns the requested property of the specified object name. For example, the output of the foloowing code indicates whether the `Sales.Orders` table has a primary key:

SELECT OBJECTPROPERTY(OBJECT_ID(N'Sales.Orders'), 'TableHasPrimaryKey');

-- Notice the nesting of the function OBJECT_ID within OBJECTPROPERTY. The OBJECTPROPERTY function expects an object ID & not a name, so the OBJECT_ID function is used to return the ID of the `Sales.Orders` table.



-- The COLUMNPROPERTY function returns the requested property of a specified column. For example, the output of the following code indicates whether ths `shipcountry` column in the `Sales.Orders` table is nullable:

SELECT COLUMNPROPERTY(OBJECT_ID(N'Sales.Orders'), N'shipcountry', 'AllowsNull');





