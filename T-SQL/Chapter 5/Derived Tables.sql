-----------------------

-- Derived Tables

-----------------------

-- A derived table is a temporary result set defined in the FROM clause of an outer query. Its scope exists only within that query: once that outer query finishes, the derived table no longer exists.



-- To define a derived table, we write a query inside parentheses, give it an alias with the AS keyword, & then refer to it by that alias in the outer query. For example, the query below creates a derived table named `USACusts` based on all customers from

-- the United States. The outer query then selects all rows from the derived table:

USE TSQLV6;

SELECT *
FROM (SELECT custid, companyname
	  FROM Sales.Customers
	  WHERE country = N'USA') AS USACusts;

-- This is a simple example that shows the syntax. In practice, a derived table is most useful when the outer query needs to further manipulate or filter the intermediate result set. Here, since the outer query doesn't add anything, the derived table is

-- unnecessary.



-- For a query to be valid as the inner query of a table expression, it must satisfy three requirements:

	-- 1. No guaranteed order: A table expression represents a table, & tables have no inherent row order. Because of this, standard SQL disallows ORDER BY in queries that define table expressions -- unless the clause serves a logical purpose beyond 
	
	-- presentation.

		-- Exceptions: ORDER BY is permitted when combined with TOP or OFFSET-FETCH, since in that context, it defines which rows are included.

		-- Remember: if the outer query does not include its own ORDER BY, the final result is not guaranteed to appear in any particular order.
	
	-- 2. All columns must have names: Every column in a table must be named. Therefore, when defining a table expression, all expressions in the SELECT list must have aliases.

		-- Note: While T-SQL sometimes allows anonymous result columns in regular queries, this is not allowed in table expressions.

	-- 3. All column names must be unique: Column names in a table must be distinct. If a query joins two tables that share a column name, you must rename one (or both) using column aliases. Without unique column names, the table expression is invalid.

-- All three rules come from the relational model:

	-- Tuples (rows) form a set, so order is irrelevant.

	-- Attributes (columns) must have names.

	-- Attribute names must be unique.



----------------------------------
-- Assigning Column Aliases
----------------------------------

-- One advantage of table expressions is that the outer query can reference column aliases defined in the inner query's SELECT clause. This helps work around a key limitation: within a single query, column aliases cannot be used in clauses that are

-- logically processed before SELECT (such as WHERE or GROUP BY). For example, suppose we want to return the number of distinct customers per order year from the `Sales.Orders` table. The following attempt is invalid because the GROUP BY clause tries to use

-- the alias `orderyear`, which is only assigned in the SELECT clause:

SELECT YEAR(orderdate) AS orderyear,
	COUNT(DISTINCT custid) AS numcusts
FROM Sales.Orders
GROUP BY orderyear;

-- If we run this query, SQL Server returns the error: "Invalid column name 'orderyear'." This happens because GROUP BY is evaluated before SELECT, so the alias `orderyear` does not yet exist at that point. We can fix the problem by repeating the expression

-- `YEAR(orderdate)` in both the SELECT & GROUP BY clauses. The fix works here because the expression is short, but with more complex expressions, repetition can make the query harder to read & maintain. A cleaner approach is to use a table expression:

SELECT orderyear, COUNT(DISTINCT custid) AS numcusts -- (Sample Query 5-1)
FROM (SELECT YEAR(orderdate) AS orderyear, custid
	  FROM Sales.Orders) AS D
GROUP BY orderyear;

-- In this example, the inner query creates a derived table `D` that returns two columns: `orderyear` (aliased from `YEAR(orderdate)`) & `custid`. The outer query then groups by & selects `orderyear` directly. From the perspective of the outer query, `D`

-- is just a regular table with those two columns, so the alias can be freely referenced without repeating the full expression.



-- Microsoft SQL Server expands a table expression & accesses the underlying objects directly. After expansion, sample query 5-1 is equivalent to the following:

SELECT YEAR(orderdate) AS orderyear,
	COUNT(DISTINCT custid) AS numcusts
FROM Sales.Orders
GROUP BY YEAR(orderdate);

-- This example highlights an important point: table expressions are used primarily for logical clarity, not for performance. In most cases, they have no significant positive or negative effect compared to writing the expanded query directly.



