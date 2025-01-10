CREATE TABLE product_spend (
	category text,
	product text,
	user_id smallint,
	spend numeric(5, 2),
	transaction_date timestamp
);

COPY product_spend
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/Amazon - Highest Grossing Items/product_spend.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM product_spend;

SELECT category, product, spend
FROM (
	SELECT *,
		   dense_rank() OVER (PARTITION BY category 
		   	   ORDER BY spend DESC)
	FROM product_spend
	WHERE date_part('year', transaction_date) = 2022
	ORDER BY category, spend DESC
)
WHERE dense_rank <= 2;
