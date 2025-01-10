CREATE TABLE user_transactions2 (
	transaction_id smallint,
	product_id integer,
	spend numeric(6, 2),
	transaction_date timestamp
);

COPY user_transactions2
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/Wayfair - Year Over Year Growth Rate/user_transactions2.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM user_transactions2;

WITH transact
AS (
	SELECT *,
		   lag(spend) OVER (PARTITION BY product_id 
		       ORDER BY date_part('year', 
			   transaction_date)) AS prev_spend
	FROM user_transactions2
)
SELECT date_part('year', transaction_date),
	   product_id,
	   spend,
	   prev_spend,
	   round((spend - prev_spend) / prev_spend * 100, 2)
	   	   AS yoy_growth_rate
FROM transact;

COPY (
	WITH transact
	AS (
		SELECT *,
			   lag(spend) OVER (PARTITION BY product_id 
			       ORDER BY date_part('year', 
				   transaction_date)) AS prev_spend
		FROM user_transactions2
	)
	SELECT date_part('year', transaction_date),
		   product_id,
		   spend,
		   prev_spend,
		   round((spend - prev_spend) / prev_spend * 100, 
		   	   2) AS yoy_growth_rate
	FROM transact
)
TO '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/Wayfair - Year Over Year Growth Rate/YoY Growth Rate Result.csv'
WITH (FORMAT CSV, HEADER);
