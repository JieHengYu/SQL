-----------------

-- Exercises

-----------------

-- This section provides exercises so that we can practice the subjects discussed in this lesson.

USE TSQLV6;



------------------
-- Exercise 1
------------------

-- Run the following code to create the `dbo.Customers` table in the `TSQLV6` database:

DROP TABLE IF EXISTS dbo.Customers; 

CREATE TABLE dbo.Customers (
	custid		INT				NOT NULL PRIMARY KEY,
	companyname	NVARCHAR(40)	NOT NULL,
	country		NVARCHAR(15)	NOT NULL,
	region		NVARCHAR(15)	NULL,
	city		NVARCHAR(15)	NOT NULL
);

------------------
-- Exercise 1-1
------------------

-- Insert into the `dbo.Customers` table a row with the following information:

	-- `custid`: 100

	-- `companyname`: Coho Winery

	-- `country`: USA

	-- `region`: WA

	-- `city`: Redmond

INSERT INTO dbo.Customers (custid, companyname, country, region, city)
VALUES (100, N'Coho Winery', N'USA', N'WA', N'Redmond');

SELECT * FROM dbo.Customers;

------------------
-- Exercise 1-2
------------------

-- Insert into the `dbo.Customers` table all customers from `Sales.Customers` who placed orders.

INSERT INTO dbo.Customers (custid, companyname, country, region, city)
SELECT custid, companyname, country, region, city
FROM Sales.Customers AS C
WHERE EXISTS (SELECT *
			  FROM Sales.Orders AS O
			  WHERE C.custid = O.custid);

SELECT * FROM dbo.Customers;



------------------
-- Exercise 1-3
------------------

-- Use a SELECT INTO statement to create & populate the `dbo.Orders` table with orders from the `Sales.Orders` table that were placed in years 2020 through 2022.

DROP TABLE IF EXISTS dbo.Orders;

SELECT *
INTO dbo.Orders
FROM Sales.Orders
WHERE orderdate >= '20200101' AND orderdate < '20230101';

SELECT * FROM dbo.Orders;



------------------
-- Exercise 2
------------------

-- Delete from the `dbo.Orders` table orders that were placed before August 2020. Use the output clause to return the `orderid` & `orderdate` values of the deleted orders:

DELETE FROM dbo.Orders
	OUTPUT deleted.orderid,
		   deleted.orderdate
WHERE orderdate < '20200801';



------------------
-- Exercise 3
------------------

-- Delete from the dbo.Orders table orders placed by customers from Brazil:

DELETE O
FROM dbo.Orders AS O
	INNER JOIN dbo.Customers AS C
		ON O.custid = C.custid
WHERE C.country = N'Brazil';



------------------
-- Exercise 4
------------------

-- Run the following query against `dbo.Customers`, & notice that some rows have a NULL in the region column:

SELECT * FROM dbo.Customers;

-- Update the `dbo.Customers` table, & change all NULL region values to "<None>". Use the OUTPUT clause to show the `custid`, `oldregion` & `newregion`:

UPDATE dbo.Customers
	SET region = '<None>'
OUTPUT deleted.custid,
	   deleted.region AS oldregion,
	   inserted.region AS newregion
WHERE region IS NULL;



------------------
-- Exercise 5
------------------

-- Update all orders in the `dbo.Orders` that were placed by United Kingdom customers, & set their `shipcountry`, `shipregion`, & `shipcity` values to the `country`, `region`, & `city` values of the corresponding customers:

MERGE INTO dbo.Orders AS O
USING (SELECT * FROM dbo.Customers WHERE country = N'UK') AS C
	ON O.custid = C.custid
WHEN MATCHED THEN
	UPDATE SET
		O.shipcountry = C.country,
		O.shipregion = C.region,
		O.shipcity = C.city;

SELECT *
FROM dbo.Orders
WHERE shipcountry = N'UK';



------------------
-- Exercise 6
------------------

-- Run the following code to create the tables `dbo.Orders` & `dbo.OrderDetails` & populate them with data:

DROP TABLE IF EXISTS dbo.OrderDetails, dbo.Orders;

CREATE TABLE dbo.Orders (
	orderid			INT				NOT NULL,
	custid			INT				NULL,
	empid			INT				NOT NULL,
	orderdate		DATE			NOT NULL,
	requireddate	DATE			NOT NULL,
	shippeddate		DATE			NULL,
	shipperid		INT				NOT NULL,
	freight			MONEY			NOT NULL
		CONSTRAINT DFT_Orders_freight DEFAULT(0),
	shipname		NVARCHAR(40)	NOT NULL,
	shipaddress		NVARCHAR(60)	NOT NULL,
	shipcity		NVARCHAR(15)	NOT NULL,
	shipregion		NVARCHAR(15)	NULL,
	shippostalcode	NVARCHAR(10)	NULL,
	shipcountry		NVARCHAR(15)	NOT NULL,
	CONSTRAINT PK_Orders PRIMARY KEY (orderid)
);

CREATE TABLE dbo.OrderDetails (
	orderid		INT				NOT NULL,
	productid	INT				NOT NULL,
	unitprice	MONEY			NOT NULL
		CONSTRAINT DFT_OrderDetails_unitprice DEFAULT(0),
	qty			SMALLINT		NOT NULL
		CONSTRAINT DFT_OrderDetails_qty	DEFAULT(1),
	discount	NUMERIC(4, 3)	NOT NULL
		CONSTRAINT DFT_OrderDetails_discount DEFAULT(0),
	CONSTRAINT PK_OrderDetails PRIMARY KEY (orderid, productid),
	CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY (orderid)
		REFERENCES dbo.Orders(orderid),
	CONSTRAINT CHK_discount CHECK (discount BETWEEN 0 AND 1),
	CONSTRAINT CHK_qty CHECK (qty > 0),
	CONSTRAINT CHK_unitprice CHECK (unitprice >= 0)
);
GO

INSERT INTO dbo.Orders
SELECT * FROM Sales.Orders;

INSERT INTO dbo.OrderDetails
SELECT * FROM Sales.OrderDetails;

-- Write & test the T-SQL code that is required to truncate both tables, & make sure your code runs successfully.

ALTER TABLE dbo.OrderDetails DROP CONSTRAINT FK_OrderDetails_Orders;

TRUNCATE TABLE dbo.Orders;

TRUNCATE TABLE dbo.OrderDetails;

ALTER TABLE dbo.OrderDetails ADD CONSTRAINT FK_OrderDetails_Orders
	FOREIGN KEY (orderid) REFERENCES dbo.Orders(orderid);



-- When you're finished with the exercises, run the following code for cleanup:

DROP TABLE IF EXISTS dbo.OrderDetails, dbo.Orders, dbo.Customers;