CREATE TABLE pharmacy_sales (
	product_id smallint,
	units_sold integer,
	total_sales numeric(10, 2),
	cogs numeric(10, 2),
	manufacturer text,
	drug text
);

COPY pharmacy_sales
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/CVS Health - Pharmacy Analytics (Part 1)/pharmacy_sales.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM pharmacy_sales;

SELECT drug,
	   sum(total_sales - cogs) AS total_profit
FROM pharmacy_sales
GROUP BY drug
ORDER BY sum(total_sales - cogs) DESC
LIMIT 3;
