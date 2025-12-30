-----------------------------------------

-- Inline Table-Valued Functions

-----------------------------------------

-- Inline table-valued functions (inline TVFs) are reusable table expressions that accept input parameters. Aside from parameter support, inline TVFs behave much like views. For this reason, they are often thought of as "parameterised views", although 

-- that is not their formal name.



-- T-SQL also supports multi-statement TVFs, which return the contents of a table variable. Unlike inline TVFs, there are not considered table expressions, since they are not directly based on a single query.



-- When creating an inline TVF, the syntax differs slightly from that of a view. The function header must include a RETURNS TABLE clause, indicating that the function conceptually returns a table. In addition, the definition requires a RETURN keyword

-- before the inner query, which is not part of a view definition. As an example, the following code creates an inline TVF called `dbo.GetCustOrders` in the `TSQLV6` database:

USE TSQLV6;
GO

CREATE OR ALTER FUNCTION dbo.GetCustOrders
	(@cid AS INT) RETURNS TABLE
AS
RETURN
SELECT orderid, custid, empid, orderdate, requireddate,
	shippeddate, shipperid, freight, shipname, shipaddress, shipcity,
	shipregion, shippostalcode, shipcountry
FROM Sales.Orders
WHERE custid = @cid;
GO

-- This particular inline TVF accepts an input parameter called `@cid`, representing a customer ID, & returns all orders placed by that customer. Inline TVFs are queried just like tables, using DML statements. If the function accepts input parameters,

-- they are supplied in parentheses after the function name. It's also good practice to assign an alias to the function result, even though it's not always mandatory -- this improves readability & reduces the risk of errors.



-- As an example, the following code queries the function to request all orders placed by customer 1:

SELECT orderid, custid
FROM dbo.GetCustOrders(1) AS O;



-- Like tables, inline TVFs can participate in joins. For instance, the following query joins the inline TVF (returning customer 1's orders) with the `Sales.OrderDetails` table to match each order with its order lines:

SELECT O.orderid, O.custid, OD.productid, OD.qty
FROM dbo.GetCustOrders(1) AS O
	INNER JOIN Sales.OrderDetails AS OD
		ON O.orderid = OD.orderid;



-- When you're done, run the following code for cleanup:

DROP FUNCTION IF EXISTS dbo.GetCustOrders;



