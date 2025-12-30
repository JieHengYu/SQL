--------------------------------

-- Exercises

--------------------------------

-- This section provides exercises to help us familiarise ourselves with the subjects discussed in this chapter.

USE TSQLV6;



------------------------
-- Exercise 1
------------------------

-- Write a query against the `Sales.Orders` table that returns orders placed in June 2021.

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderdate >= '20210601'
	AND orderdate < '20210701';



------------------------
-- Exercise 2
------------------------

-- Write a query against the `Sales.Orders` table that returns orders placed on the day before the last day of the month:

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderdate = DATEADD(day, DATEDIFF(day, '18991231', DATEADD(month, DATEDIFF(month, '18991231', orderdate), '18991231')) - 1, '18991231');

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderdate = DATEADD(day, DATEDIFF(day, '18991231', EOMONTH(orderdate)) - 1, '18991231');



------------------------
-- Exercise 3
------------------------

-- Write a query against the `HR.Employees` table that returns employees with a last name containing the letter `'e'` twice or more.

SELECT empid, firstname, lastname
FROM HR.Employees
WHERE LEN(lastname) - LEN(REPLACE(lastname, 'e', '')) >= 2;



------------------------
-- Exercise 4
------------------------

-- Write a query against the `Sales.OrderDetails` table that returns orders with a total value (quantity * unitprice) greater than 10,000 sorted by total value, decending.

SELECT orderid, SUM(unitprice * qty) AS totalvalue 
FROM Sales.OrderDetails
GROUP BY orderid
HAVING SUM(unitprice * qty) > 10000
ORDER BY SUM(unitprice * qty) DESC;



------------------------
-- Exercise 5
------------------------

-- To check the validity of the data, write a query against the `HR.Employees` table that returns employees with a last name that starts with a lowercase English letter in the range a through z. Remember that the collation of the sample database is case 

-- insensitive (`'Latin_General_CI_CP1_AS'` if you didn't choose an explicit collation during the SQL Server installation, or `'Latin_General_CI_AS'` if you chose Windows collation, case insensitive, accent sensitive):

SELECT name, description
FROM sys.fn_helpcollations();

SELECT empid, lastname
FROM HR.Employees
WHERE lastname COLLATE Latin1_General_CS_AS LIKE N'[abcdefghijklmnopqrstuvwxyz]%';



------------------------
-- Exercise 6
------------------------

-- Explain the difference between the following two queries:

SELECT empid, COUNT(*) AS numorders -- Query 1
FROM Sales.Orders
WHERE orderdate < '20220501'
GROUP BY empid;

SELECT empid, COUNT(*) AS numorders -- Query 2
FROM Sales.Orders
GROUP BY empid
HAVING MAX(orderdate) < '20220501';

-- In query 1, we choose the table `Sales.Orders` (FROM clause) & filter to the orders where the order date is before May 1, 2022 (WHERE clause). We then group up this resulting set by the employee ids (GROUP BY) & return the employee id along with the number 

-- of orders each employee fulfilled (SELECT clause).

-- In query 2, we choose the `Sales.Orders` table again (FROM clause), but we don't initially filter it. We group this table by employee id (GROUP BY clause), & with this grouped set, filter to employees whose last order they fulfilled was before 

-- May 1, 2022 (HAVING clause). Then, from this filtered grouped result, we'll return the employee id & the number of orders each employee fulfilled (SELECT clause).



------------------------
-- Exercise 7
------------------------

-- Write a query against `Sales.Orders` table that returns the three shipped-to countrys with the highest average freight for orders placed in 2021.

SELECT TOP (3) shipcountry, AVG(freight) AS avgfreight
FROM Sales.Orders
WHERE orderdate >= '20210101'
	AND orderdate < '20220101'
GROUP BY shipcountry
ORDER BY avgfreight DESC;

SELECT shipcountry, AVG(freight) AS avgfreight
FROM Sales.Orders
WHERE orderdate >= '20210101'
	AND orderdate < '20220101'
GROUP BY shipcountry
ORDER BY avgfreight DESC
OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY;



------------------------
-- Exercise 8
------------------------

-- Write a query against the `Sales.Orders` table that calculates row numbers for orders based on order date ordering (using the order ID as the tiebreaker) for each customer separately.

SELECT custid, orderdate, orderid,
	ROW_NUMBER() OVER (PARTITION BY custid ORDER BY orderdate, orderid) AS rownum
FROM Sales.Orders
ORDER BY custid, orderdate, orderid;



------------------------
-- Exercise 9
------------------------

-- Using the `HR.Employees` table, write a SELECT statement that returns for each employee the gender based on the title of courtesy. For `'Ms.'` & `'Mrs.'`, return `'Female'`; for `'Mr.'`, return `'Male'`; & in all other cases (for example, `'Dr.'`), return 

-- `'Unknown'`.

SELECT empid, firstname, lastname, titleofcourtesy,
	CASE 
		WHEN titleofcourtesy IN ('Ms.', 'Mrs.') THEN 'Female'
		WHEN titleofcourtesy = 'Mr.' THEN 'Male'
		ELSE 'Unknown'
		END AS gender
FROM HR.Employees;



------------------------
-- Exercise 10
------------------------

-- Write a query against the `Sales.Customers` table that returns for each customer the customer ID & region. Sort the rows in the output by region, ascending, having NULLs sort last (after non-NULL values). Note that the default sort behaviour for NULLs in

-- T-SQL is to sort first (before non-NULL values).

SELECT custid, region
FROM Sales.Customers
ORDER BY CASE WHEN region IS NULL THEN 1 ELSE 0 END, region;

