---------------------------------------------

-- Elements of the SELECT Statement

---------------------------------------------

-- The purpose of the SELECT statement is to query tables, apply some logical manipulation & return a result. In this section, we'll discuss phases involved in logical query processing, the order in which

-- the different query classes are processed, & what happens in each phase.

-- To describe logical query processing & the various SELECT query clauses, we'll use the below query as an example:

USE TSQLV6;

SELECT empid, YEAR(orderdate) AS orderyear, COUNT(*) AS numorders -- (Sample Query 2-1)
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate)
HAVING COUNT(*) > 1
ORDER BY empid, orderyear;

-- This query filters orders that were placed by customer 71, groups those orders by employee & order year, & then filters only employees who have more than one order during a given year. For the remaining groups, the query presents the

-- employee ID, order year, & count of orders, sorted by employee ID & order year. 



-- The code starts with a USE statement that ensures that the database context of our session is in the TSQLV6 database.



-- In most programming languages, the lines of code are processed in the order that they are written. SQL works differently. Although the SELECT clause appears first in the query, it is actually processed near the end. The logical

-- processing order of SQL clauses is as follows:

-- 1. FROM
-- 2. WHERE
-- 3. GROUP BY
-- 4. HAVING
-- 5. SELECT
-- 6. ORDER BY

-- So even though syntactically the sample query starts with the SELECT clause; logically, its clauses are processed in the following order:

-- FROM Sales.Orders
-- WHERE custid = 71
-- GROUP BY empid, YEAR(orderdate)
-- HAVING COUNT(*) > 1
-- SELECT empid, YEAR(orderdate) AS orderyear, COUNT(*) AS numorders
-- ORDER BY empid, orderyear;

-- Or, to present it in a more readable manner, here's what the query does:

-- 1. Queries the rows from the `Sales.Orders` table
-- 2. Filters only orders where the customer ID is equal to 71
-- 3. Groups the orders by employee ID & order year
-- 4. Filters only groups (employee ID & order year) having more than one order
-- 5. Selects (returns) for each group the employee ID, order year, & number of orders
-- 6. Orders (sorts) the rows in the output by employee ID & order year



----------------------------
-- The FROM Clause
----------------------------

-- The FROM clause is the very first query clause that is logically processed. In this clause, we specify the name(s) of the table(s) we want to query.



-- To return all rows from a table with no special manipulation, all we need is a query with a FROM clause, in which we specify the table we want to query, & a SELECT clause, in which we specify the attributes

-- we want to return. For example, the following statement queries all rows from the `Orders` table in the `Sales` schema, selecting the attributes `orderid`, `custid`, `empid`, `orderdate`, & `freight`:

SELECT orderid, custid, empid, orderdate, freight
FROM Sales.Orders;

-- The output of this statement is shown below in the results bar.



--------------------------
-- The WHERE Clause
--------------------------

-- In the WHERE clause, we specify a predicate, or logical expressions, to filter the rows returned by the FROM phase. Only rows for which the logical expression evaluates to TRUE are returned by the WHERE phase to the subsequent 

-- logical query processing phase. In sample query 2-1, the WHERE phase filters only orders placed by customer 71. Out of the 830 rows returned by the FROM phase, the WHERE phase filters only the 31 rows where the customer ID

-- is equal to 71. To see which rows we get back after applying the filter, `custid = 71`, we'll run the following query:

SELECT orderid, empid, orderdate, freight
FROM Sales.Orders
WHERE custid = 71;

-- The query should generate an output with 31 rows.



-- Only rows for which the logical expression evaluates to TRUE are returned by the WHERE phase. T-SQL uses three-valued predicate logic, where logical expressions can evaluate to TRUE, FALSE, or UNKNOWN. With three-valued logic, 

-- saying "returns TRUE" is not the same as saying "does not return FALSE". The WHERE phase returns rows for which the logical expression evaluates to TRUE, & it doesn't return rows for which the logical expression evaluates to FALSE

-- or UNKNOWN.



----------------------------------
-- The GROUP BY Clause
----------------------------------

-- We can use the GROUP BY phase to arrange the rows returned by the previous logical query processing phase in groups. The groups are determined by the elements, or expressions, we specify in the GROUP BY clause. For example, the

