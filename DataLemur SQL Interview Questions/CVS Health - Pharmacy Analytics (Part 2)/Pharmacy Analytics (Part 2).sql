SELECT * FROM pharmacy_sales;

SELECT * 
FROM pharmacy_sales
WHERE total_sales - cogs < 0;

WITH unprofitable_sales
AS (
	SELECT * 
	FROM pharmacy_sales
	WHERE total_sales - cogs < 0
)
SELECT manufacturer,
	   count(drug) AS drug_count,
	   abs(sum(total_sales - cogs)) AS total_loss
FROM unprofitable_sales
GROUP BY manufacturer
ORDER BY total_loss DESC
LIMIT 3;
