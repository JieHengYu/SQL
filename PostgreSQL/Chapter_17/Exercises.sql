SELECT * FROM nyc_yellow_taxi_trips;

SELECT date_part('hour', tpep_pickup_datetime)::integer 
		   AS hour,
	   count(*) AS num_trips
FROM nyc_yellow_taxi_trips
GROUP BY date_part('hour', tpep_pickup_datetime)
ORDER BY date_part('hour', tpep_pickup_datetime);

CREATE MATERIALIZED VIEW nyc_taxi_trips_per_hour
AS (
    SELECT date_part('hour', tpep_pickup_datetime)::integer 
    		   AS hour,
    	   count(*) AS num_trips
    FROM nyc_yellow_taxi_trips
    GROUP BY date_part('hour', tpep_pickup_datetime)
    ORDER BY date_part('hour', tpep_pickup_datetime)
);

SELECT * FROM nyc_taxi_trips_per_hour;

REFRESH MATERIALIZED VIEW nyc_taxi_trips_per_hour;

CREATE OR REPLACE FUNCTION 
rate_per_thousand(observed_number numeric,
				  base_number numeric,
				  decimal_places smallint DEFAULT 1)
RETURNS numeric AS
'SELECT round((observed_number / base_number) * 1000,
			decimal_places);'
LANGUAGE SQL
IMMUTABLE
RETURNS NULL ON NULL INPUT;

SELECT cbp.county,
       cbp.st,
       cbp.establishments,
       pop.pop_est_2018,
       round((cbp.establishments::numeric /
           pop.pop_est_2018) * 1000, 1)
           AS estabs_per_1000
FROM cbp_naics_72_establishments AS cbp
JOIN us_counties_pop_est_2019 AS pop
    ON cbp.state_fips = pop.state_fips
        AND cbp.county_fips = pop.county_fips
WHERE pop.pop_est_2018 >= 50000
ORDER BY cbp.establishments::numeric / 
	pop.pop_est_2018 DESC;

SELECT cbp.county,
       cbp.st,
       cbp.establishments,
       pop.pop_est_2018,
       round((cbp.establishments::numeric /
           pop.pop_est_2018) * 1000, 1)
           AS estabs_per_1000,
       rate_per_thousand(cbp.establishments::numeric,
           pop.pop_est_2018) AS rate_per_thou_func
FROM cbp_naics_72_establishments AS cbp
JOIN us_counties_pop_est_2019 AS pop
    ON cbp.state_fips = pop.state_fips
        AND cbp.county_fips = pop.county_fips
WHERE pop.pop_est_2018 >= 50000
ORDER BY cbp.establishments::numeric /
    pop.pop_est_2018 DESC;

SELECT * FROM meat_poultry_egg_establishments;

CREATE OR REPLACE FUNCTION update_inspect_deadline()
RETURNS trigger AS
$$
BEGIN
    NEW.inspection_deadline := now() +
        '6 months'::interval;
	RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER estab_insert
BEFORE INSERT ON meat_poultry_egg_establishments_backup
FOR EACH ROW
EXECUTE PROCEDURE update_inspect_deadline();

SELECT * FROM meat_poultry_egg_establishments_backup;

INSERT INTO meat_poultry_egg_establishments_backup (
    establishment_number,
    company    
)
VALUES ('ABC123', 'Beat Your Meat Company'),
       ('XYZ000', 'Choke That Chicken Company'),
       ('TIT303', 'Petting Roosters Company');

SELECT *
FROM meat_poultry_egg_establishments_backup
WHERE company IN ('Beat Your Meat Company',
    'Choke That Chicken Company',
    'Petting Roosters Company');
