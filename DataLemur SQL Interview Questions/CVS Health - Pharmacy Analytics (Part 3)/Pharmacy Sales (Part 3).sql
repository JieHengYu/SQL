SELECT * FROM pharmacy_sales;

SELECT manufacturer,
	   '$' || round(sum(total_sales) / 1000000)::text  ||
	   	   ' million' AS sales
FROM pharmacy_sales
GROUP BY manufacturer
ORDER BY manufacturer;
