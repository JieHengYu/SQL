-------------------

-- Merging Data

-------------------

-- T-SQL supports a statement called MERGE, which lets us merge data from a source table into a target table, applying different actions (INSERT, UPDATE, & DELETE) based on conditional logic. The MERGE statement is part of the SQL standard, though the

-- T-SQL implementation includes several nonstandard extensions.



-- A single MERGE statement can perform work that would otherwise require multiple separate DML statements (INSERT, UPDATE, & DELETE). To demonstrate how it works, we'll use the tables `dbo.Customers` & `dbo.CustomerStage`. Run the following code to create

-- populate the sample tables:

USE TSQLV6;

DROP TABLE IF EXISTS dbo.Customers, dbo.CustomersState;
GO

CREATE TABLE dbo.Customers(
	custid		INT			NOT NULL,
	companyname	VARCHAR(25)	NOT NULL,
	phone		VARCHAR(20) NOT NULL,
	address		VARCHAR(50) NOT NULL,
	CONSTRAINT PK_Customers PRIMARY KEY (custid)
);

INSERT INTO dbo.Customers(custid, companyname, phone, address)
VALUES (1, 'cust 1', '(111) 111-1111', 'address 1'),
	   (2, 'cust 2', '(222) 222-2222', 'address 2'),
	   (3, 'cust 3', '(333) 333-3333', 'address 3'),
	   (4, 'cust 4', '(444) 444-4444', 'address 4'),
	   (5, 'cust 5', '(555) 555-5555', 'address 5');

CREATE TABLE dbo.CustomersStage (
	custid		INT			NOT NULL,
	companyname	VARCHAR(25)	NOT NULL,
	phone		VARCHAR(20) NOT NULL,
	address		VARCHAR(50) NOT NULL,
	CONSTRAINT PK_CustomersStage PRIMARY KEY (custid)
);

INSERT INTO dbo.CustomersStage(custid, companyname, phone, address)
VALUES (2, 'AAAAA', '(222) 222-2222', 'address 2'),
	   (3, 'cust 3', '(333) 333-3333', 'address 3'),
	   (5, 'BBBBB', 'CCCCC', 'DDDDD'),
	   (6, 'cust 6 (new)', '(666) 666-6666', 'address 6'),
	   (7, 'cust 7 (new)', '(777) 777-7777', 'address 7');

-- Examine the data in both tables:

SELECT * FROM dbo.Customers;

SELECT * FROM dbo.CustomersStage;



-- Suppose we want to merge the contents of `dbo.CustomersStage` (the source) into `dbo.Customers` (the target), adding new customers & updating existing ones. If you're already comfortable with DELETE or UPDATE statements based on joins, MERGE will feel

-- similar -- it's also based on join semantics. We specify the target table in the MERGE clause, the source table in the USING clause, & define the match condition in the ON clause. We then define actions for matched & unmatched rows using the WHEN

-- MATCHED THEN & WHEN NOT MATCHED THEN clauses. For example:

MERGE INTO dbo.Customers AS TGT
USING dbo.CustomersStage AS SRC
	ON TGT.custid = SRC.custid
WHEN MATCHED THEN
	UPDATE SET
		TGT.companyname = SRC.companyname,
		TGT.phone = SRC.phone,
		TGT.address = SRC.address
WHEN NOT MATCHED THEN
	INSERT (custid, companyname, phone, address)
	VALUES (SRC.custid, SRC.companyname, SRC.phone, SRC.address);

-- In this statement:
	
	-- `dbo.Customers` is the target, & `dbo.CustomersStage` is the source.

	-- The join condition `TGT.custid = SRC.custid` defines which rows are considered matches.

	-- When a match is found, the target row is updated.

	-- When no match is found, a new row is inserted.

-- The statement reports that five rows were affected -- three updated (`custid` 2, 3, & 5) & two inserted (`custid` 6, & 7). Check the results:

SELECT * FROM dbo.Customers;



-- The WHEN MATCHED clause defines what happens when a source row matches a target row. The WHEN NOT MATCHED clause defines what happens when a source row has no match in the target. T-SQL also provides a third clause -- WHEN NOT MATCHED BY SOURCE -- which

-- defines what to do when a target row has no corresponding source row. For example, to delete rows from the target that no longer exist in the source:

MERGE dbo.Customers AS TGT
USING dbo.CustomersStage AS SRC
	ON TGT.custid = SRC.custid
WHEN MATCHED THEN
	UPDATE SET
		TGT.companyname = SRC.companyname,
		TGT.phone = SRC.phone, 
		TGT.address = SRC.address
WHEN NOT MATCHED THEN
	INSERT (custid, companyname, phone, address)
	VALUES (SRC.custid, SRC.companyname, SRC.phone, SRC.address)
WHEN NOT MATCHED BY SOURCE THEN
	DELETE;

-- After running this, check the results:

SELECT * FROM dbo.Customers;

-- You'll see that customers 1 & 4 have been deleted.



-- In the earlier MERGE example, the UPDATE action was applied even when the source & target rows had identical values. If we want to perform the update only when at least one column value differs, we can add a predicate to the WHEN MATCHED clause using 

-- the AND keyword:

MERGE dbo.Customers AS TGT
USING dbo.CustomersStage AS SRC
	ON TGT.custid = SRC.custid
WHEN MATCHED AND
	(TGT.companyname <> SRC.companyname
	 OR TGT.phone <> SRC.phone
	 OR TGT.address <> SRC.address) THEN
	UPDATE SET
		TGT.companyname = SRC.companyname,
		TGT.phone = SRC.phone,
		TGT.address = SRC.address
WHEN NOT MATCHED THEN
	INSERT (custid, companyname, phone, address)
	VALUES (SRC.custid, SRC.companyname, SRC.phone, SRC.address);

-- This version updates only when at least one column value is different between the source & target rows.



-- The MERGE statement is a powerful tool for expressing complex modification logic in a single, unified statement. It lets us insert, update, & delete rows in one pass, based on the relationship between source & target data sets.

