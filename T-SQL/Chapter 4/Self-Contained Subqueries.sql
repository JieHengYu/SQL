-----------------------------------

-- Self-Contained Subqueries

-----------------------------------

-- Self-contained subqueries are subqueries that do not depend on the tables in the outer query. They are often easier to debug, since we can run the inner query independently to verify that it produces the expected result. Logically, a self-contained subquery

-- is evaluated once before the outer query, & the outer query then uses its result. The following sections present concrete examples of self-contained subqueries.



----------------------------------------------------
-- Self-Contained Scalar Subquery Examples
----------------------------------------------------

-- A scalar subquery is a subquery that returns a single value. Such subqueries can appear anywhere in the outer query where a single-valued expression is valid, such as in the WHERE or SELECT clause. 



-- For example, suppose we want to query the `Sales.Orders` table in the `TSQLV6` database & return information about the order with the maximum order ID. One approach is to use a variable: first retrieve the maximum order ID from the `Sales.Orders` table &

-- store it in a variable, then query the same table & filter for the order whose ID matches the stored value:

USE TSQLV6;

DECLARE @maxid AS INT = (SELECT MAX(orderid)
						 FROM Sales.Orders);

SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderid = @maxid;

-- We can simplify this by replacing the variable with a scalar self-contained subquery, as shown below:

SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderid = (SELECT MAX(orderid)
	             FROM Sales.Orders);



-- For a scalar subquery to be valid, it must return at most one value. If it returns more than one, the query fails at run time.

SELECT O.orderid
FROM Sales.Orders AS O
WHERE O.empid = (SELECT E.empid
			     FROM HR.Employees AS E
			     WHERE E.lastname LIKE N'C%');

-- This query is intended to return orders placed by employees whose last name begins with the letter `'C'`. The subquery retrieves the IDs of employees whose last names match this pattern, & the outer query returns orders where the employee ID equals the 

-- subquery's result.



-- Because the equality operator requires scalar operands, the subquery is treated as scalar. However, since multiple employees can have last names starting with `'C'`, the subquery may return more than one value, which would cause the query to fail. In this

-- particular case, the query succeeds only because the `HR.Employees` table currently contains just one matching employee -- Maria Cameron (employee ID 8).



-- If a scalar subquery returns more than one value, the query fails. For example, consider the following query, which looks for orders placed by employees whose last names start with `'D'`:

SELECT O.orderid
FROM Sales.Orders AS O
WHERE O.empid = (SELECT E.empid
			     FROM HR.Employees AS E
			     WHERE E.lastname LIKE N'D%');

-- In this case, two employees -- Sara Davis & Patricia Doyle -- have last names beginning ith `'D'`. As a result, the subquery produces multiple values, & the query fails at run time with an error.



-- If a scalar subquery returns no value, the result is treated as NULL. Recall that any comparison with NULL evaluates to UNKNOWN, & rows for which the filter expression evaluates to UNKNOWN are not returned. For example, since the `HR.Employees` table

-- currently contains no employees whose last name begins with `'A'`, the following query returns an empty set:

SELECT O.orderid
FROM Sales.Orders AS O
WHERE O.empid = (SELECT E.empid
				 FROM HR.Employees AS E
				 WHERE E.lastname LIKE N'A%');



--------------------------------------------------------
-- Self-Contained Multivalued Subquery Examples
--------------------------------------------------------

-- A multivalued subquery is a subquery that returns multiple values in a single column. Certain predicates, such as IN, are designed on multivalued subqueries.

	-- Syntax: <scalar_expression> IN (<multivalued subquery>)

-- The predicate evaluates to TRUE if the scalar expression matches any of the values returned by the subquery.



-- Recall the example from the previous section: returning orders handled by employees whose last names begin with a certain letter. Since multiple employees may share the same initial, this request should be handled with the IN predicate rather than an

-- equality operator. For instance, the following query returns orders placed by employees whose last names start with `'D'`:

SELECT O.orderid
FROM Sales.Orders AS O
WHERE O.empid IN (SELECT E.empid
				  FROM HR.Employees AS E
				  WHERE E.lastname LIKE N'D%');

