CREATE TABLE measurements (
	measurement_id integer,
	measurement_value numeric(6, 2),
	measurement_time timestamp
);

COPY measurements
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/Google - Odd & Even Measurements/measurements.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM measurements;

WITH measurement_ranked
AS (
	SELECT date_trunc('day', measurement_time),
		   rank() OVER (PARTITION BY date_part('day', 
		   	   measurement_time) ORDER BY 
			   measurement_time), 
		   measurement_value
	FROM measurements
	ORDER BY date_part('day', measurement_time)
)
SELECT date_trunc AS day,
	   sum(CASE WHEN rank % 2 != 0 THEN measurement_value
	   	   ELSE NULL END) AS odd_sums,
	   sum(CASE WHEN rank % 2 = 0 THEN measurement_value
	   	   ELSE NULL END) AS even_sums
FROM measurement_ranked
GROUP BY date_trunc
ORDER BY date_trunc;
