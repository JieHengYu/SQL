-----------------------------------------------

-- Dealing with Misbehaving Subqueries

-----------------------------------------------

-- This section introduces cases in which the use of subqueries involves bugs, & it provides best practices to help avoid those bugs.



----------------------
-- NULL Trouble
----------------------

-- Remember that T-SQL uses three-valued logic because of its support for NULLs. In this section, we'll discuss problems that can occur when we forget about NULLs & the three-valued logic.



-- Consider the following query, which is supposed to return customers who did not place orders:

USE TSQLV6;

SELECT C.custid, C.companyname
FROM Sales.Customers AS C
WHERE C.custid NOT IN (SELECT O.custid
					   FROM Sales.Orders AS O);

-- With the current sample data in the `Sales.Orders` table, the query seems to work the way we expect it to, & indeed, it returns the customers 22 & 57.



-- Next, run the following code to insert a new order into the `Sales.Orders` table with a NULL customer ID:

INSERT INTO Sales.Orders (custid, empid, orderdate, requireddate, shippeddate, shipperid, freight, shipname, shipaddress, shipcity, shipregion, shippostalcode, shipcountry)
VALUES (NULL, 1, '20220212', '20220212', '20220212', 1, 123.00, N'abc', N'abc', N'abc', N'abc', N'abc', N'abc');

-- Next, run the previous query again:

SELECT C.custid, C.companyname
FROM Sales.Customers AS C
WHERE C.custid NOT IN (SELECT O.custid
					   FROM Sales.Orders AS O);

-- This time, the query returns an empty set.



-- Obviously, the culprit here is the NULL customer ID we added to the `Sales.Orders` table. The NULL is one of the elements returned by the subquery.



-- Let's start with the part that does not behave like we expect it to. The IN predicate returns TRUE for a customer who placed orders (for example, customer 85), because such customer is returned by the subquery. The NOT operator negates the IN predicate;

-- hence, the NOT TRUE becomes FALSE, & the customer is discarded. The expected behaviour here is that if a customer ID is known to appear in the `Sales.Orders` table, we know with certainty that we do not want to return it. However, if a customer ID from the

-- `Sales.Customers` table doesn't appear in the set of non-NULL customer IDs in `Sales.Orders`, & there's also a NULL customer ID in `Sales.Orders`, we can't tell with certainty that the customers is there -- & similarly, we can't tell with certainty that it's

-- not there. Confused? Lets clarity this explanation with an example.



-- The IN predicate returns UNKNOWN for a customer such as 22 that does not appear in the set of customer IDs in `Sales.Orders`. That's because when we compare it with known customer IDs, we get FALSE, & when we compare it with a NULL we get UNKNOWN. FALSE or

-- UNKNOWN yields UNKNOWN. Consider the expression `22 NOT IN (1, 2, <other non-22 values>, NULL)`. This expression can be rephrased as `NOT 22 IN (1, 2, ..., NULL)`. We can expand this expression to `NOT (22 = 1 OR 22 = 2 OR ... OR 22 = NULL)`. Evaluate each 

-- individual expression in the parentheses to know its truth value & we get `NOT (FALSE OR FALSE OR ... OR UNKNOWN)`, which translates to NOT UNKNOWN, which evaluates to UNKNOWN.



-- The logical meaning of UNKNOWN here, before we apply the NOT operator, is that it can't be determined whether the customer ID appears in the set, because the NULL could represent that customer ID. The tricky part here is that negating the UNKNOWN with the 

-- NOT operator still yields UNKNOWN. This means that in a case where it is unknown whether a customer ID appears in a set, it is also unknown whether it doesn't appear in the set. Remember that a query filter discards rows that get UNKNOWN in the result of

-- the predicate.



-- In short, when we use the NOT IN predicate against a subquery that returns at least one NULL, the query always returns an empty set. So what practices can we follow to avoid such trouble? First, when a column is not supposed to allow NULLs, be sure to 

-- define it as NOT NULL. Second, in all queries we write, we should consider NULLs & the three-valued logic. Think explicitly about whether the query might process NULLs, & if so, whether SQL's treatment of NULLs is correct for you. When it isn't, you need 

-- to intervene. For example, our query returns an empty set because of the comparison with the NULL. If we want to check whether a customer ID appears only in the set of known values, we should exclude the NULLs -- either explicitly or implicitly. To exclude

-- them explicitly, add the predicate `O.custid IS NOT NULL` to the subquery like this:

SELECT C.custid, C.companyname
FROM Sales.Customers AS C
WHERE custid NOT IN (SELECT O.custid
					 FROM Sales.Orders AS O
					 WHERE O.custid IS NOT NULL);

-- We can also exclude the NULLs implicitly by using the NOT EXISTS predicate instead of NOT IN, like this:

