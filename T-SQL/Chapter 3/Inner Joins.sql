-------------------

-- Inner Joins

-------------------

-- An inner join involves two logical query processing phases. First, it forms a Cartesian product of the two input tables, just like a cross join. Then, it filters rows based on a specified predicate. As with cross joins, inner joins can be written using

-- either SQL-92 or SQL-89 syntax.



--------------------
-- SQL-92 Syntax
--------------------

-- Using the SQL-92 syntax, we specify the INNER JOIN keywords between the table names. The INNER keyword is optional, so JOIN alone is sufficient. The predicate used to filter rows is specified in the ON clause, & it is also referred to as the join condition.

-- For example, the following query performs an inner join between the `HR.Employees` & `Sales.Orders` tables, matching employees to orders based on the condition `E.empid = O.empid`:

USE TSQLV6;

SELECT E.empid, E.firstname, E.lastname, O.orderid
FROM HR.Employees AS E
	INNER JOIN Sales.Orders AS O
		ON E.empid = O.empid;



-- For most people, the simplest way to understand an inner join is to think of it as matching each employee row with all order rows that share the same employee ID. This is a simplified, intuitive explanation.



-- Formally, based on relational algebra, the join first computes a Cartesian product of the two tables (9 employee rows & 830 order rows = 7,470 rows) & then filters the results using the predicate `E.empid = O.empid`, ultimately returning 830 rows. As noted

-- earlier, this describes the logical processing of the join; the database engine may execute the query differently in practice.



-- Recall that SQL uses three-valued predicate logic. Just like in the WHERE & HAVING clauses, the ON clause returns only rows for which the predicate evaluates to TRUE; rows for which the predicate evaluates to FALSE or UNKNOWN are excluded.



-- In the TSQLV6 database, every employee has related orders, so all employees appear in the output. However, if some employees had no matching orders, they would be filtered out during the join. The same logic applies to orders without related employees,

-- though in this database, a foreign-key constraint & the fact that the `empid` column in `Sales.Orders` disallows NULL values prevents such cases.



----------------------
-- SQL-89 Syntax
----------------------

-- Like cross joins, inner joins can also be written using SQL-89 syntax. In this form, table names are separated by commas, & the join condition is specified in the WHERE clause, as shown below:

SELECT E.empid, E.firstname, E.lastname, O.orderid
FROM HR.Employees AS E, Sales.Orders AS O
WHERE E.empid = O.empid;



-- Both SQL-89 & SQL-92 syntaxes are part of the SQL standard, fully supported by T-SQL, & interpreted the same way by the database engine, so there is no expected difference in performance. However, one syntax is considered safer, as discussed in the next

-- section.



--------------------------
-- Inner Join Safety
--------------------------

-- It is strongly recommended to use SQL-92 join syntax for several reasons. First, it is the only standard syntax that supports all three fundamental join types: cross, inner, & outer. Second, it is less error-prone. For example, suppose you intend to write

-- an inner join but accidently omit the join condition. With SQL-92 syntax, the query is invalid, & the parse immediately generates an error. Consider the following code:

SELECT E.empid, E.firstname, E.lastname, O.orderid
FROM HR.Employees AS E
	INNER JOIN Sales.Orders AS O;

-- Although the error message may not immediately indicate that the problem is a missing join condition (i.e., a missing ON clause), we can usually identify & correct it. However, if the join condition is omitted using SQL-89 syntax, the query is still valid

-- & executes as a cross join:

SELECT E.empid, E.firstname, E.lastname, O.orderid
FROM HR.Employees AS E, Sales.Orders AS O;



-- Because the query executes without error, the logical mistake may go unnoticed for some time, & users of the application could end up relying on incorrect results. While it is unlikely that a programmer would forget a join condition in short, simple queries,

-- most production queries are far more complex, often involving multiple tables, filters, & other elements. In such cases, the risk of omitting a join condition increases.



-- If you are convinced that SQL-92 syntax is important for inner joins, we may wonder whether the same recommendation applies to cross joins. Since cross joins do not require a join condition, it might seem that either syntax is fine. However, it is still

-- best to stick with SQL-92 for the sake of consistency. As noted earlier, SQL-92 is the only standard syntax that supports all three fundamental join types. Mixing SQL-92 & SQL-89 styles within the same query -- especially when multiple joins are involved -- 

-- can lead to code that is harder to read & maintain.
