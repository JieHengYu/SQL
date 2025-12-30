--------------------

-- Set Operators

--------------------

-- Set operators combine rows from the result sets (or multisets) of two queries. Some operators remove duplicates from the output -- returning a set -- while others keep duplicates, returning a multiset. T-SQL supports the following set operators: UNION,

-- UNION ALL, INTERSECT, & EXCEPT. The general syntax is:

	-- Syntax: `Input Query 1
	--          <set_operator>
	--          Input Query 2
	--          [ORDER BY ...];`



-- A set operator compares entire rows between the two input query results. Whether a row appears in the final result depends on the operator used & the outcome of these comparisons. Because set operators expect multiset inputs, the two queries involved

-- cannot include ORDER BY clauses. A query with an ORDER clause returns an ordered result, not a multiset. However, we can optionally include an ORDER BY clause after the set operation to sort the combined result. Each of the input queries can include all 

-- logical query processing phases except a presentation ORDER BY. Set operators are applied to the results of both queries, & any outer ORDER BY (if present) is applied to the operator's result.



-- The two input queries must:

	-- Return the same number of columns.

	-- Have corresponding columns with compatible data types.

-- "Compatible" means that the data type with lower precedence must be implicitly convertible to the one with higher precedence. If necessary, we can use CAST or CONVERT to explicitly align data types.



-- The column names in the final result are taken from the first query. If we need to assign column aliases, do so in the first query. However, it's still best practice to ensure that both queries define column names, & that the names of the corresponding

-- columns match.



-- When comparing rows between inputs, set operators use distinctness-based comparison rather than equality-based comparison. This follows the rules of the IS [NOT] DISTINCT FROM predicate. NULLs are treated like any other value in this context:

	-- One NULL is not distinct from another NULL (like 5 is not distinct from 5).

	-- A NULL is distinct from any non-NULL value (like NULL is distinct from 13).

-- This distinction is important for understanding how set operators handle NULLs in practice.



-- The SQL Standard defines two variants for each operator:

	-- DISTINCT (default) -- removes duplicates; returns a set

	-- ALL -- keeps duplicates; returns a multiset

-- In T-SQL:
	
	-- All three operators (UNION, INTERSECT, EXCEPT) support the implicit DISTINCT version.

	-- Only UNION supports the ALL version explicitly.

	-- T-SQL does not allow specifying DISTINCT explicitly -- it's implied when ALL isn't used.

-- Later, we'll look at ways to simulate the missing INTERSECT ALL & EXCEPT ALL operators.



--------------------------

-- The UNION Operator

--------------------------

-- The UNION operators combine the results of two input queries into a single result set. If a row appears in either input, it will appear in the output of the UNION operator. T-SQL supports two flavours of the UNION operator:

	-- UNION ALL -- keeps duplicates (returns a multiset)

	-- UNION (implicit DISTINCT) -- removes duplicates (returns a set)



-------------------------------
-- The UNION ALL Operator
-------------------------------

-- UNION ALL combines the results of both input queries without attempting to remove duplicates. If Query 1 returns m rows & Query 2 returns n rows, `Query 1 UNION ALL Query 2` will return m + n rows. For example, the code below uses the UNION ALL operator

-- to combine employee locations with customer locations:

USE TSQLV6;

SELECT country, region, city FROM HR.Employees
UNION ALL
SELECT country, region, city FROM Sales.Customers;

-- This query returns 100 rows in total -- 9 from `HR.Employees` & 91 from `Sales.Customers`. Because UNION ALL does not eliminate duplicates, the result is a multiset. The same row may appear more than once (for example, `(UK, NULL, London)` may appear 

-- multiple times).



---------------------------------------
-- The UNION (DISTINCT) Operator
---------------------------------------

-- The UNION operator (which implies DISTINCT) combines the results of both queries & removes duplicates. If a row appears in both input sets, it will appear only once in the output. Therefore, the result represents a set, not a multiset. For example, the

-- following code returns distinct locations that are either employee or customer locations:

SELECT country, region, city FROM HR.Employees
UNION
SELECT country, region, city FROM Sales.Customers;

-- This query returns 71 distinct rows, compared to the 100 rows produced by UNION ALL.



-- So when should we use UNION ALL & when should we use UNION?

	-- Use UNION when we explicitly need to eliminate duplicates.

	-- Use UNION ALL when duplicates are acceptable or impossible, to avoid the performance cost of distinct processing.