-- Sample query 5-1 uses the inline aliasing form to assign column aliases directly to expressions:

	-- Syntax: `<expression> [AS] <alias>`

-- The keyword AS is optional, but it improves readability & is generally recommended. In some cases, we may prefer a second approach: external aliasing. With this form, we specify all output column names in parentheses after the table expression's alias:

SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM (SELECT YEAR(orderdate), custid
	  FROM Sales.Orders) AS D(orderyear, custid)
GROUP BY orderyear;

-- Advantages of inline aliasing:

	-- When debugging, if we run the inner query on it's own, the result set already includes the assigned aliases.

	-- The link between each expression & its alias is explicit, which is especially helpful in longer queries.

-- Advantages of external aliasing:

	-- Useful when the inner query is stable & won't change, allowing us to treat it as a black box.

	-- Shifts focus to the interface between the outer query & the table expression: the table alias & its output column list.



------------------------
-- Using Arguments
------------------------

-- The query that defines a derived table can reference arguments such as local variables or routine input parameters (e.g., those passed to a stored procedure or function). For example, the code below declares & initialises a variable `@empid`, then

-- uses it in the inner query's WHERE clause:

DECLARE @empid AS INT = 3;

SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM (SELECT YEAR(orderdate) AS orderyear, custid
	  FROM Sales.Orders
	  WHERE empid = @empid) AS D
GROUP BY orderyear;

-- This query returns the number of distinct customers per year for orders handled by a specific employee -- in this case, the employee whose ID is stored in `@empid` (employee ID 3).



-------------
-- Nesting
-------------

-- A derived table can itself be based on another derived table, creating a nested structure. While valid, nesting often complicates the code & reduces readability. For example, the query below returns order years & the number of distinct customers handled 

-- in each year, but only for years with more than 70 distinct customers:

SELECT orderyear, numcusts
FROM (SELECT orderyear, COUNT(DISTINCT custid) AS numcusts -- (Sample Query 5-2)
	  FROM (SELECT YEAR(orderdate) AS orderyear, custid
			FROM Sales.Orders) AS D1
	  GROUP BY orderyear) AS D2
WHERE numcusts > 70;

-- The motivation here is to simplify logic by reusing column aliases, but the extra nesting may actually make the query harder to follow. In this case, a simpler alternative without table expressions is easier to read:

SELECT YEAR(orderdate) AS orderyear,
	COUNT(DISTINCT custid) AS numcusts
FROM Sales.Orders
GROUP BY YEAR(orderdate)
HAVING COUNT(DISTINCT custid) > 70;



----------------------------
-- Multiple References
----------------------------

-- Another limitation of derived tables arises when we need to join multiple instances of the same one. A join treats each input (derived table) as a set, but we cannot reuse the same alias on both sides of the join. Instead, we must define the derived table 

-- separately for each input. For example, the query below calculates the year-over-year growth in the number of distinct customers:

SELECT Cur.orderyear,
	Cur.numcusts AS curnumcusts, Prv.numcusts AS prvnumcusts, -- (Sample Query 5-3)
	Cur.numcusts - Prv.numcusts AS growth
FROM (SELECT YEAR(orderdate) AS orderyear,
	      COUNT(DISTINCT custid) AS numcusts
	  FROM Sales.Orders
	  GROUP BY YEAR(orderdate)) AS Cur
	LEFT OUTER JOIN (SELECT YEAR(orderdate) AS orderyear,
						 COUNT(DISTINCT custid) AS numcusts
					 FROM Sales.Orders
					 GROUP BY YEAR(orderdate)) AS Prv
		ON Cur.orderyear = Prv.orderyear + 1;

-- The derived table `Cur` represents the current year values. The derived table `Prv` represents the previous year values. The join condition `Cur.orderyear = Prv.orderyear + 1` ensures each year in `Cur` matches the year immediately before it in 

-- `Prv`. Because this is a left outer join, all years from `Cur` are preserved, including the first year (which has no match in `Prv`). The outer query then computes the growth in distinct customers between consecutive years.



-- The downside is clear: since we cannot reuse a single derived table alias for both sides of the join, we are forced to duplicate the same query definition. This makes the code longer, harder to maintain, & more prone to errors.