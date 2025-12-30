-------------

-- Views

-------------

-- Derived tables & common table expressions (CTEs) have a single-statement scope, meaning they cannot be reused beyond the query in which they are defined. In contrast, views & inline table-valued functions (inline TVFs) are stored as permanent objects

-- in the database, which makes them reusable. Functionally, they behave much like derived tables & CTEs: when we query a view or an inline TVF, SQL Server expands its definition & queries the underlying objects directly.



-- As an example, the following code creates a view named `USACusts` in the `Sales` schema of the `TSQLV6` database. The view returns all customers located in the United States:

USE TSQLV6;

CREATE OR ALTER VIEW Sales.USACusts
AS
SELECT custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA'
GO

-- The CREATE OR ALTER syntax either creates the object if it doesn't exist or updates its definition if it does. In contrast, using CREATE VIEW alone will result in an error if the view already exists.



-- Similar to derived tables & CTEs, we can define column names in a view either inline (using column aliases in the SELECT list) or externally by specifying the target column names in parentheses immediately after the view name. 



-- Once a view is created, we can query it like any other table:

SELECT custid, companyname
FROM Sales.USACusts;

-- Because a view is a database object, we can manage access permissions just like with tables, including SELECT, INSERT, UPDATE, & DELETE. This also allows us to grant access to the view while restricting direct access to the underlying table.



-- A key consideration when defining views is to avoid `SELECT *`. When a view is created with `SELECT *`, SQL Server stores only the columns that exist at creation time. For example, if a view is defined as `SELECT * FROM dbo.T1` & `T1` initially has

-- columns `col1` & `col2`, only these columns are stored in the view's metadata. Adding new columns to `dbo.T1` later will not automatically update the view. To refresh a view's metadata after adding columns, we can use:

	-- `EXEC sp_refreshview 'ViewName'`

	-- `EXEC sp_refreshsqlmodule 'ViewName'`

-- However, best practice is to explicitly list the columns needed when defining a view. If new columns are added to underlying tables & we want them in the view, update the view using CREATE AND ALTER VIEW or ALTER VIEW.



--------------------------------------
-- Views & the ORDER BY Clause
--------------------------------------

-- The query used to define a view must satisfy the same requirements that apply to the inner query of other table expressions. Specifically: all view columns must have names, all column names must be unique, & the view does not guarantee any order of the 

-- rows.



-- In this section, we'll focus on the ordering issue, which is a fundamental concept that is important to understand.



-- Remember that a presentation ORDER BY clause is not allowed in the query that defines a table expression because a relation is inherently unordered. If we want to return rows from a view in a specific order for presentation purposes, the ORDER BY clause

-- should be applied in the outer query against the view, for example:

SELECT custid, companyname, region
FROM Sales.USACusts
ORDER BY region;

-- If we try to include a presentation ORDER BY clause directly in the view definition, like this:

CREATE OR ALTER VIEW Sales.USACusts
AS

SELECT custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA'
ORDER BY region;
GO

-- The attempt will fail with an error: "The ORDER BY clause is invalid in views, inline functions, derived tables, subqueries, & common table expressions, unless TOP OFFSET or FOR XML is also specified." This error shows that T-SQL allows ORDER BY in very

-- specific cases -- when combined with TOP, OFFSET-FETCH, or FOR XML -- because in those scenarios the clause serves a functional purpose rather than a simple presentation purpose. Standard SQL has a similar restriction, with the same exception when using

-- OFFSET-FETCH.



-- Because T-SQL allows an ORDER BY clause in a view only when TOP or OFFSET-FETCH is specified, some people try to create "ordered views". A common approach is to use `TOP (100) PERCENT`, as in the following example:

CREATE OR ALTER VIEW Sales.USACusts
AS

SELECT TOP (100) PERCENT
	custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA'
ORDER BY region;
GO

-- Although this code is technically valid & the view is created successfully, it does not guarantee row order when querying the view. For example:

SELECT custid, companyname, region
FROM Sales.USACusts;

-- The rows may not be sorted by `region`. If the outer query does not include an ORDER BY clause but the result appears to be ordered, it may be due to physical storage or query optimisation choices. However, these conditions are not guaranteed or

-- repeatable. The only way to guarantee presentation order is to include an ORDER BY clause in the outer query -- nothing else counts.



-- In older versions of SQL Server, when the inner query used `TOP (100) PERCENT` along with an ORDER BY clause, & the outer query had no ORDER BY, the rows sometimes appeared ordered. This was not guaranteed behaviour -- it was simply a side effect of how

-- the optimiser handled the query. Later, Microsoft improved the optimiser, which now ignores this meaningless combination. One exception is when the inner query uses an OFFSET clause with 0 rows, & no FETCH clause, for example:

CREATE OR ALTER VIEW Sales.USACusts
AS

SELECT custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA'
ORDER BY region
OFFSET 0 ROWS;
GO

-- Currently, querying this view without an outer ORDER BY may appear to return rows sorted by `region`:

SELECT custid, companyname, region
FROM Sales.USACusts;

-- But this is not guaranteed -- it happens only because of the current optimiser's behaviour. To reliably return rows in a specific order, the outer query must include an ORDER BY clause.



-- Do not confuse the behaviour of the query used to define a table expression with that of an outer query. An outer query with ORDER BY & TOP or OFFSET-FETCH guarantees presentation order. The simple rule is:

	-- If the outer query has an ORDER BY clause, presentation order is guaranteed, regardless of whether that ORDER BY serves another purpose.



----------------------
-- View Options
----------------------

-- When creating or altering a view, we can specify view attributes & options as part of its definition. In the view header, using the WITH clause, we can define attributes such as ENCRYPTION & SCHEMABINDING. At the end of the query, we can include