-- GROUP BY clause in sample query 2-1 has the elements `empid` & `YEAR(orderdate)`. This means that the GROUP BY phase produces a group for each distinct combination of employee-ID & order-year values that appear in the

-- data returned by the WHERE phase. The expression `YEAR(orderdate)` invokes the YEAR function to return only the year part from the `orderdate` column.



-- The WHERE phase returns 31 rows, within which there are 16 distinct combinations of employee-ID & order-year values, as shown in the results bar when we run the following query:

SELECT empid, YEAR(orderdate) AS orderyear
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate);

-- Thus, the GROUP BY phase creates 16 groups & associates each of the 31 rows returned from the WHERE phase with the relevant group.



-- If the query is a grouped query, all phases subsequent to the GROUP BY phase -- including HAVING, SELECT, & ORDER BY -- operate on groups as opposed to operating on individual rows. Each group is ultimately represented by a

-- single row in the final result of the query. All expressions we specify in clauses that are processed in phases subsequent to the GROUP BY phase are required to guarantee returning a scalar (single value) per group.



-- Elements that do not participate in the GROUP BY clause are allowed only as inputs to an aggregate function such as COUNT, SUM, AVG, MIN, or MAX. For example the following query returns the total freight & number of orders

-- per employee & order year.

SELECT empid,
	   YEAR(orderdate) AS orderyear,
	   SUM(freight) AS totalfreight,
	   COUNT(*) AS numorders
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate);



-- The expression `SUM(freight)` returns the sum of all freight values in each group, & the function `COUNT(*)` returns the count of rows in each group -- which in this case means the number of orders. If we try to refer to an 

-- attribute that does not participate in the GROUP BY clause (such as `freight`) & not as an input to an aggregate function in any clause that is processed after the GROUP BY clause, you'll get an error -- in such a case,

-- there's no guarantee that the expression will return a single value per group. For example, the following query will fail:

SELECT empid, YEAR(orderdate) AS orderyear, freight
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate);




-- Note that all aggregate functions that are applied to an input expression ignore NULLs. The `COUNT(*)` function isn't applied to any input expression; it just counts rows irrespective of what those rows contain. For example,

-- consider a group of five rows with the values 30, 10, NULL, 10, 10, in a column called `qty`. The expression `COUNT(*)` returns 5 because there are five rows in the group, whereas `COUNT(qty)` returns 4 because there are four

-- known (non-NULL) values.



-- If you want to handle only distinct (unique) occurrences of knwon values, specify the DISTINCT keyword before the input expression to the aggregate function. For example, the expression `COUNT(DISTINCT qty)` returns 2, because

-- there are two distinct known values (30 & 10). The DISTINCT keyword can be used with other functions as well. For example, although the expression `SUM(qty)` returns 60, the expression `SUM(DISTINCT qty)` returns 40. The

-- expression `AVG(qty)` returns 15, whereas the expression `AVG(DISTINCT qty)` returns 20. As an example of using the `DISTINCT` option with an aggregate function in a complete query, the following code returns the number of 

-- distinct customers handled by each employee in each order year:

SELECT empid,
	   YEAR(orderdate) AS orderyear,
	   COUNT(DISTINCT custid) AS numcusts
FROM Sales.Orders
GROUP BY empid, YEAR(orderdate);



-- The aggregate functions that are covered in this section, including MAX & MIN functions, are grouped aggregate functions. They operate on sets of rows that are defined by the query's grouping. However, sometimes we need to apply 

-- maximum & minimum calculations across columns. In SQL Server 2022, this is achievable with the functions GREATEST & LEAST.



---------------------------
-- The HAVING Clause
---------------------------

-- Whereas the WHERE clause is a row filter, the HAVING clause is a group filter. Only groups for which the HAVING predicate evaluates to TRUE are returned by the HAVING phase to the next logical query processing phase. Groups

-- for which the predicate evaluates to FALSE or UNKNOWN are discarded. 



-- Because the HAVING clause is processed after the rows have been grouped, we can refer to aggregate functions in the HAVING filter predicate. For example, in the sample query 2-1, the HAVING clause has the predicate `COUNT(*) > 1`,

-- meaning that the HAVING phase filters only groups (employee & order year) with more than one row. 