-------------------------------

-- The INTERSECT Operator

-------------------------------

-- The INTERSECT operator returns only rows that exist in both input query results.



--------------------------------------------
-- The INTERSECT (DISTINCT) Operator
--------------------------------------------

-- The INTERSECT operator (which implies DISTINCT) returns only distinct rows that appear in both input query results. If a row appears at least once in each input, it appears once in the final result. As an example the following query returns distinct

-- locations that are both employee & customer locations:

SELECT country, region, city FROM HR.Employees
INTERSECT
SELECT country, region, city FROM Sales.Customers;



-- When comparing rows, INTERSECT uses distinctness-based comparison semantics (as defined by the SQL standard's IS [NOT] DISTINCT FROM predicate). This means that NULLs are treated as equal to other NULLs:

	-- One NULL is not distinct from another NULL.

	-- A NULL is distinct from any non-NULL value.

-- For example, the location `(UK, NULL, London)` appears in the result of the INTERSECT query, because both tables contain that row.



-----------------------------------
-- The INTERSECT ALL Operator
-----------------------------------

-- The SQL Standard defines an INTERSECT ALL operator, but T-SQL does not implement it. 



-- Conceptually, INTERSECT ALL behaves like INTERSECT, except that it retains duplicates based on their counts in the inputs. This means that if a row R appears x times in the first input & y times in the second, then INTERSECT ALL returns R exactly

-- `MIN(x, y)` times. For example, if `(UK, NULL, London)` appears 4 times in `HR.Employees` & 6 times in `Sales.Customers`, INTERSECT ALL would return 4 occurrences of that row.



-- Although T-SQL lacks native support for INTERSECT ALL, we can simulate it using the ROW_NUMBER() function. The idea is to number duplicate occurrences of each row in each input & then perform a regular INTERSECT:

SELECT ROW_NUMBER() OVER (PARTITION BY country, region, city ORDER BY (SELECT 0)) AS rownum,
	country, region, city
FROM HR.Employees

INTERSECT

SELECT ROW_NUMBER() OVER (PARTITION BY country, region, city ORDER BY (SELECT 0)) AS rownum,
	country, region, city
FROM Sales.Customers;

-- This query effectively intersects on both data columns & their occurrence numbers. For instance, if one table has rows numbered 1-4 & the other 1-6 for the same location, occurrences 1-4 will intersect.



-- To exclude the `rownum` column from the output query, we can define a named table expression based on this query & select only the the attributes we want to return:

WITH INTERSECT_ALL AS (
	SELECT ROW_NUMBER() OVER (PARTITION BY country, region, city ORDER BY (SELECT 0)) AS rownum,
		country, region, city
	FROM HR.Employees

	INTERSECT

	SELECT ROW_NUMBER() OVER (PARTITION BY country, region, city ORDER BY (SELECT 0)) AS rownum,
		country, region, city
	FROM Sales.Customers
)
SELECT country, region, city
FROM INTERSECT_ALL;

-- This produces the same result that a standard INTERSECT ALL operator would, but without returning row numbers.



-----------------------------

-- The EXCEPT Operator

-----------------------------

-- The EXCEPT operator performs a set difference operation. It compares the results of two input queries & returns the rows that appear in the first input but not in the second.



---------------------------------------
-- The EXCEPT (DISTINCT) Operator
---------------------------------------

-- The EXCEPT operator (which implies DISTINCT) returns distinct rows that exist in the first query's result but not in the second's. A row is returned as long as it appears at least once in the first input & zero times in the second.



-- Unlike UNION & INTERSECT, EXCEPT is noncommutative -- the order of the two input queries matters. For example, the following code returns distinct locations that are employee locations but not customer locations:

SELECT country, region, city FROM HR.Employees
EXCEPT
SELECT country, region, city FROM Sales.Customers;

-- This query returns the two locations that are employee locations but not customer locations.



-- The following query returns 66 distinct locations that are customer locations but not employee locations:

SELECT country, region, city FROM Sales.Customers
EXCEPT
SELECT country, region, city FROM HR.Employees;



--------------------------------
-- The EXCEPT ALL Operator
--------------------------------

-- The SQL Standard defines an EXCEPT ALL operator, which extends EXCEPT to consider duplicate occurrences of rows. If a row R appears x times in the first input & y times in the second:

	-- If x > y, R appears x - y times in the output.

	-- If x <= y, R does not appear at all.

-- In other words, EXCEPT ALL returns only the extra occurrences of each row from the first multiset that are not matched in the second.



-- T-SQL does not natively support EXCEPT ALL, but we can emulate it using the same approach as with INTERSECT ALL -- by numbering row occurrences with ROW_NUMBER(). The following code returns occurrences of employee locations that have no corresponding 

-- occurrences of customer locations, matching the behaviour of a standard EXCEPT ALL operator:

WITH EXCEPT_ALL AS (
	SELECT ROW_NUMBER() OVER (PARTITION BY country, region, city ORDER BY (SELECT 0)) AS rownum,
		country, region, city
	FROM HR.Employees

	EXCEPT

	SELECT ROW_NUMBER() OVER (PARTITION BY country, region, city ORDER BY (SELECT 0)) AS rownum,
		country, region, city
	FROM Sales.Customers
)
SELECT country, region, city
FROM EXCEPT_ALL;



-------------------

-- Precedence

-------------------

-- SQL defines a precedence order among set operators, which determines the sequence in which they are evaluated when multiple operators appear in the same query.

	-- INTERSECT has the highest precedence.

	-- UNION & EXCEPT have equal precedence & are evaluated from left to right (in order of appearance).

	-- The ALL variants (e.g., INTERSECT ALL, UNION ALL, EXCPET ALL) follow the same precedence rules as their DISTINCT counterparts.

-- Consider the following code:

SELECT country, region, city FROM Production.Suppliers
EXCEPT
SELECT country, region, city FROM HR.Employees
INTERSECT
SELECT country, region, city FROM Sales.Customers;

-- Even though the INTERSECT operator appears second in the query, it is evaluated first, because it has higher precedence than EXCEPT. The logical meaning of this query is, "Return locations that are supplier locations, but not locations that are both

-- employee & customer locations."



-- To explicitly control the order in which set operators are evaluated, use parentheses. Parentheses have the highest precedence & also improve readability, reducing the likelihood of logical errors. For example, to return "Locations that are supplier

-- locations but not employee locations, & that are also customer locations", use the following code:

(SELECT country, region, city FROM Production.Suppliers
 EXCEPT
 SELECT country, region, city FROM HR.Employees)
INTERSECT
SELECT country, region, city FROM Sales.Customers;



---------------------------------------------------

-- Circumventing Unsupported Logical Phases

---------------------------------------------------

-- Each input query used in a set operation supports all logical query processing phases -- such as FROM, WHERE, GROUP BY, & HAVING -- except for ORDER BY. However, only the ORDER BY phase is allowed on the final result of a set operation.



-- If we need to apply other logical phases (besides ORDER BY) to the result of a set operation, this isn't directly supported within the same query. To work around this limitation, we can use a table expression (such as a derived table, CTE, or view). By

-- defining a named table expression that contains the set operator, we can then apply any logical query processing phases we want in the outer query. For example, the following query returns the number of distinct locations that are either employee or

-- customer locations in each country:

SELECT country, COUNT(*) AS numlocations
FROM (SELECT country, region, city FROM HR.Employees
	  UNION
	  SELECT country, region, city FROM Sales.Customers) AS U
GROUP BY country;

-- This example demonstrates how to apply a GROUP BY to the result of a UNION operator. The same approach works for applying other logical phases such as WHERE, HAVING, or even SELECT DISTINCT in the outer query.



-- Recall that an ORDER BY clause is not allowed within the input queries of a set operator. So what if we need to limit the number of rows in each input using TOP or OFFSET-FETCH? Again, we can use table expressions to handle this case. When ORDER BY

-- appears inside a subquery that uses TOP or OFFSET-FETCH, it serves only for filtering -- not for presentation -- so it's allowed. For example, the following query returns the two most recent orders for employees 3 & 5:

SELECT empid, orderid, orderdate
FROM (SELECT TOP(2) empid, orderid, orderdate
	  FROM Sales.Orders
	  WHERE empid = 3
	  ORDER BY orderdate DESC, orderid DESC) AS D1

UNION ALL

SELECT empid, orderid, orderdate
FROM (SELECT TOP(2) empid, orderid, orderdate
	  FROM Sales.Orders
	  WHERE empid = 5
	  ORDER BY orderdate DESC, orderid DESC) AS D2;

-- Here, each subquery independently filters its top two most recent orders (based on `orderdate` & `orderid`), & UNION ALL combines the results.