SELECT C.custid, C.companyname
FROM Sales.Customers AS C
WHERE NOT EXISTS (SELECT *
				  FROM Sales.Orders AS O
				  WHERE O.custid = C.custid);



-- Recall that unlike IN, EXISTS uses two-valued predicate logic. EXISTS always returns TRUE or FALSE & never UNKNOWN. When the subquery stumbles into a NULL in `O.custid`, the expression evaluates to UNKNOWN & the row is filtered out. As far as the EXISTS

-- predicate is concerned, the NULL cases are eliminated naturally, as though they weren't there. So EXISTS ends up handling only known customer IDs. There, it's safer to use NOT EXISTS than NOT IN.



-- When you're done, run the following code for cleanup:

DELETE FROM Sales.Orders WHERE custid IS NULL;



--------------------------------------------------------------
-- Substitution Errors in Subquery Column Names
--------------------------------------------------------------

-- Logical bugs in our code can sometimes be elusive. In this section, we'll cover bug related to an innocent substitution error in a subquery column name. After explaining the bug, we'll provide the best practices that help us avoid it.



-- The examples in this section query a table called `MyShippers` in the `Sales` schema. Run the following code to create & populate this table:

DROP TABLE IF EXISTS Sales.MyShippers;

CREATE TABLE Sales.MyShippers (
	shipper_id	INT			 NOT NULL,
	companyname NVARCHAR(40) NOT NULL,
	phone		NVARCHAR(40) NOT NULL,
	CONSTRAINT PK_MyShippers PRIMARY KEY(shipper_id)
);

INSERT INTO Sales.MyShippers(shipper_id, companyname, phone)
VALUES (1, N'Shipper GVSUA', N'(504) 555-0137'),
	   (2, N'Shipper ETYNR', N'(425) 555-0136'),
	   (3, N'Shipper ZHISN', N'(415) 555-0138');



-- Consider the following query, which is supposed to return shippers who shipped orders to customer 43:

SELECT shipper_id, companyname
FROM Sales.MyShippers
WHERE shipper_id IN (SELECT shipper_id
					 FROM Sales.Orders
					 WHERE custid = 43);

-- Only shippers 2 & 3 shipped orders to customer 43, but for some reason this query returned all shippers from the `Sales.MyShippers` table. Examine the query carefully & also the schemas fo the tables involved, & see if you can explain what's going on.

SELECT *
FROM Sales.Orders
WHERE custid = 43;

-- It turns out that the column name in the `Sales.Orders` table holding the shipper ID is not called `shipper_id`, but rather `shipperid` (no underscore). The column in the `Sales.MyShippers` table is called `shipper_id`, with an underscore. The resolution, 

-- or binding, of nonprefixed column names works in the context of a subquery from the inner scope outward. In our example, SQL Server first looks for the column `shipper_id` in the table in the inner query, `Sales.Orders`. Such a column is not found there,

-- so SQL Server looks for it in the table in the outer query, `Sales.MyShippers`. Such a column is found in `Sales.MyShippers`, so that is the one used.



-- You can see that what was supposed to be a self-contained subquery unintentionally became a correlated subquery. As long as the `Sales.Orders` table has at least one row, all rows from the `Sales.MyShippers` table find a match when comparing the outer

-- shipper ID with the very same shipper ID.



-- Some argue that this behaviour is a bug in SQL Server. It is indeed a bug, but not in SQL Server. It's a bug in the developer's code. This behaviour is by design in the SQL standard. The thinking in the standard is to allow us to refer to column names from

-- the outer table without a prefix as long as they are unambiguous (that is, as long as they appear in only one of the tables).



-- This problem is more common in environments that do not use consistent attribute names across tables. Sometimes, the names are only slightly different, as in this case -- `shipperid` in one table & `shipper_id` in another. That's enough for the bug to

-- manifest itself.



-- You can follow a couple of best practices to avoid such problems:

	-- Use consistent attribute names across tables.

	-- Prefix column names in subqueries with the source table name or alias (if you assigned one).

-- This way, the resolution process looks for the column only in the specified table. If it doesn't exist there, we get a resolution error. For example, try running the following code:

SELECT shipper_id, companyname
FROM Sales.MyShippers
WHERE shipper_id IN (SELECT O.shipper_id
					 FROM Sales.Orders AS O
					 WHERE O.custid = 43);

-- We should get an "Invalid column name 'shipper_id'" error. After getting this error, we can identify the problem & correct the query:

SELECT MS.shipper_id, MS.companyname
FROM Sales.MyShippers AS MS
WHERE MS.shipper_id IN (SELECT O.shipperid
						FROM Sales.Orders AS O
						WHERE O.custid = 43);

-- This time, the query returns the expected result.



-- When you're done, run the following code for cleanup:

DROP TABLE IF EXISTS Sales.MyShippers;