-- Recall that the GROUP BY phase created 16 groups of employee ID & order year. 

SELECT empid, YEAR(orderdate) AS orderyear, COUNT(*) AS num_orders
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate);

-- Seven of those groups have only one row, so after the HAVING clause is processed, nine groups remain:

SELECT empid, YEAR(orderdate) AS orderyear
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate)
HAVING COUNT(*) > 1;



-------------------------
-- The SELECT Clause
-------------------------

-- The SELECT clause is where we specify the attributes (columns) we want to return in the result table of the query. For example, the SELECT list in sample query 2-1 has the following expressions: `empid`, `YEAR(orderdate)`, & `COUNT(*)`. 

-- If an expression refers to an attribute with no manipulation, such as `empid`, the name of the target attribute is the same as the name of the source attribute. We can optionally assign our own name to the target attribute by using 

-- the AS clause -- for example `empid AS employee_id`. Expressions that do manipulation, such as `YEAR(orderdate)`, or that are not based on a source attribute, such as a call to the function SYSDATETIME, won't have a name unless we 

-- alias them. T-SQL allows a query to return anonymous result columns in certain cases, so its generally recommended that we ensure that all result columns have names by aliasing the ones that would otherwise be anonymous.



-- In addition to supporting the AS clause, T-SQL supports a couple of other forms with which we can alias expressions, though the AS clause seems the most readable & intuitive form, so it's generally the most recommended. T-SQL also

-- supports the forms `<alias> = <expression>` ("alias equals expression") & `<expression> <alias>` ("expression space alias"). An example of the former is `orderyear = YEAR(orderdate)` & an example of the latter is 

-- `YEAR(orderdate) orderyear`. However, keep in mind that often, code that we write needs to be reviewed & maintained by other developers, or even by yourself at a later date, so code clarity is important.



-- Note that if by mistake, we miss a comma between two column names in the SELECT list, our code won't fail. Instead, SQL Server will assume the second name is an alias for the first column name. As an example, suppose we want to 

-- query the columns `orderid` & `orderdate` from the `Sales.Orders` table & we miss the comma between them, as follows:

SELECT orderid orderdate
FROM Sales.Orders;

-- This query is considered syntactically valid, as if we intended to alias the `orderid` column as `orderdate`. In the output, we'll only get one column holding the order IDs, with the alias `orderdate`. So, if you get accustomed to

-- using the syntax with the space between an expression & its alias, it will be harder for you to detect such bugs.



-- With the addition of the SELECT phase, the following query clauses from sample query 2-1 have been processed so far.

SELECT empid, YEAR(orderdate) AS orderyear, COUNT(*) AS numorders
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate)
HAVING COUNT(*) > 1;

-- The SELECT clause produces the result table of the query, where the heading has the attributes `empid`, `orderyear`, & `numorders`, & the body has nine rows.



-- Remember that the SELECT clause is processed after the FROM, WHERE, GROUP BY, & HAVING clauses. This means that any aliases defined in the SELECT clause are not yet available to the earlier clauses. A common mistake is to try to 

-- reference a column alias too soon -- for example, in the WHERE clause:

SELECT orderid, YEAR(orderdate) AS orderyear
FROM Sales.Orders
WHERE orderyear > 2021;

-- At first glance, this query might seem valid, but if we consider that the column aliases are created in the SELECT phase -- which is processed after the WHERE phase -- we can see that the reference to the `orderyear` alias in the WHERE

-- clause is invalid. Consequently, SQL server produces an invalid column name error. One way around this problem is to repeat the expression `YEAR(orderdate)` in both the WHERE & SELECT clauses:

SELECT orderid, YEAR(orderdate) AS orderyear
FROM Sales.Orders
WHERE YEAR(orderdate) > 2021;

-- A similar problem can happen if we try to refer to an expression alias in the HAVING clause, which is also processed before the SELECT clause:

SELECT empid, YEAR(orderdate) AS orderyear, COUNT(*) AS numorders
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate)
HAVING numorders > 1;

-- This query fails with an error saying that the column name `numorders` is invalid. Just like in the previous example, the workaround here is to repeat the expression `COUNT(*)` in both clauses:

