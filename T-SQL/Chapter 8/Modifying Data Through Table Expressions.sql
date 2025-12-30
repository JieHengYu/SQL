-----------------------------------------------------

-- Modifying Data Through Table Expressions

-----------------------------------------------------

-- T-SQL doesn't restrict table expressions to SELECT statements only -- it also allows other DML statements (INSERT, UPDATE, DELETE, & MERGE) against them. 



-- Remember that a table expression doesn't actually store data; it's a logical projection of data from underlying tables. Therefore, when we modify data through a table expression, we're effectively modifying the data in the underlying tables via that

-- expression.



-- Just as a SELECT statement against a table expression is expanded internally by SQL Server, a modification statement against a table expression is also expanded & executed against the underlying table.



-- There are some restrictions when modifying data through table expressions:

	-- 1. Only one side of the join can be modified. If the query defining the table expression includes a join, we can affect only one of the joined tables in a single modification statement -- not both.

	-- 2. Computed columns cannot be updated. We cannot update a column derived from an expression or calculation; SQL Server doesn't attempt to "reverse-engineer" such values.

	-- 3. INSERT statements must provide explicit values. When inserting through a table expression, we must supply explicit values for columns that don't receive implicit values. Columns can receive values implicitly when:

		-- They allow NULLs

		-- They have a default constraint

		-- They use the IDENTITY property

		-- They are of type ROWVERSION



-- One advantage of modifying data through table expressions is improved debugging & troubleshooting. For example, consider the following UPDATE statement:

USE TSQLV6;

UPDATE OD
	SET discount += 0.05
FROM dbo.OrderDetails AS OD
	INNER JOIN dbo.Orders AS O
		ON OD.orderid = O.orderid
WHERE O.custid = 1;

-- Suppose we want to preview which rows this statement would modify, without actually updating the data. One option is to temporarily rewrite the statement as a SELECT, test it, & then convert it back to an UPDATE. A more convenient approach is to define

-- a table expression (for example, a CTE) & run the UPDATE against that expression:

WITH C AS (
	SELECT custid, OD.orderid,
		productid, discount, discount + 0.05 AS newdiscount
	FROM dbo.OrderDetails AS OD
		INNER JOIN dbo.Orders AS O
			ON OD.orderid = O.orderid
	WHERE O.custid = 1
)
UPDATE C
	SET discount = newdiscount;

-- The same logic can be expressed with a derived table:

UPDATE D	
	SET discount = newdiscount
FROM (SELECT custid, OD.orderid,
		  productid, discount, discount + 0.05 AS newdiscount
	  FROM dbo.OrderDetails AS OD
		  INNER JOIN dbo.Orders AS O
			  ON OD.orderid = O.orderid
	  WHERE O.custid = 1) AS D;

-- Using a table expression makes troubleshooting easier becuase you can simply run the inner SELECT query to see which rows would be affected, without altering any data.



-- In some scenarios, using a table expression isn't just convenient -- it's required. Consider the following setup:

DROP TABLE IF EXISTS dbo.T1;
CREATE TABLE dbo.T1(col1 INT, col2 INT);
GO

INSERT INTO dbo.T1(col1) VALUES(20), (10), (30);

SELECT * FROM dbo.T1;

-- Now suppose we want to update `col2` with the result of a ROW_NUMBER() function. The problem is that window functions like ROW_NUMBER cannot be used directly in the SET clause:

UPDATE dbo.T1
	SET col2 = ROW_NUMBER() OVER (ORDER BY col1);

-- Running this will raise the error: "Window functions can only appear in the SELECT or ORDER BY clauses." To work around this, define a table expression that computes both the target column (`col2`) & the windowed value (`rownum`), & then perform the 

-- UPDATE against the table expression:

WITH C AS (
	SELECT col1, col2, ROW_NUMBER() OVER (ORDER BY col1) AS rownum
	FROM dbo.T1
)
UPDATE C
	SET col2 = rownum;

-- Finally, query the table to verify the update:

SELECT * FROM dbo.T1;
