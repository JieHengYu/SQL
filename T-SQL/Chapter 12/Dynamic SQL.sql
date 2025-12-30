-------------------

-- Dynamic SQL

-------------------

-- With SQL Server, we can construct a batch of T-SQL code as a character string & then execute that batch at runtime. This capability is called dynamic SQL. SQL Server provides two primary approaches to execute dynamic SQL:

	-- The EXEC (short for EXECUTE) command
	
	-- The `sp_executesql` system stored procedure

-- We'll explain the differences between these two approaches & provide examples of each.



-- Dynamic SQL is useful in several scenarios, including the following:

	-- Automative administrative tasks: For example, querying metadata & dynamically constructing & executing a BACKUP DATABASE statement for each database in an instance.

	-- Improving performnace in certain scenarios: For example, constructing parameterised ad-hoc queries that can reuse previously cached execution plans.

	-- Constructing code elements based on actual data: For example, dynamically building a PIVOT query when we don't know in advance which values should appear in the IN clause of the PIVOT operator.



-------------------------
-- The EXEC Command
-------------------------

-- The EXEC command accepts a character string (enclosed in parentheses) as input & executes the batch of code contained in that string. EXEC supports both regular (VARCHAR) & Unicode (NVARCHAR) character strings. In addition

-- to executing dynamic SQL batches, EXEC can also be used to execute stored procedures, as we'll share later.



-- The following example stores a character string containing a PRINT statement in the variable `@sql`, & then uses EXEC to execute the batch:

USE TSQLV6;

DECLARE @sql AS VARCHAR(100);
SET @sql = 'PRINT ''This messaged was printed by a dynamic SQL batch.'';';
EXEC(@sql);

-- Notice the use of two single quotes ('') to represent a single quote instead of a quote literal. 



-- Be extremely careful when concatenating user input into dynamic SQL. Malicious users can attempt to inject code that you did not intend to run. The best defense against SQL injection is to avoid concatenating user input into

-- dynamic SQL altogether. Instead, use parameters whenever possible, & always validate & sanitise any input that must be handled dynamically.



---------------------------------------------
-- The sp_executesql Stored Procedure
---------------------------------------------

-- The `sp_executesql` system stored procedure is an alternative to EXEC for executing dynamic SQL. It is both more secure & more flexible, because it supports input & output parameters. Unlike EXEC, `sp_executesql`` accepts

-- only Unicode character strings (NVARCHAR) for the dynamic SQL batch.



-- The ability to use parameters makes dynamic SQL both safer & more efficient:

	-- Security: Parameters are treated as operands in expressions, not as executable code. As a result, parameterised dynamic SQL greatly reduces exposure to SQL injection.

	-- Performance: Parameterisation increases the likelihood of execution plan reuse, reducing the cost of recompiling queries.



-- An execution plan is the physical processing plan SQL Server generates for a query. It describes which objects to access, in what order, which indexes to use, which join algorithms to apply, & so on. One requirement for 

-- reusing a cached execution plan is that the query string be identical to the one that originally generated the plan.



-- Stored procedures naturally promote plan reuse because the query text remains constant even when parameter values change. When using ad-hoc dynamic SQL instead of stored procedures, `sp_executesql` allows us to retain many of 

-- the same benefits by keeping the query string constant while supplying different parameter values.



-- The `sp_executesql` procedure has two main input parameters, followed by a parameter assignment section:

	-- `@stmt`: A Unicode character string containing the batch of code to execute.

	-- `@params`: A Unicode character string that declares the input & output parameters used in the batch.

	-- Parameter assignments: Values assigned to the declared parameters.

-- The following example constructs a dynamic query against the `Sales.Orders` table, using an input parameter called `@orderid`:

DECLARE @sql AS NVARCHAR(100);

SET @sql = N'SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE orderid = @orderid;';

EXEC sp_executesql
	@stmt = @sql,
	@params = N'@orderid AS INT',
	@orderid = 10248;

-- This code assigns the value 10248 to the `@orderid` parameter. Even if we rerun the code with a different value, the query string remains the same, which increases the chances of reusing a previously cached execution plan.



--------------------------------------
-- Using PIVOT with Dynamic SQL
--------------------------------------

-- We've previously discussed how to use the PIVOT operator to transform rows into columns. In a static PIVOT query, we must know in advance which values to specify in the IN clause of the PIVOT operator. Here is an example of a

-- static PIVOT query:

SELECT *
FROM (SELECT shipperid, YEAR(orderdate) AS orderyear, freight
	  FROM Sales.Orders) AS D
PIVOT(SUM(freight) FOR orderyear IN ([2020], [2021], [2022])) AS P;

-- This query pivots data from the `Sales.Orders` table so that shipper IDs appear as rows, order years appear as columns, & the total freight appears at the intersection of each shipper & order year.



-- With a static query, we must revise the code each time new order years appear in the data. Instead, we can dynamically query the distinct order years, construct a dynamic PIVOT query, & then execute it. The following example

-- demonstrates this approach:

DECLARE @sql AS NVARCHAR(100) = N'SELECT *
FROM (SELECT shipperid, YEAR(orderdate) AS orderyear, freight
	  FROM Sales.Orders) AS D
PIVOT(SUM(freight) FOR orderyear IN (' +
(SELECT STRING_AGG(QUOTENAME(orderyear), N',') WITHIN GROUP(ORDER BY orderyear)
 FROM (SELECT DISTINCT(YEAR(orderdate)) AS orderyear FROM Sales.Orders) AS D) +
 N')) AS P;';

 EXEC sys.sp_executesql @stmt = @sql;

 -- In this example:

	-- STRING_AGG concatenates the distinct order years currently present in the `Sales.Orders` table.

	-- QUOTENAME converts each year to a Unicode character string & encloses it in square brackets, making it a valid column identifier.
	
	-- The dynamically generated list of years is inserted into the IN clause of the PIVOT operator.

	-- The completed query string is stored in `@sql` & executed using `sp_executesql`.