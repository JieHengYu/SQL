SELECT county_name,
       state_name,
       pop_est_2019
FROM us_counties_pop_est_2019
WHERE pop_est_2019 >= (
    SELECT percentile_cont(0.9) WITHIN GROUP (
               ORDER BY pop_est_2019)
    FROM us_counties_pop_est_2019
)
ORDER BY pop_est_2019 DESC

CREATE TABLE us_counties_2019_top10 AS
(SELECT * FROM us_counties_pop_est_2019);

DELETE FROM us_counties_2019_top10
WHERE pop_est_2019 < (
    SELECT percentile_cont(0.9) WITHIN GROUP (
               ORDER BY pop_est_2019)
    FROM us_counties_2019_top10
);

SELECT count(*)
FROM us_counties_2019_top10;

SELECT round(calcs.average, 0) AS average,
       calcs.median,
       round(calcs.average - calcs.median, 0)
           AS median_avg_diff
FROM (
    SELECT avg(pop_est_2019) AS average,
           percentile_cont(0.5) WITHIN GROUP (
               ORDER BY pop_est_2019)::numeric
               AS median
	FROM us_counties_pop_est_2019
) AS calcs;

SELECT census.state_name AS st,
       census.pop_est_2018,
       est.establishment_count,
       round((est.establishment_count /
           census.pop_est_2018::numeric) * 1000, 1)
           AS estabs_per_thousand
FROM (SELECT st, 
			 sum(establishments) AS establishment_count
	  FROM cbp_naics_72_establishments
	  GROUP BY st
      ) AS est
JOIN (SELECT state_name,
             sum(pop_est_2018) AS pop_est_2018
      FROM us_counties_pop_est_2019
      GROUP BY state_name
      ) AS census
ON est.st = census.state_name
ORDER BY estabs_per_thousand DESC;

SELECT county_name,
       state_name AS st,
       pop_est_2019,
       (SELECT percentile_cont(0.5) WITHIN GROUP (
            ORDER BY pop_est_2019)
        FROM us_counties_pop_est_2019) AS us_median
FROM us_counties_pop_est_2019;

SELECT county_name,
       state_name AS st,
       pop_est_2019,
       pop_est_2019 - (SELECT percentile_cont(0.5)
           WITHIN GROUP (ORDER BY pop_est_2019)
           FROM us_counties_pop_est_2019)
           AS diff_from_median
FROM us_counties_pop_est_2019
WHERE (pop_est_2019 - (SELECT percentile_cont(0.5)
    WITHIN GROUP (ORDER BY pop_est_2019)
    FROM us_counties_pop_est_2019))
    BETWEEN -1000 AND 1000;

CREATE TABLE retirees (
    id int,
    first_name text,
    last_name text
);

INSERT INTO retirees
VALUES (2, 'Janet', 'King'),
       (4, 'Michael', 'Taylor');

SELECT first_name, last_name
FROM employees
WHERE emp_id IN (SELECT id FROM retirees)
ORDER BY emp_id;

SELECT first_name, last_name
FROM employees
WHERE NOT EXISTS (
    SELECT id
    FROM retirees
    WHERE id = employees.emp_id);

SELECT county_name,
       state_name,
       pop_est_2018,
       pop_est_2019,
       raw_chg,
       round(pct_chg * 100, 2) AS pct_chg
FROM us_counties_pop_est_2019,
    LATERAL (SELECT pop_est_2019 - pop_est_2018
        AS raw_chg) rc,
    LATERAL (SELECT raw_chg / pop_est_2018::numeric
        AS pct_chg) pc
ORDER BY pct_chg DESC;

ALTER TABLE teachers ADD CONSTRAINT id_key
    PRIMARY KEY (id);

CREATE TABLE teachers_lab_access (
    access_id bigint PRIMARY KEY
        GENERATED ALWAYS AS IDENTITY,
    access_time timestamp with time zone,
    lab_name text,
    teacher_id bigint REFERENCES teachers (id)
);

INSERT INTO teachers_lab_access (
    access_time, lab_name, teacher_id
)
VALUES ('2022-11-30 08:59:00-08', 'Science A', 2),
       ('2022-12-01 08:58:00-08', 'Chemistry B', 2),
       ('2022-12-21 09:01:00-08', 'Chemistry A', 2),
       ('2022-12-02 11:01:00-08', 'Science B', 6),
       ('2022-12-07 10:02:00-08', 'Science A', 6),
       ('2022-12-17 16:00:00-08', 'Science B', 6);

SELECT t.first_name, t.last_name, a.access_time,
       a.lab_name
FROM teachers AS t
LEFT JOIN LATERAL (SELECT * FROM teachers_lab_access
                   WHERE teacher_id = t.id
                   ORDER BY access_time DESC
                   LIMIT 2) AS a
