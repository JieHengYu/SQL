CREATE TABLE us_counties_pop_est_2019 (
    state_fips text,
    county_fips text,
    region smallint,
    state_name text,
    county_name text,
    area_land bigint,
    area_water bigint,
    internal_point_lat numeric(10, 7),
    internal_point_lon numeric(10, 7),
    pop_est_2018 integer,
    pop_est_2019 integer,
    births_2019 integer,
    deaths_2019 integer,
    international_migr_2019 integer,
    domestic_migr_2019 integer,
    residual_2019 integer,
    CONSTRAINT counties_2019_key 
        PRIMARY KEY (state_fips, county_fips)
);

SELECT * FROM us_counties_pop_est_2019;

COPY us_counties_pop_est_2019
FROM '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_05/us_counties_pop_est_2019.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM us_counties_pop_est_2019;

SELECT county_name, state_name, area_land
FROM us_counties_pop_est_2019
ORDER BY area_land DESC
LIMIT 3;

SELECT county_name, state_name, internal_point_lat,
	   internal_point_lon
FROM us_counties_pop_est_2019
ORDER BY internal_point_lon DESC
LIMIT 5;

CREATE TABLE supervisor_salaries (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    town text,
    county text,
    supervisor text,
    start_date date,
    salary numeric(10, 2),
    benefits numeric(10, 2)
);

COPY supervisor_salaries
FROM '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_05/supervisor_salaries.csv'
WITH (FORMAT CSV, HEADER);

COPY supervisor_salaries (town, supervisor, salary)
FROM '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_05/supervisor_salaries.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM supervisor_salaries
LIMIT 2;

DELETE FROM supervisor_salaries;

COPY supervisor_salaries (town, supervisor, salary)
FROM '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_05/supervisor_salaries.csv'
WITH (FORMAT CSV, HEADER)
WHERE town = 'New Brillig';

SELECT * FROM supervisor_salaries;

DELETE FROM supervisor_salaries;

CREATE TEMPORARY TABLE supervisor_salaries_temp 
    (LIKE supervisor_salaries INCLUDING ALL);
    
COPY supervisor_salaries_temp (town, supervisor, salary)
FROM '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_05/supervisor_salaries.csv'
WITH (FORMAT CSV, HEADER);

INSERT INTO supervisor_salaries (town, county, supervisor, salary)
SELECT town, 'Mills', supervisor, salary
FROM supervisor_salaries_temp;

DROP TABLE supervisor_salaries_temp;

SELECT * FROM supervisor_salaries
LIMIT 2;

COPY us_counties_pop_est_2019
TO '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_05/us_counties_export.txt'
WITH (FORMAT CSV, HEADER, DELIMITER '|');

COPY us_counties_pop_est_2019 (county_name, 
	internal_point_lat, internal_point_lon)
TO '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_05/us_counties_latlon_export.txt'
WITH (FORMAT CSV, HEADER, DELIMITER '|');

COPY (
    SELECT county_name, state_name
    FROM us_counties_pop_est_2019
    WHERE county_name ILIKE '%mill%'
)
TO '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_05/us_counties_mill_export.csv'
WITH (FORMAT CSV, HEADER);
