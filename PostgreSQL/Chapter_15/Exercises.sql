WITH county_areas 
AS (
	SELECT pop.state_name,
		   pop.county_name,
		   (ST_Area(shp.geom::geography) / 
		   	   2589988.110336)::numeric AS sq_mile_area
	FROM us_counties_2019_shp AS shp
	JOIN us_counties_pop_est_2019 AS pop
		ON shp.statefp = pop.state_fips 
			AND shp.countyfp = pop.county_fips
	ORDER BY sq_mile_area DESC
	)
SELECT state_name,
	   round(sum(sq_mile_area), 2) AS total_sq_mile_area
FROM county_areas
GROUP BY state_name
HAVING sum(sq_mile_area) > (
	SELECT sq_mile_area 
	FROM county_areas
	WHERE county_name = 'Yukon-Koyukuk Census Area'
)
ORDER BY total_sq_mile_area DESC;

SELECT market_name, geog_point
FROM farmers_markets
WHERE market_name = 'The Oakleaf Greenmarket';

SELECT market_name, geog_point
FROM farmers_markets
WHERE market_name = 'Columbia Farmers Market';

SELECT round((ST_Distance(
	(SELECT geog_point
	FROM farmers_markets
	WHERE market_name = 'The Oakleaf Greenmarket'),
	(SELECT geog_point
	FROM farmers_markets
	WHERE market_name = 'Columbia Farmers Market')
) / 1609.344)::numeric, 2) AS distance_miles;

SELECT market_name, county
FROM farmers_markets
WHERE county IS NULL;

SELECT fm.market_name, fm.county, c.name	   
FROM farmers_markets AS fm
JOIN us_counties_2019_shp AS c
	ON ST_Intersects(fm.geog_point, 
		ST_SetSRID(c.geom, 4326))
WHERE fm.county IS NULL;

SELECT count(*)
FROM nyc_yellow_taxi_trips;

SELECT pop.state_name, 
	   pop.county_name,
	   ST_AsText(ST_MakePoint(taxi.dropoff_longitude, 
	   taxi.dropoff_latitude)) AS dropoff_point
FROM nyc_yellow_taxi_trips AS taxi
JOIN us_counties_2019_shp AS c
	ON ST_Intersects(ST_SetSRID(ST_MakePoint(
		dropoff_longitude, dropoff_latitude), 4269), 
		c.geom)
JOIN us_counties_pop_est_2019 AS pop
	ON c.statefp = pop.state_fips
		AND c.countyfp = pop.county_fips;

WITH dropoff_locations
AS (
	SELECT pop.state_name, 
		   pop.county_name,
		   ST_AsText(ST_MakePoint(taxi.dropoff_longitude, 
		   taxi.dropoff_latitude)) AS dropoff_point
	FROM nyc_yellow_taxi_trips AS taxi
	JOIN us_counties_2019_shp AS c
		ON ST_Intersects(ST_SetSRID(ST_MakePoint(
			dropoff_longitude, dropoff_latitude), 4269), 
			c.geom)
	JOIN us_counties_pop_est_2019 AS pop
		ON c.statefp = pop.state_fips
			AND c.countyfp = pop.county_fips
)
SELECT state_name, county_name,
	   count(*)
FROM dropoff_locations
GROUP BY state_name, county_name
ORDER BY count(*) DESC;
