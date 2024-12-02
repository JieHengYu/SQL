SELECT date_part('year', 
		   '2022-12-01 18:37:12 EST'::timestamptz)
           AS year,
       date_part('month', 
	   	   '2022-12-01 18:37:12 EST'::timestamptz)
           AS month,
       date_part('day', 
	   	   '2022-12-01 18:37:12 EST'::timestamptz)
           AS day,
       date_part('hour', 
	   	   '2022-12-01 18:37:12 EST'::timestamptz)
           AS hour,
       date_part('minute', 
	       '2022-12-01 18:37:12 EST'::timestamptz)
           AS minute,
       date_part('seconds', 
	       '2022-12-01 18:37:12 EST'::timestamptz)
           AS seconds,
       date_part('timezone_hour',
           '2022-12-01 18:37:12 EST'::timestamptz) 
		   AS tz,
       date_part('week', 
	       '2022-12-01 18:37:12 EST'::timestamptz)
           AS week,
       date_part('quarter', 
	       '2022-12-01 18:37:12 EST'::timestamptz)
           AS quarter,
       date_part('epoch', 
	       '2022-12-01 18:37:12 EST'::timestamptz)
           AS epoch;

SELECT make_date(2022, 2, 22);

SELECT make_time(18, 4, 30.3);

SELECT make_timestamptz(2022, 2, 22, 18, 4, 30.3,
           'Europe/Lisbon');

CREATE TABLE current_time_example (
    time_id integer GENERATED ALWAYS AS IDENTITY,
    current_timestamp_col timestamptz,
    clock_timestamp_col timestamptz
);

INSERT INTO current_time_example (
    current_timestamp_col, clock_timestamp_col
)
(SELECT current_timestamp, clock_timestamp()
 FROM generate_series(1, 1000));

SELECT *
FROM current_time_example;

SHOW timezone;

SELECT current_setting('timezone');

SELECT make_timestamptz(2022, 2, 22, 18, 4, 30.3,
           current_setting('timezone'));

SELECT * FROM pg_timezone_abbrevs ORDER BY abbrev;

SELECT * FROM pg_timezone_names ORDER BY name;

SELECT * FROM pg_timezone_names
WHERE name LIKE 'Europe%'
ORDER BY name;

SET TIME ZONE 'US/Eastern';

CREATE TABLE time_zone_test (
    test_date timestamptz
);

INSERT INTO time_zone_test
VALUES ('2023-01-01 4:00');

SELECT test_date
FROM time_zone_test;

SET TIME ZONE 'US/Pacific';

SELECT test_date
FROM time_zone_test;

SELECT test_date AT TIME ZONE 'Asia/Seoul'
FROM time_zone_test;

CREATE TABLE nyc_yellow_taxi_trips (
    trip_id bigint GENERATED ALWAYS AS IDENTITY 
		PRIMARY KEY,
    vendor_id text NOT NULL,
    tpep_pickup_datetime timestamptz NOT NULL,
    tpep_dropoff_datetime timestamptz NOT NULL,
    passenger_count integer NOT NULL,
    trip_distance numeric(8,2) NOT NULL,
    pickup_longitude numeric(18,15) NOT NULL,
    pickup_latitude numeric(18,15) NOT NULL,
    rate_code_id text NOT NULL,
    store_and_fwd_flag text NOT NULL,
    dropoff_longitude numeric(18,15) NOT NULL,
    dropoff_latitude numeric(18,15) NOT NULL,
    payment_type text NOT NULL,
    fare_amount numeric(9,2) NOT NULL,
    extra numeric(9,2) NOT NULL,
    mta_tax numeric(5,2) NOT NULL,
    tip_amount numeric(9,2) NOT NULL,
    tolls_amount numeric(9,2) NOT NULL,
    improvement_surcharge numeric(9,2) NOT NULL,
    total_amount numeric(9,2) NOT NULL
);

COPY nyc_yellow_taxi_trips (
    vendor_id,
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    passenger_count,
    trip_distance,
    pickup_longitude,
    pickup_latitude,
    rate_code_id,
    store_and_fwd_flag,
    dropoff_longitude,
    dropoff_latitude,
    payment_type,
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    improvement_surcharge,
    total_amount
)
FROM '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_12/nyc_yellow_taxi_trips.csv'
WITH (FORMAT CSV, HEADER);

CREATE INDEX tpep_pickup_idx
ON nyc_yellow_taxi_trips (tpep_pickup_datetime);

SELECT count(*) FROM nyc_yellow_taxi_trips;

SET TIME ZONE 'US/Eastern';

SELECT date_part('hour', tpep_pickup_datetime)
           AS trip_hour,
       count(*)
FROM nyc_yellow_taxi_trips
GROUP BY trip_hour
ORDER BY trip_hour;

COPY (SELECT date_part('hour',
          	 	 tpep_pickup_datetime) AS trip_hour,
		  	 count(*)
      FROM nyc_yellow_taxi_trips
      GROUP BY trip_hour
      ORDER BY trip_hour)
TO '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_12/hourly_taxi_pickups.csv'
WITH (FORMAT CSV, HEADER);

SELECT date_part('hour',
           tpep_pickup_datetime) AS trip_hour,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY
           tpep_dropoff_datetime - tpep_pickup_datetime)
           AS median_trip
FROM nyc_yellow_taxi_trips
GROUP BY trip_hour
ORDER BY trip_hour;

CREATE TABLE train_rides (
    trip_id bigint GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,
    segment text NOT NULL,
    departure timestamptz NOT NULL,
    arrival timestamptz NOT NULL
);

INSERT INTO train_rides (segment, departure, arrival)
VALUES ('Chicago to New Yok', '2020-11-13 21:30 CST',
        '2020-11-14 18:23 EST'),
       ('New York to New Orleans', '2020-11-15 14:15 EST',
        '2020-11-16 19:32 CST'),
       ('New Orleans to Los Angeles', '2020-11-17 13:45 CST',
        '2020-11-18 9:00 PST'),
       ('Los Angeles to San Francisco', '2020-11-19 10:10 PST',
        '2020-11-19 21:24 PST'),
       ('San Francisco to Denver', '2020-11-20 9:10 PST',
        '2020-11-21 18:38 MST'),
       ('Denver to Chicago', '2020-11-22 19:10 MST',
        '2020-11-23 14:50 CST');

SET TIME ZONE 'US/Central';

SELECT * FROM train_rides;

SELECT segment,
       to_char(departure, 'YYYY-MM-DD HH12:MI a.m. TZ')
           AS departure,
       arrival - departure AS segment_duration
FROM train_rides;

SELECT segment,
       arrival - departure AS segment_duration,
       sum(arrival - departure) OVER (ORDER BY
           trip_id) AS cumul_duration
FROM train_rides;

SELECT segment,
       arrival - departure AS segment_duration,
       justify_interval(sum(arrival - departure)
           OVER (ORDER BY trip_id)) AS cumul_duration
FROM train_rides;