ON true
ORDER BY t.id;

WITH large_counties (
    county_name, state_name, pop_est_2019
)
AS (SELECT county_name, state_name, pop_est_2019
    FROM us_counties_pop_est_2019
    WHERE pop_est_2019 >= 100000)
SELECT state_name, count(*)
FROM large_counties
GROUP BY state_name
ORDER BY count(*) DESC;

WITH counties (st, pop_est_2018) AS (
         SELECT state_name, sum(pop_est_2018)
         FROM us_counties_pop_est_2019
         GROUP BY state_name),
     establishments (st, establishment_count) AS (
         SELECT st, sum(establishments) 
		 	AS establishment_count
         FROM cbp_naics_72_establishments
         GROUP BY st)
SELECT counties.st,
       pop_est_2018,
       establishment_count,
       round((establishments.establishment_count /
           counties.pop_est_2018::numeric(10, 1)) * 
		   1000, 1)
           AS estabs_per_thousand
FROM counties JOIN establishments
ON counties.st = establishments.st
ORDER BY estabs_per_thousand DESC;

WITH us_median AS (
    SELECT percentile_cont(0.5) WITHIN GROUP (
               ORDER BY pop_est_2019)
               AS us_median_pop
    FROM us_counties_pop_est_2019)
SELECT county_name,
       state_name AS st,
       pop_est_2019,
       us_median_pop,
       pop_est_2019 - us_median_pop AS diff_from_median
FROM us_counties_pop_est_2019 CROSS JOIN us_median
WHERE (pop_est_2019 - us_median_pop)
    BETWEEN -1000 AND 1000;

CREATE EXTENSION tablefunc;

CREATE TABLE ice_cream_survey (
    response_id integer PRIMARY KEY,
    office text,
    flavor text
);

COPY ice_cream_survey
FROM '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_13/ice_cream_survey.csv'
WITH (FORMAT CSV, HEADER)

SELECT *
FROM ice_cream_survey
ORDER BY response_id
LIMIT 5;

SELECT *
FROM crosstab('SELECT office,
					  flavor,
					  count(*) 
			   FROM ice_cream_survey
			   GROUP BY office, flavor
			   ORDER BY office',
			  'SELECT flavor
			   FROM ice_cream_survey 
			   GROUP BY flavor 
			   ORDER BY flavor')
AS (office text, 
	chocolate bigint,
    strawberry bigint,
    vanilla bigint);

CREATE TABLE temperature_readings (
    station_name text,
    observation_date date,
    max_temp integer,
    min_temp integer,
    CONSTRAINT temp_key PRIMARY KEY (
        station_name, observation_date)
);

COPY temperature_readings
FROM '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_13/temperature_readings.csv'
WITH (FORMAT CSV, HEADER);

SELECT *
FROM crosstab('SELECT station_name,
                      date_part(''month'',
                          observation_date),
                      percentile_cont(0.5) WITHIN
                          GROUP (ORDER BY max_temp)
               FROM temperature_readings
               GROUP BY station_name,
                        date_part(''month'',
                            observation_date)
               ORDER BY station_name',
              'SELECT month
               FROM generate_series(1,12) month')
AS (station text,
    jan numeric(3, 0),
    feb numeric(3, 0),
    mar numeric(3, 0),
    apr numeric(3, 0),
    may numeric(3, 0),
    jun numeric(3, 0),
    jul numeric(3, 0),
    aug numeric(3, 0),
    sep numeric(3, 0),
    oct numeric(3, 0),
    nov numeric(3, 0),
    dec numeric(3, 0));

SELECT max_temp,
       CASE WHEN max_temp >= 90 THEN 'Hot'
            WHEN max_temp >= 70 AND
                max_temp < 90 THEN 'Warm'
            WHEN max_temp >= 50 AND
                max_temp < 70 THEN 'Pleasant'
            WHEN max_temp >= 30 AND
                max_temp < 50 THEN 'Cold'
            WHEN max_temp < 30 THEN 'Inhumane'
       END AS temperature_group
FROM temperature_readings
ORDER BY station_name, observation_date;

WITH temps_collapsed (
    station_name, max_temperature_group
) AS (
    SELECT station_name,
           CASE WHEN max_temp >= 90 THEN 'Hot'
                WHEN max_temp >= 70 AND
                    max_temp < 90 THEN 'Warm'
                WHEN max_temp >= 50 AND
                    max_temp < 70 THEN 'Pleasant'
                WHEN max_temp >= 30 AND
                    max_temp < 50 THEN 'Cold'
                WHEN max_temp < 30 THEN 'Inhumane'
           END AS temperature_group
    FROM temperature_readings           
)
SELECT station_name, max_temperature_group, count(*)
FROM temps_collapsed
GROUP BY station_name, max_temperature_group
ORDER BY station_name, count(*) DESC;
