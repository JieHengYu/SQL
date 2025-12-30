---------------------------------

-- All-At-Once Operations

---------------------------------

-- SQL supports all-at-once operations, meaning that all expressions within the same logical query processing phase are evaluated simultaneously. This is because expressions in a given phase are treated as a set, & sets has no inherent 

-- order. For example, this is why we cannot reference to column aliases defined in the SELECT clause within that same SELECT clause. Consider the following query:

USE TSQLV6;

SELECT orderid, YEAR(orderdate) AS orderyear,
	   orderyear + 1 AS nextyear
FROM Sales.Orders;

-- The reference to the column alias `orderyear` in the third expression in the SELECT list is invalid, even though it appears after the expression where the alias is defined. Logically,  the SELECT clause is a set of expression with no 

-- defined order of evaluation. Conceptually, all the expressions are evaluated at the same time. As a result, this query produces an "Invalid column name 'orderyear'" error. 



-- Here's another example for the ramifications of all-at-once operations: Suppose we have a table `T1` with two integer columns `col1` & `col2`, & we want to return all rows for which `col2/col1` is greater than 2. Because

-- there might be rows in the table in which `col1` is zero, we need to ensure that the query won't produce a divide-by-zero error. So, we write a query using the following format:

-- SELECT col1, col2
-- FROM dbo.T1
-- WHERE col1 <> 0 AND col2/col1 > 2;



-- You might assume SQL Server evaluates the expressions from left to right, & that if the expression `col1 <> 0` evaluates to FALSE, it would skip evaluating `col2/col1 > 2` since the entire predicate is already known to be FALSE. 

-- Based on this reasoning, it may seem that the query should never produce a divide-by-zero error. However, because of the all-at-once operations concept, SQL Server can evaluate expressions in the WHERE clause in any order, 

-- typically guided by cost-based optimisation. If it evaluates `col2/col1 > 2` first, this query may fail with a divide-by-zero error.



-- We have several ways to avoid a failure here. For example, the order in which the WHEN clauses of a CASE expression are evaluated is guaranteed. So, we can revise the query as follows:

-- SELECT col1, col2
-- FROM dbo.T1
-- WHERE 
--     CASE
--         WHEN col1 = 0 THEN 'no'
--		   WHEN col2/col1 > 2 THEN 'yes'
--		   ELSE 'no'
--	   END = 'yes'

-- For rows where `col1` equals zero, the first WHEN clause evaluates to TRUE, & the CASE expression returns `'no'`. Only when `col1` is not zero does the second WHEN clause evaluate `col2/col1 > 2`. If this condition is TRUE, the CASE

-- expression returns `'yes'`; otherwise, it returns `'no'`. The WHERE clause predicate returns TRUE only when the CASE expression yields `'yes'`. As a result, this query never attempts to divide by zero.



-- We can also use a mathematical workaround that avoids division, although it is a bit convoluted:

-- SELECT col1 col2
-- FROM dbo.T1
-- WHERE (col1 > 0 AND col2 > 2 * col1) 
--    OR (col1 < 0 AND col2 < 2 * col1);