-- WITH CHECK OPTION. The following sections explain the purpose & usage of these options.



------------------------------
-- The ENCRYPTION Option
------------------------------

-- The ENCRYPTION option is available when we create or alter views, stored procedures, triggers, & user-defined functions (UDFs). The ENCRYPTION option indicates that SQL Server will internally store the text with the definition of the object in an

-- obfuscated format. The obfuscated text is not directly visible to users through any of the catalog objects -- only to privileged users through special means.



-- Before exploring the ENCRYPTION options, let's restore the `Sales.USACusts` view to its original definition:

CREATE OR ALTER VIEW Sales.USACusts
AS

SELECT custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO



-- To retrieve the definition of a view, we can use the OBJECT_DEFINITION function:

SELECT OBJECT_DEFINITION(OBJECT_ID('Sales.USACusts'));

-- Since the `Sales.USACusts` view was initially created without the ENCRYPTION option, its definition is returned by the function. Next, let's alter the view to include ENCRYPTION:

CREATE OR ALTER VIEW Sales.USACusts WITH ENCRYPTION
AS

SELECT custid, companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO

-- If we try again to retrieve the view definition:

SELECT OBJECT_DEFINITION(OBJECT_ID('Sales.USACusts'));

-- This time, the function returns NULL, because the view definition is now encrypted.



-- As an alternative, we can use the sp_helptext stored procedure to view object definitions.

EXEC sp_helptext 'Sales.USACusts';

-- However, since the view was created with ENCRYPTION, this also does not return the object definition. Instead, we'll see the message: "The text for object 'Sales.USACusts' is encrypted."



-----------------------------------
-- The SCHEMABINDING Option
-----------------------------------

-- The SCHEMABINDING option is available for views, UDFs, & natively compiled modules. It binds the schema of referenced objects & columns to the schema of the referencing object, which means:

	-- Referenced objects cannot be dropped.

	-- Referenced columns cannot be dropped or altered.

-- For example, we can alter the `Sales.USACusts` view to use SCHEMABINDING:

CREATE OR ALTER VIEW Sales.USACusts WITH SCHEMABINDING
AS

SELECT
custid, companyname, contactname, contacttitle, address,
city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA';
GO

-- After this, if we try to drop the `address` column from the `Sales.Customers` table:

ALTER TABLE Sales.Customers DROP COLUMN address;

-- SQL Server returns an error, because the column is referenced by a schemabound view. Without SCHEMABINDING, we could have made this schema change -- or even dropped the `Sales.Customers` table entirely -- potentially causing runtime errors when querying 

-- the view. Using SCHEMABINDING helps prevent such errors by enforcing dependencies.



-- To use SCHEMABINDING, the object definition must meet a few requirements:

	-- 1. The SELECT clause cannot use *; all columns must be explicitly listed.

	-- 2. All referenced objects must use schema-qualified, two-part names.

-- Both of these requirements are considered good practice in general.



-- Overall, creating objects with SCHEMABINDING is considered a best practice, as it helps maintain schema integrity. However, it can make application upgrades more complex & time-consuming, because structural changes must account for these 

-- dependencies.



--------------------------
-- The CHECK Option
--------------------------

-- The purpose of WITH CHECK OPTION is to prevent modifications through a view that would violate the view's filtering conditions. For example, the `Sales.USACusts` view filters customers to include only those from the United States. Since the view is

-- is currently defined without CHECK OPTION, it is possible to insert or update rows through the view in ways that conflict with its filter. For instance, the following statement successfully inserts a customer from the United Kingdom through the view:

INSERT INTO Sales.USACusts(
	companyname, contactname, contacttitle, address,
	city, region, postalcode, country, phone, fax
)
VALUES (N'Customer ABCDE', N'Contact ABCDE', N'Title ABCDE', N'Address ABCDE',
	N'London', NULL, N'12345', N'UK', N'012-3456789', N'012-3456789');

-- This row is inserted into the underlying `Sales.Customers` table. However, because the view only returns US customers, querying for the new row through the view returns an empty result set:

SELECT custid, companyname, country
FROM Sales.USACusts
WHERE companyname = N'Customer ABCDE';



-- If we query the `Sales.Customers` table directly, we can see the newly inserted customer:

SELECT custid, companyname, country
FROM Sales.Customers
WHERE companyname = N'Customer ABCDE';

-- The customer appears in the output because the row was successfully inserted into the underlying `Sales.Customers` table. Likewise, if we update an existing customer through the view & change the `country` value to something other than the United 

-- States, the update will succeed. However, that customer will no longer appear in the view, since it no longer satisfies the view's filter condition.



-- To prevent modifications that conflict with a view's filter, add WITH CHECK OPTION at the end of the view definition:

CREATE OR ALTER VIEW Sales.USACusts WITH SCHEMABINDING
AS

SELECT
custid, companyname, contactname, contacttitle, address,
city, region, postalcode, country, phone, fax
FROM Sales.Customers
WHERE country = N'USA'
WITH CHECK OPTION;
GO

-- Now, if we try to insert a row that does not satisfy the filter condition:

INSERT INTO Sales.USACusts(
companyname, contactname, contacttitle, address,
city, region, postalcode, country, phone, fax)
VALUES(
N'Customer FGHIJ', N'Contact FGHIJ', N'Title FGHIJ', N'Address FGHIJ',
N'London', NULL, N'12345', N'UK', N'012-3456789', N'012-3456789');

-- SQL Server returns an error, because the new row violates the view's `WHERE country = N'USA'` condition.



-- When you're done, run the following code for cleanup:

DELETE FROM Sales.Customers
WHERE custid > 91;

DROP VIEW IF EXISTS Sales.USACusts;