SELECT empid, YEAR(orderdate) AS orderyear, COUNT(*) AS numorders
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate)
HAVING COUNT(*) > 1;



-- A table in SQL isn't required to have a key. Without a key, the table can have duplicate rows & therefore isn't relational. Even if the table does have a key, a SELECT query against the table can still return duplicate rows. SQL 

-- query results do not have keys. As an example, the `Sales.Orders` table does have a primary key defined on the `orderid` column. Still, the following query against the `Sales.Orders` table returns duplicate rows:

SELECT empid, YEAR(orderdate) AS orderyear -- (Sample Query 2-2)
FROM Sales.Orders
WHERE custid = 71;

-- SQL provides the means to remove duplicates using the DISTINCT clause, & in this sense, return a relational result.

SELECT DISTINCT empid, YEAR(orderdate) AS orderyear -- (Sample Query 2-3)
FROM Sales.Orders
WHERE custid = 71;

-- Note that the DISTINCT clause here applies to the combination of `empid` & `orderyear`. Of the 31 rows returned by sample query 2-2, 16 rows are in the result returned by sample query 2-3 after the removal of duplicates.



-- SQL allows specifying an asterisk (*) in the SELECT list to request all attributes from the queried tables instead of listing them explicitly, as in the following example:

SELECT *
FROM Sales.Shippers;

-- Such use of an asterisk is considered a bad programming practice in most cases & it's recommended that we explicitly list all attributes that we need.



-- Curiously, we aren't allowed to refer to column aliases created in the SELECT clause in other expressions within the same SELECT clause. That's the case even if the expression that tries to use the alias appears after the

-- expression that created it. For example, the following attempt is invalid:

SELECT orderid,
	   YEAR(orderdate) AS orderyear,
	   orderyear + 1 AS nextyear
FROM Sales.Orders;

-- Similar as with before, one of the ways around this problem is to repeat the expression:

SELECT orderid,
	   YEAR(orderdate) AS orderyear,
	   YEAR(orderdate) + 1 as nextyear
FROM Sales.Orders;



-------------------------------
-- The ORDER BY Clause
-------------------------------

-- We use the ORDER BY clause to sort the rows in the output for presentation purposes. In terms of logical query processing, ORDER BY comes after the SELECT phase. The sample query below orders the rows in the output by employee ID & order year.

SELECT empid, YEAR(orderdate) AS orderyear, COUNT(*) AS numorders
FROM Sales.Orders
WHERE custid = 71
GROUP BY empid, YEAR(orderdate)
HAVING COUNT(*) > 1
ORDER BY empid, orderyear;



-- One of the most important points to understand about SQL is that a table -- be it an existing one in the database or a table result returned by a query -- has no guaranteed order. That's because a table is supposed to represent a set of

-- rows, & a set has no order. This means that when we query a table without specifying the ORDER BY clause, SQL Server is free to return the rows in the output in any order. The only way for use to guarantee the presentation order in the

-- result is with an ORDER BY clause.



-- Notice, in the query above, that the ORDER BY clause refers to the column alias `orderyear`, which was created in the SELECT phase. The ORDER BY phase is the only phase in which we can refer to column aliases created in the SELECT

-- phase, because it is the only phase processed after the SELECT phase. Note that if we define a column alias that is the same as the underlying column name, as in `1 - col1 AS col1`, & refer to that alias in the ORDER BY clause, the new

-- column is the one considered for ordering.



-- When we want to order the rows by some expression in an ascending order, we either specify ASC right after the expression, as in `orderyear ASC`, or don't specify anything after the expression, because ASC is the default. If we 

-- want to sort in descending order, we need to specify DESC after the expression as in `orderyear DESC`.



-- We can also specify elements in the ORDER BY clause that do not appear in the SELECT clause, meaning we can sort by something we don't necessarily want to return. For example, the following query sorts the employee rows by hire date without 

-- returning the `hiredate` attribute:

SELECT empid, firstname, lastname, country
FROM HR.Employees
ORDER BY hiredate;

-- However, when the DISTINCT clause is specified, we are restricted in the ORDER BY list only to elements that appear in the SELECT list. The reasoning behind this restriction is that when DISTINCT is specified, a single result row

-- might represent multiple source rows; therefore, it might not be clear which of the values in the multiple rows should be used. Consider the following invalid query:

