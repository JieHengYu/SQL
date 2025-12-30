----------------

-- Exercises

----------------

USE TSQLV6; -- (Connection 2)



-------------------
-- Exercise 1-1
-------------------

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;



-------------------
-- Exercise 1-2
-------------------

SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails
WHERE orderid = 10249;



-------------------
-- Exercise 2-1
-------------------

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails
WHERE orderid = 10249;



-------------------
-- Exercise 2-2
-------------------

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails
WHERE orderid = 10249;



--------------------
-- Exercise 2-3
--------------------

UPDATE Sales.OrderDetails
	SET discount += 0.05
WHERE orderid = 10249;



--------------------
-- Exercise 2-4
--------------------

INSERT INTO Sales.OrderDetails (orderid, productid, unitprice, qty, discount)
VALUES (10249, 2, 19.00, 10, 0.00);



SET TRANSACTION ISOLATION LEVEL READ COMMITTED;



--------------------
-- Exercise 2-5
--------------------

SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

BEGIN TRAN;

SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails
WHERE orderid = 10249;



SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails
WHERE orderid = 10249;



COMMIT TRAN;

SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails
WHERE orderid = 10249;




-------------------
-- Exercise 2-6
-------------------

BEGIN TRAN;

SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails
WHERE orderid = 10249;



SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails
WHERE orderid = 10249;

COMMIT TRAN;



--------------------
-- Exercise 3-3
--------------------

BEGIN TRAN;

UPDATE Production.Products
	SET unitprice += 1.00
WHERE productid = 3;



SELECT productid, unitprice
FROM Production.Products
WHERE productid = 2;

COMMIT TRAN;