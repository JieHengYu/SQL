-------------------

-- Cross Joins

-------------------

-- The cross join is the simplest type of join, consisting of a single logical query phase: the Cartesian product. In this phase, every row from one input table is matched with every row from the other. If one table has m rows & the other has n rows, the result

-- contains m * n rows.



-- T-SQL supports two standard syntaxes for cross joins: 

	-- SQL-92 syntax (the recommended form, & the one we will use throughout this lesson)

	-- SQL-89 syntax (supported, but not recommended)



---------------------
-- SQL-92 Syntax
---------------------

-- The following query applies a cross join between the `Sales.Customers` & `HR.Employees` tables in the `TSQLV6` database (using the SQL-92 syntax) & returns the `custid` & `empid` attributes in the result set:

USE TSQLV6;

SELECT C.Custid, E.empid
FROM Sales.Customers AS C
	CROSS JOIN HR.Employees AS E;

-- Since the `Sales.Customers` table contains 91 rows & the `HR.Employees` table contains 9 rows, the query produces a result set of 819 rows.



-- When using the SQL-92 syntax, we specify the CROSS JOIN keywords between the two tables.



-- In the FROM clause of the query, the tables `Sales.Customers` & `HR.Employees` are assigned the aliases `C` & `E`, respectively. Once a table alias is defined, it should be used in place of the full table name when qualifying column references -- for example,

-- `table_alias.column_name`. Column prefixes help avoid ambiguity when the same column name exists in both tables. While prefixes are optional in unambiguous cases, it is considered good practice to use them consistently for clarity. Note that if a table alias

-- is assigned, the full table can no longer be used as a prefix; in ambiguous cases, the alias must be used.



------------------------
-- SQL-89 Syntax
------------------------

-- T-SQL also supports an older cross join syntax, where the table names are separated by a comma:

SELECT C.custid, E.empid
FROM Sales.Customers AS C, HR.Employees AS E;



-- There is no logical or performance difference between the SQL-92 & SQL-89 syntax. Both are part of the SQL standard & are fully supported in T-SQL.



-------------------------
-- Self Cross Joins
-------------------------

-- We can join multiple instances of the same table -- a technique known as a self join. Self joins are supported with all join types including cross, inner, & outer joins. For example, the following query performs a self cross join between two

-- instances of the `HR.Employees` table:

SELECT E1.empid, E1.firstname, E1.lastname,
	E2.empid, E2.firstname, E2.lastname
FROM HR.Employees AS E1
	CROSS JOIN HR.Employees AS E2;



-- In a self join, aliasing tables are mandatory. Without them, the column names in the result would be ambiguous.



-----------------------------------
-- Producing Tables of Numbers
-----------------------------------

-- Cross joins are often useful for efficiently generating a result set that represents a sequence of integers (1, 2, 3, & so on).



-- We'll start by creating a table named `dbo.Digits` with a single column `digit`, & populating it with 10 rows containing the digits 0 through 9:

DROP TABLE IF EXISTS dbo.Digits;

CREATE TABLE dbo.Digits(digit INT NOT NULL PRIMARY KEY);

INSERT INTO dbo.Digits(digit)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9);

SELECT digit FROM dbo.Digits;

-- This code also uses an INSERT statement to populate the `dbo.Digits` table.



-- Suppose we need a query that generates the integers from 1 through 1,000. To achieve this, we can cross join three instances of the `dbo.Digits` table, with each instance representing a differnet power of 10 (1, 10, & 100). Since each table instance contains

-- 10 rows, multiplying them together produces 1,000 rows in the result set. To calculate the actual numbers, we multiply the digit from each instance by its corresponding power of 10, sum the results, & add 1. Here's the complete query:

SELECT D3.digit * 100 + D2.digit * 10 + D1.digit + 1 AS n
FROM dbo.Digits AS D1
	CROSS JOIN dbo.Digits AS D2
	CROSS JOIN dbo.Digits AS D3
ORDER BY n;

-- This example produces a sequence of 1,000 integers. To generate larger sequences, simply add more instances of the `dbo.Digits` table. For example, joining six instances will yield 1,000,000 rows.



-- Keep in mind that this technique is mainly useful in versions prior to SQL Server 2022. In newer versions, we can generate integer sequences more easily using the GENERATE_SERIES function.

