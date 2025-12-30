--------------------------------------------------------

-- Creating Tables & Defining Data Integrity

--------------------------------------------------------

-- This section describes the fundamentals of creating tables & defining data integrity using T-SQL. 

-- DML, data manipulation language, rather than DDL, data defining language, is the focus of this series of lessons.

-- Still, we need to understand how to create tables & define data integrity. We'll only provide a brief description of the essentials.



-----------------------------
-- Creating Tables
-----------------------------

-- The following code creates a table named `Employees` in the `dbo` schema in the `TSQLV6` database:

USE TSQLV6;

DROP TABLE IF EXISTS dbo.Employees;

CREATE TABLE dbo.Employees (
	empid		INT			NOT NULL,
	firstname	VARCHAR(30) NOT NULL,
	lastname	VARCHAR(30) NOT NULL,
	hiredate	DATE		NOT NULL,
	mgrid		INT			NULL,
	ssn			VARCHAR(20) NOT NULL,
	salary		MONEY		NOT NULL
);

-- The USE statement sets the current database context to that of TSQLV6. It's important to incorporate the USE statement in scripts that create objects to ensure that SQL Server creates the objects in the specified database.

-- THE DROP TABLE IF EXISTS statement (aka DIE) drops the `Employees` table if it already exists in the current database.

-- We can use the CREATE TABLE statement to define a table. We specify the name of the table &, in parentheses, the definition of its attributes (columns).



-- For each attribute, we specify the attribute name, data type, & whether the value can be NULL (called nullability).



-- In the `Employees` table, the attributes `empid` (employee ID) & `mgrid` (manager ID) are each defined with the INT (four-byte integer) data type;

-- the `firstname`, `lastname`, & `ssn` (US Social Security number) are defined as VARCHAR (variable-length character string with the specified maximum supported number of characters);

-- `hiredate` is defined as DATE & `salary` is defined as MONEY.



-- If you don't explicitly specify whether a column allows or disallows NULLs, SQL Server will have to rely on defaults. Standard SQL dictates that when a column's nullability is not specified,

-- the assumption should be NULL (allowing NULLS). It's recommended to define a column as NOT NULL unless you have a compelling reason to support NULLs. If a column is not supposed to allow NULLs & we don't

-- enforce this with a NOT NULL constraint, we can rest assured that NULLs will occur. In the `Employees` table, all columns are defined as NOT NULL except for the `mgrid` column. A NULL in the `mgrid` column 

-- would represent the fact that the employee has no manager, as in the case of the CEO of the organisation.



-------------------------------------
-- Defining Data Integrity
-------------------------------------

-- Declarity data integrity refers to rules enforced directly within the data model, specifically through table definitions. Examples include data type & nullability choices for attributes, as well as

-- structural rules in the model itself. Other common declarative constraints include primary keys, unique constraints, foreign keys, check constraints, & default values. These constraints can be defined when creating a 

-- table with the CREATE TABLE statement, or added later with the ALTER TABLE statement. With the exception of default constraints, all constraint types can also be defined as composite constraints -- that is, applied

-- across multiple attributes.




-------------------------------------
-- Primary Key Constraints
-------------------------------------

-- A primary key enforces the uniqueness of rows & also disallows NULLs in the constraint attribute(s). Each unique combination of values in the constraint attribute(s) can appear only once in the table

-- i.e., they must be distinct. An attempt to define a primary key constraint on a column that does allows NULLs will be rejected. Each table can only have one primary key, though it can consist of multiple columns (a composite constraint).

-- Here's an example of defining a primary key constraint on the `empid` attribute in the `Employees` table that we created above.

ALTER TABLE dbo.Employees
	ADD CONSTRAINT PK_Employees
	PRIMARY KEY (empid);

-- With this primary key in place, we can be assured that all `empid` values will be unique & known. An attempt to insert or update a row such that the constraint would be violated (i.e., duplicate combinations 

-- of the constraint attribute(s) or NULL values in the constraint attribute(s)) will be rejected & result in an error.



-----------------------------
-- Unique Constraints
-----------------------------

-- A unique constraint enforces the uniqueness of rows, allowing us to implement the concept of alternate keys from the relational model in our database. Unlike with primary keys, we can defined multiple

-- unique constraints within the same table. Also unlike with primary keys, a unique constraint is not restricted to columns defined as NOT NULL.

-- The following code defines a unique constraint on the `ssn` column in the `Employees` table:

ALTER TABLE dbo.Employees
	ADD CONSTRAINT UNQ_Employees_ssn
	UNIQUE(ssn);

-- For the purpose of enforcing a unique constraint, SQL Server handles NULLs just like non-NULL values. Consequently, for example, a single-column unique constraint allows only one NULL in the constrained column.

-- However, the SQL standard defines NULL-handling by a unique constraint differently, like so: "A unique constraint on T is satisfied if & only if there do not exist two rows R1 & R2 of T such that R1 & R2 have

-- the same non-NULL values in the unique columns." In other words, only the non-NULL values are compared to determine whether duplicates exist. Consequently, a standard single-column unique constraint would allow 

-- multiple NULLs in the constrained column. To emulate a standard single-column unique constraint in SQL Server, we can use a unique filtered index that filters only non-NULL values. For example, suppose that the 

-- column `ssn` allowed NULLs, & we wanted to create such an index instead of a unique constraint. We would use the following code:

CREATE UNIQUE INDEX idx_ssn_notnull
	ON dbo.Employees(ssn)
	WHERE ssn IS NOT NULL;

