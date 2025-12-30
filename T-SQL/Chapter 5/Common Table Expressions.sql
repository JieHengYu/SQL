----------------------------------

-- Common Table Expressions

----------------------------------

-- A common table expression (CTE) is another standard form of table expression, similar to a derived table but with a few important advantages. CTEs are defined with the WITH keyword & follow this general form:

	-- Syntax: `WITH <CTE_Name>[(target_column_list)] AS (
	--                <inner_query_defining_CTE>
	--          )
	--          <outer_query_against_CTE>;

-- The inner query must meet the same requirements as any table expression. For example, the code below defines a CTE named `USACusts` that returns all customers from the United States. The outer query then selects all rows from this CTE:

USE TSQLV6;

WITH USACusts AS (
	SELECT custid, companyname
	FROM Sales.Customers
	WHERE country = N'USA'
)
SELECT * FROM USACusts;



-- Like derived tables, a CTE exists only for the duration of the outer query against the CTE. Once the outer query finishes, the CTE goes out of scope.

SELECT * FROM USACusts;



-------------------------------------------
-- Assigning Column Aliases in CTEs
-------------------------------------------

-- CTEs support two forms of column aliasing: inline & external.

	-- Inline aliasing: assign aliases directly in the SELECT list using the syntax `<expression> AS <alias>`.

	-- External aliasing: specify the full list of output column names in parentheses immediately after the CTE name.

-- Here's an example of the inline form:

WITH C AS (
	SELECT YEAR(orderdate) AS orderyear, custid
	FROM Sales.Orders
)
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM C
GROUP BY orderyear;

-- Here's an example of the external form:

WITH C(orderyear, custid) AS (
	SELECT YEAR(orderdate), custid
	FROM Sales.Orders
)
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM C
GROUP BY orderyear;

-- The choice between inline & external aliasing follows the same considerations discussed for derived tables. Inline alising makes debugging easier, while external aliasing can be useful when treating the CTEs as a fixed "black box" with a defined interface.



-------------------------------
-- Using Arguments in CTEs
-------------------------------

-- As with derived tables, the inner query of a CTE can reference arguments such as local variables or input parameters. For example, the code below declares a variable `@empid` & uses it in a CTE definition to filter rows by employee ID:

DECLARE @empid AS INT = 3;

WITH C AS (
	SELECT YEAR(orderdate) AS orderyear, custid
	FROM Sales.Orders
	WHERE empid = @empid
)
SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
FROM C
GROUP BY orderyear;



------------------------------
-- Defining Multiple CTEs
------------------------------

-- At first glance, the difference between derived tables & CTEs may seem mostly semantic. However, the way CTEs are named & defined before being referenced gives them several important advantages. One key advantage is the ability to reference one CTE from

-- another without nesting. Instead of wrapping queries inside each other, we separate CTE definitions with commas. Each CTE can reference all previously defined CTEs, & the outer query can reference any of them. For example, the following code shows the

-- CTE-based alternative to the nested derived table version of sample query 5-2 in the setion on derived tables:

WITH C1 AS (
	SELECT YEAR(orderdate) AS orderyear, custid
	FROM Sales.Orders
),
C2 AS (
	SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
	FROM C1
	GROUP BY orderyear
)
SELECT orderyear, numcusts
FROM C2
WHERE numcusts > 70;

-- This modular structure improves both readability & maintainability compared to nested derived tables. 



-- It is important to note that in T-SQL, we cannot nest CTEs or define one inside the parentheses of a derived table.



--------------------------------------
-- Multiple References in CTEs
--------------------------------------

-- Another advantage of CTEs is that, because they are named & defined before being queried, they can be referenced multiple times within the same outer query. From the perspective of the outer query, the CTE already exists & can therefore appear in multiple

-- table operators such as joins. This is likely the reason behind the term "common" in common table expression: the name is common to the outer query. For example, the following query is the CTE-based equivalent to the derived table solution shown in 

-- sample query 5-3 in the section on derived tables.

WITH YearlyCount AS (
	SELECT YEAR(orderdate) AS orderyear,
		COUNT(DISTINCT custid) AS numcusts
	FROM Sales.Orders
	GROUP BY Year(orderdate)
)
SELECT Cur.orderyear,
	Cur.numcusts AS curnumcusts, Prv.numcusts AS prvnumcusts,
	Cur.numcusts - Prv.numcusts AS growth
FROM YearlyCount AS Cur
LEFT OUTER JOIN YearlyCount AS Prv
	ON Cur.orderyear = Prv.orderyear + 1;

-- Here, the CTE `YearlyCount` is defined only once but referenced twice in the outer query -- once as `Cur` & once as `Prv`. This eliminates the need to duplicate the inner query definition in sample query 5-3, making the code clearer & less error-prone.



-- Regarding performance, remember that table expressions generally do not improve efficiency, since they are not physically materialised. In this case, both references to the CTE are expanded into a self join of `Sales.Orders`. Each side of the join

-- independently scans & aggregates the table before combining results -- the same work performed in the derived table approach. To avoid repeating this work, we would need to persist the intermediate result in a temporary table or a table variable.



----------------------
-- Recursive CTEs
----------------------

-- CTEs are unique among table expressions in that they support recursion, as defined in the SQL standard. A recursive CTE consists of at least two queries: one called the anchor member & one called the recursive member (though more members are possible).

-- The basic structure looks like this:

	-- Syntax: `WITH <CTE_Name>[(<target_column_list>)] AS (
	--              <anchor_member>
	--              UNION ALL
	--              <recursive_member>
	--          )
	--          <outer_query_against_CTE>;`

-- The anchor member is a standard query that produces a valid result set, much like the query used to define a non-recursive table expression. It is executed only once. The recursive member is a query that references the CTE name & is invoked repeatedly 

-- until it returns an empty set. On the first invocation, the CTE reference represents the anchor member's result. On each subsequent invocation, it represents the result from the previous recursive step.



-- Both the anchor & recursive members must return the same number of columns with compatible data types. In the outer query, a reference to the CTE name represents the unified result of the anchor member's output & all recursive iterations combined.



-- The concept of recursive CTEs may seem abstract. The best way to understand them is through an example. The following query returns information about employee Don Funk (employee ID 2) & all of his subordinates at every level, both direct & indirect.

WITH EmpsCTE AS (
	SELECT empid, mgrid, firstname, lastname
	FROM HR.Employees
	WHERE empid = 2

	UNION ALL

	SELECT C.empid, C.mgrid, C.firstname, C.lastname
	FROM EmpsCTE AS P
		INNER JOIN HR.Employees AS C
			ON P.empid = C.mgrid
)
SELECT empid, mgrid, firstname, lastname
FROM EmpsCTE;


-- Here's how it works step by step:

	-- Anchor member: returns employee 2 (Don Funk)

	-- First recursive step: Finds Don Funk's direct subordinates -- employees 3 & 5 (i.e., Don Funk is the manager of employees 3 & 5).

	-- Second recursive step: Finds the subordinates of employees 3 & 5 -- employees 4, 6, 7, 8, & 9 (i.e., employees 3 & 5 are the managers of employees 4, 6, 7, 8 & 9).

	-- Third recursive step: Finds no new subordinates, so recursion stops.

-- The reference to EmpsCTE in the outer query represents the combined results of the anchor member & all recursive steps -- in this case, employee 2 & all of his direct & indirect subordinates.



-- If the join predicate in the recursive member contains a logical error, or if the data contains cycles, the recursive member may be invoked endlessly. To prevent this, SQL Server imposes a safety limit: by default, the recursive member can be invoked at

-- most 100 times. If recursion exceeds this limit, the query fails.



-- We can override this behaviour by specifying the hint `OPTION(MAXRECURSION n)` at the end of the outer query, where `n` is an integer from 0 through 32,767:

	-- `MAXRECURSION n`: sets the recursion limit to `n`

	-- `MAXRECURSION 0`: removes the limit entirely

-- Be careful when removing the limit. SQL Server stores the intermediate results of both the anchor & recursive members in a work table in `tempdb`. If recursion runs unchecked, the work table can grow rapidly, potentially consuming large amounts of space

-- & preventing the query from ever completing.


