--------------------------

-- More Join Examples

--------------------------

-- This section covers further join considerations, including composite joins, non-equi joins, & multi-join queries.



-----------------------
-- Composite Joins
-----------------------

-- A composite join is a join that matches multiple columns from each table. This type of join is typically needed when a primary key-foreign key relationship involves more than one column. For example, suppose the table `dbo.Table2` has a foreign key on

-- columns `col1` & `col2` that references `dbo.Table1` on the same columns. To join the two tables based on this relationship, the FROM clause of the query would look like this:

-- `FROM dbo.Table1 AS T1
--      INNER JOIN dbo.Table2 AS T2
--          ON T1.col1 = T2.col1
--          AND T2.col2 = T2.col2;`

-- The join condition in this INNER JOIN is considered composite because it is based on multiple attributes in the ON clause.



-----------------------
-- Non-Equi Joins
-----------------------

-- When a join condition uses only the equality operator (=), the join is called an equi join. If the join condition uses any operator other than equality, it is called a non-equi join. As an example of a non-equi join, the following query joins two instances 

-- of the `HR.Employees` table to produce unique pairs of employees:

USE TSQLV6;

SELECT E1.empid, E1.firstname, E2.lastname,
	E2.empid, E2.firstname, E2.lastname
FROM HR.Employees AS E1
	INNER JOIN HR.Employees AS E2
		ON E1.empid < E2.empid;

-- Notice the predicate specified in the ON clause. The query is desgined to produce unique employee pairs. 

	-- If a cross join had been used, the result would have included self-pairs (e.g., employee 1 paired with employee 1) & mirrored pairs (e.g., employee 1 paired with employee 2, & employee 2 paired with employee 1).

	-- Using an inner join with the condition `E1.empid < E2.empid` eliminates these inapplicable cases:
		
		-- Self-pairs are excluded because no value is less than itself.

		-- Mirrored pairs are reduced to a single instance because only one of the two possible orderings satisfies the < condition.

-- In this example, out of the 81 possible pairs a cross join would have produced, the query returns 36 unique pairs of employees.



-- If the behaviour of this query is still unclear, try processing it step by step using a smaller set of employees. For example, suppose the `HR.Employees` table contains only employees 1, 2, & 3. 

-- Step 1: Produce the Cartesian product of two instances of the table:

SELECT E1.empid, E2.empid
FROM (SELECT empid
      FROM HR.Employees
	  WHERE empid IN (1, 2, 3)) AS E1
	CROSS JOIN (SELECT empid
				FROM HR.Employees
				WHERE empid IN (1, 2, 3)) AS E2;

-- This produces all possible pairs of employees.

-- Step 2: Apply the join condition `E1.empid < E2.empid` to filter the pairs:

SELECT E1.empid, E2.empid
FROM (SELECT empid
      FROM HR.Employees
	  WHERE empid IN (1, 2, 3)) AS E1
	CROSS JOIN (SELECT empid
				FROM HR.Employees
				WHERE empid IN (1, 2, 3)) AS E2
WHERE E1.empid < E2.empid;

-- After applying the filter, only the unique pairs remain, leaving three rows (1, 2), (1, 3), & (2, 3).



---------------------------
-- Multi-Join Queries
---------------------------

-- A join table operator operates on two tables at a time, but a single query can include multiple joins. In general, when multiple table operators appear in the FROM clause, they are logically processed in the order written. That is:

	-- 1. The result of the first join becomes the left input for the second join.

	-- 2. The result of the second join becomes the left input for the third join, & so on.

-- In other words, the first join operates on two base tables, while subsequent joins operate on the result of the preceding join as their left input. For example, the following query first joins the `Sales.Customers` & `Sales.Orders` tables to match customers

-- with their orders. Then, it joins the result of that first join with the `Sales.OrderDetails` table to match orders with their order lines:

SELECT C.custid, C.companyname, O.orderid,
	OD.productid, OD.qty
FROM Sales.Customers AS C
	INNER JOIN Sales.Orders as O
		ON C.custid = O.custid
	INNER JOIN Sales.OrderDetails AS OD
		ON O.orderid = OD.orderid;



-- For cross joins & inner joins, the database engine may internally rearrange the join order for optimisation purposes. This reordering does not affect the correctness of the query result.
