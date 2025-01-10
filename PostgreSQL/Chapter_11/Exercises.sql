SELECT round(corr(median_hh_income,
           pct_bachelors_higher)::numeric, 3)
           AS bachelors_income_r,
       round(corr(median_hh_income,
           pct_masters_higher)::numeric, 3)
           AS masters_income_r
FROM acs_2014_2018_stats;

SELECT year, month, soybeans_export_value,
	   sum(soybeans_export_value) OVER (ORDER BY 
	   	   year, month ROWS BETWEEN 11 PRECEDING AND 
		   CURRENT ROW) AS twelve_month_sum
FROM us_exports
ORDER BY year, month;

COPY (
SELECT year, month, soybeans_export_value,
	   sum(soybeans_export_value) OVER (ORDER BY 
	   	   year, month ROWS BETWEEN 11 PRECEDING AND 
		   CURRENT ROW) AS twelve_month_sum
FROM us_exports
ORDER BY year, month
)
TO '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_11/soybean_exports.csv'
WITH (FORMAT CSV, HEADER);

SELECT stabr, city, county, libname, popu_lsa,
	   rank() OVER (ORDER BY popu_lsa DESC)
FROM pls_fy2018_libraries
WHERE popu_lsa > 250000
ORDER BY popu_lsa DESC;
