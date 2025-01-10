CREATE TABLE customer_contracts (
	customer_id smallint,
	product_id smallint,
	amount smallint
);

COPY customer_contracts
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/Microsoft - Supercloud Customer/customer_contracts.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM customer_contracts;

CREATE TABLE products (
	product_id smallserial,
	product_category varchar(10),
	product_name text
);

INSERT INTO products (product_category, product_name)
VALUES ('Analytics', 'Azure Databricks'),
	   ('Analytics', 'Azure Stream Analytics'),
	   ('Containers', 'Azure Kubernetes Service'),
	   ('Containers', 'Azure Service Fabric'),
	   ('Compute', 'Virtual Machines'),
	   ('Compute', 'Azure Functions');

SELECT * FROM products;

CREATE EXTENSION tablefunc;

SELECT * 
FROM crosstab(
	'SELECT cc.customer_id, 
	 	    products.product_category,
		    count(*)
	 FROM customer_contracts AS cc
	 LEFT JOIN products
	 	 ON cc.product_id = products.product_id
	 GROUP BY customer_id, product_category
	 ORDER BY customer_id',
	
	'SELECT product_category
	 FROM products
	 GROUP BY product_category
	 ORDER BY product_category'
) AS (
	customer_id smallint,
	analytics smallint,
	compute smallint,
	containers smallint
)
WHERE ROW(analytics, compute, containers) IS NOT NULL;