SELECT DISTINCT country
FROM HR.Employees
ORDER BY empid;

-- There are nine employees in the `HR.Employees` table -- five from the United States & four from the United Kingdom. If we omit the invalid ORDER BY clause from this query, we get two rows back -- one for each distinct country. Because

-- each country appears in multiple rows in the source table, & each such row has a different employee IDs, the meaning of `ORDER BY empid` is not really defined.



-----------------------------------------
-- The TOP & OFFSET-FETCH Filter
-----------------------------------------

-- In this section, we'll cover the filtering clauses TOP & OFFSET-FETCH, which are based on number of rows & ordering.



-- The TOP filter is a proprietary T-SQL feature we can use to limit the number or percentage of rows our query returns. It relies on two elements as part of its specification: one is the number or percent of rows to return, & the 

-- other is the ordering. For example, to return from the `Sales.Orders` table the five most recent orders, we specify `TOP(5)` in the SELECT clause & `orderdate DESC` in the ORDER BY clause, as shown below:

SELECT TOP (5) orderid, orderdate, custid, empid -- (Sample Query 2-5)
FROM Sales.Orders
ORDER BY orderdate DESC;



-- Note that the TOP filter is handled after DISTINCT. This means that if DISTINCT is specified in the SELECT clause, the TOP filter is evaluated after duplicated rows have been removed.

-- Also note that when the TOP filter is specified, the ORDER BY clause serves a dual purpose in the query. One purpose is to define the presentation ordering for the rows in the query result. Another purpose is to define for the TOP option

-- which rows to filter. The query above returns the five rows with the most recent `orderdate` values & presents the rows in the output in `orderdate DESC` ordering.



-- You can use the TOP option with the PERCENT keyword, in which case SQL Server calculates the number of rows to return based on a percetnage of the numbers of qualifying rows, rounded up. For example, the following query requsests the 

-- top 1 percent of the most recent orders:

SELECT TOP (1) PERCENT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;

-- The query returns nine rows because the `Sales.Orders` table has 830 rows, & 1 percent of 830, rounded up, is 9.



-- Note that we can even use the TOP filter in a query without an ORDER BY clause. In such a case, the ordering is completely undefined -- SQL Server returns whichever n rows it happens to physically access first, where n is the 

-- requested number of rows. 



-- Notice that in the output for sample query 2-5 that the minimum order date in the rows returned is May 5, 2022, & one row in the output has that date. Other rows in the table might have the same order date, & with the existing

-- non-unique ORDER BY list, there is no guarantee which one will be returned. If we want the query to be deterministic, we need strict toal ordering; in other words, add a tiebreaker. For example, we can add `orderid DESC` to 

-- the ORDER BY list as shown in the query below, so that in case of ties, the row with the greater order ID value will be preferred.

SELECT TOP (5) orderid, orderdate, custid, empid -- (Sample Query 2-6)
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC;



-- If you examine the results of the sample queries 2-5 & 2-6, you'll notice that they seem the same. The important difference is that the result shown in the query output for sample query 2-5 is one of several possible valid results

-- for its query, whereas the result shown in the output for sample query 2-6 is the only possible valid result.



-- Instead of adding a tiebreaker to the ORDER BY list, we can request to return all ties. For example, we can ask that in addition to the five rows we get back from sample query 2-5, all the other rows from the table be returned that 

-- have the same sort value (order date, in this case) as the last one found (May 5, 2022, in this case). We achieve by adding the WITH TIES option, as shown in the following query:

SELECT TOP (5) WITH TIES orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;

-- Notice that the output has eight rows, even though we specified `TOP (5)`. SQL Server first returned the `TOP (5)` rows based on the `orderdate DESC` ordering, & it also returned all other rows from the table that had the same

-- `orderdate` value as in the last of the five rows that were accessed. Using the `WITH TIES` option, the selection of rows is deterministic, but the presentation order among rows with the same order date isn't.



-- The TOP filter is useful but has two main limitations: it isn't part of the SQL standard & it doesn't allow skipping rows. T-SQL also supports a standard, TOP-like filter called OFFSET-FETCH, which does provide row-skipping. In 

