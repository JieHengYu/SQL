SELECT c2019.county_name,
	   c2019.state_name,
	   c2019.pop_est_2019 AS pop2019,
	   c2010.estimates_base_2010 AS pop2010,
	   c2019.pop_est_2019 - c2010.estimates_base_2010
	       AS difference,
	   round((c2019.pop_est_2019::numeric - 
	   	   c2010.estimates_base_2010) / 
		   c2010.estimates_base_2010 * 100, 1)
		   AS pct_change
FROM us_counties_pop_est_2019 AS c2019
LEFT JOIN us_counties_pop_est_2010 AS c2010
ON c2019.state_name = c2010.state_name
	AND c2019.county_name = c2010.county_name
ORDER BY pct_change;

SELECT '2019' AS year,
	   county_name,
	   state_name,
	   pop_est_2019 AS county_population
FROM us_counties_pop_est_2019
UNION
SELECT '2010' AS year,
	   county_name,
	   state_name,
	   estimates_base_2010 AS county_population
FROM us_counties_pop_est_2010 AS c2010
ORDER BY state_name, county_name, year;

SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY 
		   c2019.pop_est_2019) AS median_county_pop_2019,
	   percentile_cont(0.5) WITHIN GROUP (ORDER BY
	       c2010.estimates_base_2010)
		   AS median_county_pop_2010,
	   (percentile_cont(0.5) WITHIN GROUP (ORDER BY 
	   	   c2019.pop_est_2019) - 
		   percentile_cont(0.5) WITHIN GROUP (ORDER BY
	       c2010.estimates_base_2010)) / 
		   percentile_cont(0.5) WITHIN GROUP (ORDER BY 
		   c2019.pop_est_2019) * 100 AS pct_change 
FROM us_counties_pop_est_2019 AS c2019
LEFT JOIN us_counties_pop_est_2010 AS c2010
ON c2019.county_name = c2010.county_name
	AND c2019.state_name = c2010.state_name;











	





