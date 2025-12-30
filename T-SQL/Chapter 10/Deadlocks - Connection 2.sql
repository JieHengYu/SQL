USE TSQLV6;

BEGIN TRAN;

UPDATE Sales.OrderDetails
	SET unitprice += 1.00
WHERE productid = 2;



SELECT productid, unitprice
FROM Production.Products
WHERE productid = 2;

COMMIT TRAN;