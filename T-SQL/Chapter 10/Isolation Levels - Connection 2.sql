--------------------------------------------
-- The READ UNCOMMITED Isolation Level
--------------------------------------------

USE TSQLV6; -- (Connection 2)

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT productid, unitprice
FROM Production.Products
WHERE productid = 2;



--------------------------------------------
-- The READ COMMITTED Isolation Level
--------------------------------------------

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT productid, unitprice
FROM Production.Products
WHERE productid = 2;



----------------------------------------------
-- The REPEATABLE READ Isolation Level
----------------------------------------------

UPDATE Production.Products
	SET unitprice += 1.00
WHERE productid = 2;



-------------------------------------------
-- The SERIALIZABLE Isolation Level
-------------------------------------------

INSERT INTO Production.Products (productname, supplierid, categoryid, unitprice, discontinued)
VALUES ('Product ABCDE', 1, 1, 20.00, 0);



SET TRANSACTION ISOLATION LEVEL READ COMMITTED;



--------------------------------------
-- The SNAPSHOT Isolation Level
--------------------------------------

SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

BEGIN TRAN;

SELECT productid, unitprice
FROM Production.Products
WHERE productid = 2;



SELECT productid, unitprice
FROM Production.Products
WHERE productid = 2;

COMMIT TRAN;



BEGIN TRAN;

SELECT productid, unitprice
FROM Production.Products
WHERE productid = 2;

COMMIT TRAN;



---------------------------
-- Conflict Detection
---------------------------

UPDATE Production.Products
	SET unitprice = 25.00
WHERE productid = 2;



-----------------------------------------------------
-- The READ COMMITTED SNAPSHOT Isolation Level
-----------------------------------------------------

USE TSQLV6;

BEGIN TRAN;

SELECT productid, unitprice
FROM Production.Products
WHERE productid = 2;



SELECT productid, unitprice
FROM Production.Products
WHERE productid = 2;

COMMIT TRAN;