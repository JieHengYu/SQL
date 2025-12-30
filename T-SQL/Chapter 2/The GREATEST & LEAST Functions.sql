----------------------------------------

-- The GREATEST & LEAST Functions

----------------------------------------

-- Previously, we covered grouped aggregate functions, including the MAX & MIN functions, which operate on sets of rows that are defined by the query's grouping set -- the elements that we group by. Starting with SQL Server 2022, we can 

-- apply maximum & minimum calculations across columns or across a set of expressions with the functions GREATEST & LEAST, which are the row-level alternatives to MAX & MIN, respectively.



-- These functions are straightforward & intuitive to use. The following query retrieves the orders that were placed by customer 8, & uses the GREATEST & LEAST functions to calculate, per order, the latest & earliest dates among the 

-- order's required date & shipped date:

USE TSQLV6;

SELECT orderid, requireddate, shippeddate,
	GREATEST(requireddate, shippeddate) AS latestdate,
	LEAST(requireddate, shippeddate) AS earliestdate
FROM Sales.Orders
WHERE custid = 8;

-- The GREATEST & LEAST functions are not limited to numeric arguments; in this respect, they behave like MAX & MIN. When the inputs have mixed data types, the value with the higher data-type precedence determines the result type,

-- forcing implicit conversion of the values with lower precedence.



-- These functions support between 1 & 254 input arguments. NULL inputs are ignored, but if all inputs are NULL, the result is NULL.