-- Because this solution uses the IN predicate, the query remains valid regardless of how many values the subquery returns -- whether none, one, or many.



-- You might wonder why we don't implement this task with a join instead of a subquery, as shown here:

SELECT O.orderid
FROM HR.Employees AS E
	INNER JOIN Sales.Orders AS O
		ON E.empid = O.empid
WHERE E.lastname LIKE N'D%';

-- In practice, many querying tasks can be solved with either subqueries or joins. There is no universal rule that makes one approach inherently better. In some cases, the database optimises both in the same way; in others, joins perform better, while in

-- others subqueries do.



-- A good strategy is to start with the version that feels most intuitive. If performance is unsatisfactory, explore alternative rewrites -- such as replacing a subquery with a join or vice versa -- alongside other tuning methods. It can also be useful to 

-- keep different rewrites available, since future changes in the database may cause one version to outperform the other.



-- As another example of a multivalued subquery, suppose we want to return orders placed by customers from the United States. We can query the `Sales.Orders` table & filter for orders whose customer IDs are found in the set of customer IDs of U.S. customers.

-- This condition can be expressed with a self-contained multivalued subquery. Here's the complete solution:

SELECT O.custid, O.orderid, O.orderdate, O.empid
FROM Sales.Orders AS O
WHERE O.custid IN (SELECT C.custid
				   FROM Sales.Customers AS C
				   WHERE C.country = N'USA');



-- As with other predicates, the IN predicate can be negated with the NOT operator. For example, the following query returns customers who have not placed any orders:

SELECT C.custid, C.companyname
FROM Sales.Customers AS C
WHERE C.custid NOT IN (SELECT O.custid
					   FROM Sales.Orders AS O);

-- It is considered best practice to qualify the subquery by filtering out NULL values. The subquery returns the IDs of all customers that appear in the `Sales.Orders` table -- that is, customers who have placed at least one order. The outer query then

-- returns those customers whose IDs are not in that list, meaning customers who have not placed any orders.



-- You might wonder whether adding a DISTINCT clause to the subquery could improve performance, since the same customer ID can appear multiple times in the `Sales.Orders` table. However, the database engine is smart enough to account for duplicates on its

-- own, so explicitly specifying DISTINCT is unnecessary in this case.



-- The final example in this section demonstrates how to use multiple self-contained subqueries in a single query -- both scalar & multivalued. Before introducing the task, we first create a table named `dbo.Orders` in the `TSQLV6` database & populate it

-- with the even-numbered order IDs from the `Sales.Orders` table:

DROP TABLE IF EXISTS dbo.Orders;

CREATE TABLE dbo.Orders(orderid INT NOT NULL CONSTRAINT PK_orders PRIMARY KEY);

INSERT INTO dbo.Orders(orderid)
	SELECT orderid
	FROM Sales.Orders
	WHERE orderid % 2 = 0;

SELECT orderid
FROM dbo.Orders;



-- Suppose we need to write a query of all order IDs missing between the minimum & maximum values in the table. Solving this task without helper tables or functions can be quite complex. One useful tool is the `dbo.Nums` table, which contains a continuous

-- sequence of integers starting at 1 with no gaps. 



-- Starting with SQL Server 2022, we could alternatively use the GENERATE_SERIES functions to produce such a sequence. In this example, however, we will use the `dbo.Nums` table.



-- To return all missing order IDs, we query `dbo.Nums` & filter for numbers that:

	-- 1. fall between the minimum & maximum order IDs in `dbo.Orders`, &

	-- 2. do not already appear as order IDs in `dbo.Orders`.

-- Scalar self-contained subqueries provide the minimum & maximum order IDs, while a multivalued self-contained subquery supplies the set of existing order IDs. Here is the complete solution:

SELECT Nums.n
FROM dbo.Nums AS Nums
WHERE Nums.n BETWEEN (SELECT MIN(O.orderid) FROM dbo.Orders AS O)
			     AND (SELECT MAX(O.orderid) FROM dbo.Orders AS O)
	AND Nums.n NOT IN (SELECT O.orderid FROM dbo.Orders AS O);



-- When you're done, run the following code for cleanup:

DROP TABLE IF EXISTS dbo.Orders;




