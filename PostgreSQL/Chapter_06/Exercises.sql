SELECT pi() * 5 ^ 2 AS area_of_circle;

SELECT county_name, 
	   state_name, 
	   births_2019,
	   deaths_2019,
	   ROUND(CAST(births_2019 AS numeric) / 
	       CAST(deaths_2019 AS numeric), 5) AS ratio
FROM us_counties_pop_est_2019
WHERE state_name = 'New York'
ORDER BY ratio DESC;

SELECT state_name,
	   percentile_cont(0.5) WITHIN GROUP (ORDER BY 
	   	  pop_est_2019) AS median_county_pop
FROM us_counties_pop_est_2019
WHERE state_name IN ('California', 'New York')
GROUP BY state_name;