-- the SQL standard, OFFSET-FETCH is defined as an extension of the ORDER BY clause. The OFFSET clause specifies how many rows to skip, while the FETCH clause specifies how many rows to return after the skipped rows. As an example, 

-- consider the following query:

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate, orderid
OFFSET 50 ROWS FETCH NEXT 25 ROWS ONLY;

-- This query orders the rows from the `Sales.Orders` table based on the `orderdate` & `orderid` attributes (from least recent to most recent, with `orderid` as the tiebreaker). Based on this ordering, the OFFSET clause skips the first

-- 50 rows & the FETCH clause filters the next 25 rows only.



-- A query that uses OFFSET-FETCH must include an ORDER BY clause. Unlike the SQL standard, however, T-SQL does not allow the FETCH clause with OFFSET. If we want to filter rows using FETCH without skipping any, we must specify 

-- `OFFSET 0 ROWS`. On the other hand, using OFFSET without FETCH is valid -- in that case, the query skips the specified number of rows & then returns all remaining rows.



-- There are interesting language aspects to note about the syntax for the OFFSET-FETCH filter. The singular & plural forms ROW & ROWS are interchangeable. The idea behind this is to allow us to phrase the filter in an intuitive,

-- English-like manner. For example, suppose you want to fetch only one row; though it would by syntactically valid, it would nevertheless look strange if we specified `FETCH 1 ROWS`. Therefore, we're allowed to use the form `FETCH 1 ROW`.

-- The same principle applies to the OFFSET clause. Also, if we're not skipping any rows (`OFFSET 0 ROWS`), we might find the term "first" more suitable than "next", Hence, the forms FIRST & NEXT are interchangeable.



-- The OFFSET-FETCH filter is more flexible than TOP because it supports skipping rows. However, the T-SQL implementation of OFFSET-FETCH does not yet support the PERCENT & WITH TIES options that TOP provides. Interestingly, the SQL

-- standard does include these options for OFFSET-FETCH. In fact, the standard uses ONLY as the alternative to WITH TIES, & it requires one of the two be specified. For this reason, even though T-SQL currently supports only the ONLY

-- option, we must explicitly include it.



-----------------------------------------
-- A Quick Look at Window Functions
-----------------------------------------

-- A window function computes a value for each row based on a related set of rows, called a window, defined by the OVER clause. This window can be restricted with PARTITION BY & ordered with ORDER BY (separate from the query's 

-- presentation ORDER BY).



-- Window functions are powerful tools for data anlysis, allowing calculations across sets of rows without collapsing them into groups. The SQL standard defines many types of window functions, & T-SQL supports a subset of these. Consider 

-- the following query as an example:

SELECT orderid, custid, val,
	   ROW_NUMBER() OVER (PARTITION BY custid ORDER BY val) AS rownum
FROM Sales.OrderValues
ORDER BY custid, val;

-- The ROW_NUMBER function assigns unique sequential incrementing integers to the rows in the result within the respective partition based on the indacted ordering. The OVER clause in this example function partitions the window by the `custid`

-- attribute. In other words, it creates a separate partition for each distinct `custid` value; hence, the row numbers are unique to each customer. The OVER clause also defines ordering in the window by the `val` attribute, so the sequential

-- row numbers are incremented within the partition based on the value in this attribute.



-- Note that the ROW_NUMBER function must produce unique values within each partition. This means that even when the ordering value doesn't increase, the row number still must increase. Therefore, if the ROW_NUMBER function's ORDER BY

-- list is non-unique, as in the preceding example, the calculation is nondeterministic. That is, more than one correct result is possible. If we want to make a row number calculation deterministic, we must add elements to the ORDER BY

-- list to make it unique. For example, in our sample query we achieved this by adding the `orderid` attribute as a tiebreaker.



-- Window ordering is different from presentation ordering. It affects how the window function calculates results, but it does not determine the order of rows in the final output. To guarantee the order of the query results, we must

-- include a presentation ORDER BY clause.



-- To put it all together, the following list presents the logical order in which all clauses discussed so far are processed:

-- 1. FROM
-- 2. WHERE
-- 3. GROUP BY 
-- 4. HAVING
-- 5. SELECT
--    * Expressions
--    * DISTINCT
-- 6. ORDER BY
--    * TOP/OFFSET-FETCH