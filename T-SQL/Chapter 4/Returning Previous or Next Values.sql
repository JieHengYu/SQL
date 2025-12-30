-----------------------------------------------

-- Returning Previous or Next Values

-----------------------------------------------

-- Suppose we need to query the `Sales.Orders` table in the `TSQLV6` database & return, for each order, information about the current order & also the previous order ID. The tricky part is that the concept of "previous" implies order, & rows in a table have no

-- order. One way to achieve this objective is with a T-SQL expression that means "the maximum value that is smaller than the current value." We could use the following T-SQL expression, which is based on a correlated subquery, for this:

USE TSQLV6;

SELECT O1.orderid, O1.orderdate, O1.empid, O1.custid,
	(SELECT MAX(O2.orderid)
	 FROM Sales.Orders AS O2
	 WHERE O2.orderid < O1.orderid) AS prevorderid
FROM Sales.Orders AS O1;

-- Notice that because there's no order before the first order, the subquery returned a NULL for the first order. Similarly, we can phrase the concept of "next" as "the minimum value that is greater than the current value." Here's a query that returns for each

-- order the next order ID:

SELECT O1.orderid, O1.orderdate, O1.empid, O1.empid,
	(SELECT MIN(O2.orderid)
	 FROM Sales.Orders AS O2
	 WHERE O2.orderid > O1.orderid) AS nextorderid
FROM Sales.Orders AS O1;

-- Notice that because there's no order after the last order, the subquery returns a NULL for the last order.



-- Note that T-SQL supports window functions called LAG & LEAD that we can use to obtain elements from a previous or next row much more easily.

