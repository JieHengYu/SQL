SET TIME ZONE 'US/Eastern';

SELECT *,
       tpep_dropoff_datetime - tpep_pickup_datetime
	   	   AS ride_length
FROM nyc_yellow_taxi_trips
ORDER BY ride_length DESC;

SELECT *
FROM pg_timezone_names
WHERE name LIKE '%London%'
	OR name LIKE '%Johannesburg%'
	OR name LIKE '%Moscow%'
	OR name LIKE '%Melbourne%';

SELECT '2100-01-01 00:00:00 US/Eastern'
           AT TIME ZONE 'Europe/London'
           AS london_timezone,
       '2100-01-01 00:00:00 US/Eastern'
           AT TIME ZONE 'Europe/Moscow'
           AS moscow_timezone,
       '2100-01-01 00:00:00 US/Eastern'
           AT TIME ZONE 'Africa/Johannesburg'
           AS johannesburg_timezone,
       '2100-01-01 00:00:00 US/Eastern'
           AT TIME ZONE 'Australia/Melbourne'
           AS melboure_timezone;

SELECT corr(total_amount,
           EXTRACT(epoch FROM tpep_dropoff_datetime -
           tpep_pickup_datetime)::integer)::numeric
           AS cost_duration_r,
       regr_r2(total_amount,
           EXTRACT(epoch FROM tpep_dropoff_datetime -
           tpep_pickup_datetime)::integer)::numeric
           AS cost_duration_r2
FROM nyc_yellow_taxi_trips
WHERE tpep_dropoff_datetime - 
   		  tpep_pickup_datetime < '3 hours';

SELECT corr(total_amount, trip_distance)::numeric
           AS cost_distance_r,
       regr_r2(total_amount, trip_distance)::numeric
           AS cost_distance_r2
FROM nyc_yellow_taxi_trips
WHERE tpep_dropoff_datetime -
          tpep_pickup_datetime < '3 hours';
 