-- The index is defined as a unique one, & the filter excludes NULLs from the index, so duplicate NULLs will be allowed in the underlying table, whereas duplicate non-NULL values won't be allowed.



-----------------------------------
-- Foreign Key Constraints
-----------------------------------

-- A foreign key enforces referential integrity. This constraint is defined on one or more attributes in what's called the referencing table & points to candidate key (primary key or unique constraint) attributes in what's

-- called  the referenced table. Note that the referencing & referenced tables can be one & the same. The foreign key's purpose is to restrict the value allowed in the foreign key column(s) to those that exist in the referenced column(s).

-- The following code creates a table called `Orders` with a primary key defined on the `orderid` column:

DROP TABLE IF EXISTS dbo.Orders;

CREATE TABLE dbo.Orders(
	orderid INT			NOT NULL,
	empid	INT			NOT NULL,
	custid	VARCHAR(10)	NOT NULL,
	orderts DATETIME2	NOT NULL,
	qty		INT			NOT NULL,
	CONSTRAINT PK_Orders
		PRIMARY KEY (orderid)
);

-- Suppose you want to enforce an integrity rule that restricts the value supported by the `empid` column in the `Orders` table to the values that exist in the `empid` column in the `Employees` table. We can achieve this 

-- defining a foreign key constraint on the `empid` column in the `Orders` table pointing to the `empid` column in the `Employees` table, like so:

ALTER TABLE dbo.Orders
	ADD CONSTRAINT FK_Orders_Employees
	FOREIGN KEY (empid)
	REFERENCES dbo.Employees(empid);

-- Similarly, if you want to restrict the values supported by the `mgrid` column in the `Employees` table to the values that exist in the `empid` column of the same table, we can do so by adding the following foreign key:

ALTER TABLE dbo.Employees
	ADD CONSTRAINT FK_Employees_Employees
	FOREIGN KEY (mgrid)
	REFERENCES dbo.Employees(empid)

-- Note that NULLs are allowed in the foreign key column(s) (`mgrid` in the last example) even if there are no NULLs in the referenced candidate key column(s). The preceding two examples are basic definitions of foreign keys that

-- enforce a referential action called no action. No action means that attempts to delete rows from the referenced table or update the referenced candidate key attributes will be rejected if related rows exist in the referencing table.

-- Or, in plainer terms: a referenced table is the parent (e.g., `dbo.Employees`). A referencing table is the child (e.g., `dbo.Orders`, which has a foreign key pointing to `dbo.Employees`). No action means the database will block the 

-- change if it would leave "orphaned" rows in the child table.

-- For example, if we try to delete an employee row from the `Employees` table when there are related orders in the `Orders` table, the attempt will be rejected & produce an error.



-- We can define the foreign key with actions that will compensate for such attempts (to delete rows from the referenced table or update the referenced candidate key attribute(s) when related rows exist in the referencing table).

-- We can define the options ON DELETE & ON UPDATE with actions such as CASCADE, SET DEFAULT, & SET NULL as part of the foreign key definition. 

-- CASCADE means that the operation (delete or update) will be cascaded to related rows. For example, ON DELETE CASCADE means that when we delete a row from the referenced table, it will delete the related rows from the referencing table. 

-- SET DEFAULT & SET NULL mean that the compensating action will set the foreign key attribute(s) of the related rows to the column's default value or NULL, respectively. 

-- Note that regardless of what action you choose, the referencing table will have orphaned rows only in the case of the exception with NULLs in the referencing column. This means, normally, foreign keys prevent orphaned rows 

-- (child rows pointing to a nonexistent parent). If we use CASCADE or SET DEFAULT, no orphans are left: the child rows either get deleted or reassigned to a valid default. But with SET NULL, the foreign key is cleared to NULL. If 

-- the column(s) used for the foreign key allows NULL, this technically leaves the row without a valid parent (since NULL means "no reference"). That's the only case where an "orphan-like" situation can exists, but it's intentional & 

-- permitted because the column(s) used for the foreign key allows NULL. Parent rows with no related child rows are always allowed.



----------------------------
-- Check Constraints
----------------------------

-- We can use a check constraint to define a predicate that a row must meet to be entered into the table or to be modified. For example, the following check constraint ensures that the salary column in the `Employees` table will 

-- support only positive values:

ALTER TABLE dbo.Employees
	ADD CONSTRAINT CHK_Employees_salary
	CHECK (salary > 0.00);

-- An attempt to insert or update a row with a nonpositive salary value will be rejected. Note that a check constraint rejects an attempt to insert or update a row when the predicate evaluates to FALSE. The modification will be

-- accepted when the predicate evaluates to either TRUE or UNKNOWN. For example, salary -1000 will be rejected, whereas salaries 50000 & NULL will both be accepted (if the column allowed NULLs, which it doesn't).



----------------------------
-- Default Constraints
----------------------------

-- A default constraint is associated with a particular attribute. It's an expression that is used as the default value when an explicit value is not specified for the attribute when we insert a row. For example, the following

-- code defines a default constraint for the `orderts` attribute (representing the order's timestamp):

ALTER TABLE dbo.Orders
	ADD CONSTRAINT DFT_Orders_orderts
	DEFAULT(SYSDATETIME()) FOR orderts;

-- The default expression invokes the SYSDATETIME function, which returns the current date & time value. After this default expression is defined, whenever we insert a row into the `Orders` table & do not explicitly specify a value in

-- the `orderts` attribute, SQL Server will set the attribute value to SYSDATETIME.



-----------------
-- Conclude
-----------------

-- When you're done, run the following code for cleanup:

DROP TABLE IF EXISTS dbo.Orders, dbo.Employees;



