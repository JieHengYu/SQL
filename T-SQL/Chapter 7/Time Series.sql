-------------------

-- Time Series

-------------------

-- Time series data represents a sequence of events or measurements taken over time, often at regular intervals. Examples include temperature & humidity readings collected every four hours by sensors at various locations, or daily sales quantities & values

-- recorded per salesperson.



-- Analysing time series data typically involves organising the data into time-based groups (buckets) & then aggregating measures within each bucket. For example, we might group sensor readings into 12-hour intervals per sensor & compute the minimum,

-- maximum, & average temperature for each interval. 



-- Sometimes, this type of analysis is straightforward. For instance, to compute daily extremes & averages per sensor, we can simply group the data by sensor & reading date, then apply the appropriate aggregate functions.



-- However, more complex cases require additional logic. Suppose we want to analyse the data in 12-hour buckets starting at 12:05 AM & 12:05 PM each day. What exactly should we group by in that case? Or what if sensors occasionally go offline, & we need to

-- include buckets with no activity in our results -- essentially filling gaps in the time series?



-- In this section, we'll explore techniques for handling these more sophisticated scenarios:

	-- 1. Bucketising the data using the built-in DATE_BUCKET function.

	-- 2. Creating custom bucket logic for platforms that don't support DATE_BUCKET.

	-- 3. Filling gaps in the time series using either the system-supplied GENERATE_SERIES function or the `dbo.GetNums` user-defined function, which is included in the sample databae `TSQLV6`.



-------------------
-- Sample Data
-------------------

-- We'll use sensor temperature & humidity readings as our sample data for time series analysis. The data is stored in two tables:

	-- `dbo.Sensors`: stores information about each sensor.

	-- `dbo.SensorMeasurements`: stores the actual sensor readings.

-- Run the following script to create & populate these tables with fictitious sample data:

USE TSQLV6;

DROP TABLE IF EXISTS dbo.SensorMeasurements, dbo.Sensors;

CREATE TABLE dbo.Sensors (
	sensorid	INT			NOT NULL
		CONSTRAINT PK_Sensors PRIMARY KEY,
	description	VARCHAR(50)	NOT NULL
);

INSERT INTO dbo.Sensors(sensorid, description)
VALUES 
	(1, 'Restaurant Fancy Schmancy beer fridge'),
	(2, 'Restaurant Fancy Schmancy wine cellar');

CREATE TABLE dbo.SensorMeasurements (
	sensorid	INT				NOT NULL
		CONSTRAINT FK_SensorMeasurements_Sensors REFERENCES dbo.Sensors,
	ts			DATETIME2(0)	NOT NULL,
	temperature NUMERIC(5, 2)	NOT NULL, -- Fahrenheit
	humidity	NUMERIC(5, 2)	NOT NULL, -- percent
		CONSTRAINT PK_SensorMeasurements PRIMARY KEY(sensorid, ts)
);

INSERT INTO dbo.SensorMeasurements(sensorid, ts, temperature, humidity)
VALUES
	(1, '20220609 06:00:03', 39.16, 86.28),
	(1, '20220609 09:59:57', 39.72, 83.44),
	(1, '20220609 13:59:59', 38.93, 84.33),
	(1, '20220609 18:00:00', 39.42, 79.66),
	(1, '20220609 22:00:01', 40.08, 94.44),
	(1, '20220610 01:59:57', 41.26, 90.42),
	(1, '20220610 05:59:59', 40.89, 72.94),
	(1, '20220610 09:59:58', 40.03, 84.48),
	(1, '20220610 14:00:03', 41.23, 93.47),
	(1, '20220610 17:59:59', 39.32, 88.09),
	(1, '20220610 21:59:57', 41.19, 92.89),
	(1, '20220611 01:59:58', 40.88, 89.23),
	(1, '20220611 06:00:03', 41.14, 82.27),
	(1, '20220611 10:00:00', 39.20, 86.00),
	(1, '20220611 14:00:02', 39.41, 74.92),
	(1, '20220611 18:00:02', 41.12, 87.37),
	(1, '20220611 21:59:59', 40.67, 84.63),
	(1, '20220612 02:00:02', 41.15, 86.16),
	(1, '20220612 06:00:02', 39.23, 74.59),
	(1, '20220612 10:00:00', 41.40, 86.80),
	(1, '20220612 14:00:00', 41.20, 79.97),
	(1, '20220612 18:00:03', 40.11, 92.84),
	(1, '20220612 22:00:03', 40.87, 94.23),
	(1, '20220613 02:00:00', 39.03, 92.44),
	(1, '20220613 05:59:57', 40.19, 94.72),
	(1, '20220613 10:00:02', 39.55, 87.77),
	(1, '20220613 14:00:02', 38.94, 89.06),
	(1, '20220613 18:00:03', 40.88, 73.81),
	(1, '20220613 21:59:57', 41.24, 86.56),
	(1, '20220614 02:00:00', 40.25, 76.64),
	(1, '20220614 06:00:01', 40.73, 90.66),
	(1, '20220614 10:00:03', 40.82, 92.76),
	(1, '20220614 13:59:58', 39.70, 73.74),
	(1, '20220614 17:59:57', 39.65, 89.38),
	(1, '20220614 22:00:02', 39.47, 73.36),
	(1, '20220615 02:00:03', 39.14, 77.89),
	(1, '20220615 06:00:00', 40.82, 86.84),
	(1, '20220615 09:59:57', 39.91, 90.09),
	(1, '20220615 13:59:57', 41.34, 82.88),
	(1, '20220615 18:00:01', 40.51, 86.58),
	(1, '20220615 22:00:00', 41.23, 83.85),
	(2, '20220609 06:00:01', 54.95, 75.39),
	(2, '20220609 10:00:03', 56.94, 71.34),
	(2, '20220609 13:59:59', 54.07, 68.09),
	(2, '20220609 18:00:02', 54.05, 65.50),
	(2, '20220609 22:00:00', 53.37, 66.28),
	(2, '20220610 01:59:58', 56.33, 79.90),
	(2, '20220610 05:59:58', 57.00, 65.88),
	(2, '20220610 10:00:02', 54.64, 61.10),
	(2, '20220610 14:00:01', 53.48, 69.76),
	(2, '20220610 17:59:57', 55.15, 65.85),
	(2, '20220610 22:00:02', 54.48, 75.90),
	(2, '20220611 02:00:00', 54.55, 62.28),
	(2, '20220611 06:00:01', 54.56, 66.36),
	(2, '20220611 09:59:58', 55.92, 77.53),
	(2, '20220611 14:00:02', 55.89, 68.57),
	(2, '20220611 18:00:01', 54.82, 62.04),
	(2, '20220611 22:00:01', 55.58, 76.20),
	(2, '20220613 01:59:58', 56.29, 62.33),
	(2, '20220615 10:00:03', 53.24, 70.67),
	(2, '20220615 13:59:59', 55.93, 77.60),
	(2, '20220615 18:00:01', 54.05, 66.56),
	(2, '20220615 21:59:58', 54.66, 61.13);

-- We can verify the data by running the following queries:

SELECT * FROM dbo.Sensors;

SELECT * FROM dbo.SensorMeasurements;

-- As you can see, the sensor record readings roughly every four hours. Notice also that Sensor 2 was offline for several periods between June 12 & June 15, 2022 -- during those times, no readings were recorded.



---------------------------------
-- The DATE_BUCKET Function
---------------------------------

-- The purpose of the DATE_BUCKET function is to return the starting point of the time bucket that contains a given timestamp. It might seem odd that the function is named DATE_BUCKET rather than TIME_BUCKET, but that ship has sailed. The function's result 

-- can be used as an identifier for the containing bucket, making it especially useful as a grouping element in time series queries.

	-- Syntax: `DATE_BUCKET(datepart, bucketwidth, ts[, origin])`



-- To understand what the function does, imagine the flow of time divided into a series of equally sized buckets. Each bucket has a starting point, defined by the optional `origin` argument.

	-- `origin`: defines where the first bucket starts. This can be any date or datetime value. If omitted, it defaults to `'19000101 00:00:00.000'`.

	-- `datepart`: specifies the unit of time to use (e.g., `year`, `month`, `day`, `hour`, `minute`, `second`, etc.).

	-- `bucketwidth`: determines the size of each bucket in terms of chosen `datepart`. For example, using `hour` as the `datepart` & `12` as `bucketwidth` defines 12-hour buckets.

	-- `ts`: the input timestamp for which the function returns the start time of the containing bucket. This should be of the same type as `origin`.

-- The function returns a value of the same type as the `ts` input.



-- Before using DATE_BUCKET in queries against `dbo.SensorMeasurements`, let's consider a simple example with local variables:

DECLARE
	@ts AS DATETIME2(0) = '20220102 12:00:03',
	@bucketwidth AS INT = 12,
	@origin AS DATETIME2(0) = '20220101 00:05:00';

SELECT DATE_BUCKET(hour, @bucketwidth, @ts, @origin);

-- Here, we define 12-hour buckets beginning at 2022-01-01 00:05:00, & we want to find the start of the bucket containing the timestamp 2022-01-02 12:00:03. The first four 12-hour buckets starting from the origin are:

	-- 1. 2022-01-01 00:05:00
	
	-- 2. 2022-01-01 12:05:00

	-- 3. 2022-01-02 00:05:00

	-- 4. 2022-01-02 12:05:00

-- Since 2022-01-02 12:00:03 falls within the third bucket, the function returns 2022-01-02 00:05:00 -- the start time of that bucket.



----------------------------------------------
-- Applying Bucket Logic to Sample Data
----------------------------------------------

-- In real-world scenarios, we often need to bucketise time series data stored in a table -- for example, in the `dbo.SensorMeasurements` table. Suppose we need to query this table &, for each reading, compute the start of the 12-hour time bucket that

-- contains it. To do this, we can define 12-hour buckets starting at midnight & use midnight of any date as the origin. The DATE_BUCKET function makes this task straightforward:

DECLARE
	@bucketwidth AS INT = 12,
	@origin AS DATETIME2(0) = '19000101 00:00:00';

SELECT sensorid, ts,
	DATE_BUCKET(hour, @bucketwidth, ts, @origin) AS bucketstart
FROM dbo.SensorMeasurements;

-- The base date at midnight (`'19000101 00:00:00'`) is actually the default value for the `origin` argument, so in this example, we could omit it safely. Note that the timestamp input to the function comes from the table column `ts`.



-- In most cases, time series analysis doesn't end with just computing the start of each bucket. Typically, we want to group the data by bucket & then compute aggregates such as the minimum, maximum, or average temperature per bucket. To organise this, we

-- can define a common table expression (CTE) that first computes the `bucketstart` column. The outer query can then group the results by `sensorid` & `bucketstart`, returning the bucket start & the desired aggregates per group. We can also compute the

-- exclusive end of each bucket by adding `@bucketwidth` hours to the start of the bucket. Here's how this looks in code:

DECLARE
	@bucketwidth AS INT = 12,
	@origin AS DATETIME2(0) = '19000101 00:00:00';

WITH C AS (
	SELECT sensorid, ts, temperature,
		DATE_BUCKET(hour, @bucketwidth, ts, @origin) AS bucketstart
	FROM dbo.SensorMeasurements
)
SELECT sensorid, bucketstart,
	DATEADD(hour, @bucketwidth, bucketstart) AS bucketend,
	MIN(temperature) AS mintemp,
	MAX(temperature) AS maxtemp,
	AVG(temperature) AS avgtemp
FROM C
GROUP BY sensorid, bucketstart
ORDER BY sensorid, bucketstart;

-- This approach provides a clear, modular way to compute & analyse time-based buckets, making it easy to extend our analysis or adjust the bucket width as needed.



-- As another example, suppose we want to aggregate temperatures into 7-day buckets, with Monday as the start of the week. To accomplish this, we can choose any date that falls on a Monday as the origin point. Conveniently, January 1, 1900 was a Monday,

-- so we'll use that as our origin. We'll also use the `day` date part in all DATE_BUCKET & DATE_ADD computations, & specify a bucket width of 7. Here's the complete solution:

DECLARE
	@bucketwidth AS int = 7,
	@origin AS DATETIME2(0) = '19000101 00:00:00';

WITH C AS (
	SELECT sensorid, ts, temperature,
		DATE_BUCKET(day, @bucketwidth, ts, @origin) AS bucketstart
	FROM dbo.SensorMeasurements
)
SELECT sensorid, bucketstart,
	DATEADD(day, @bucketwidth, bucketstart) AS bucketend,
	MIN(temperature) AS mintemp,
	MAX(temperature) AS maxtemp,
	AVG(temperature) AS avgtemp
FROM C
GROUP BY sensorid, bucketstart
ORDER BY sensorid, bucketstart;

-- Alternatively, instead of defining a 7-day bucket using the `day` date part, we can simply use 1 week as the bucket width & switch date part to `week`. Here's how that looks:

DECLARE
	@bucketwidth AS int = 1,
	@origin AS DATETIME2(0) = '19000101 00:00:00';

WITH C AS (
	SELECT sensorid, ts, temperature,
		DATE_BUCKET(week, @bucketwidth, ts, @origin) AS bucketstart
	FROM dbo.SensorMeasurements
)
SELECT sensorid, bucketstart,
	DATEADD(week, @bucketwidth, bucketstart) AS bucketend,
	MIN(temperature) AS mintemp,
	MAX(temperature) AS maxtemp,
	AVG(temperature) AS avgtemp
FROM C
GROUP BY sensorid, bucketstart
ORDER BY sensorid, bucketstart;



-- Feel free to experiment with different origins, date parts, & bucket widths to see how these choices affect the results. Adjusting these parameters lets us control how time series data is grouped & aggregated -- whether by hours, days, weeks, or any 

-- other logical interval



-------------------
-- Gap Filling
-------------------

-- A common challenge in time-series analysis is handling missing buckets -- periods for which there are no recorded data points, yet we still want those intervals represented in the results. This happens when the source data doesn't contain any

-- measurements for certain intervals. 



-- For example, suppose we want to analyse temperature data for the week of June 9-15, 2022, grouped into 12-hour buckets starting at midnight. Our goal is to compute the minimum, maximum, & average temperature per sensor & bucket for this period.

-- However, in our sample data, sensor 2 was offline during parts of June 12-15, 2022 -- perhaps due to a dead battery or malfunction. Because no readings exist for those intervals, the corresponding buckets are missing. We need a gap-filling method that

-- adds these missing buckets to the output. Naturally, since no data exists for them, the aggregate values (min, max, avg) for those buckets should be NULL.



-- Gap-filling typically involves creating a table that represents all possible time buckets within the desired range. In this example, that means all bucket start times for the week in question. We then perform a LEFT OUTER JOIN between this complete

-- set of buckets (the left table) & the actual aggregated data (the right table). This ensures that:

	-- Every possible bucket appears in the result (from the left table).

	-- The aggregate measure appear where data exists (from the right table).

	-- Missing buckets have NULL aggregates.



-- The table of all bucket start times can come from two sources:

	-- 1. A physical table in the database, prefilled with the relevant timestamps.

	-- 2. A table expression generated on the fly by a query.

-- If you're using SQL Server 2022 or later, you can use the GENERATE_SERIES function to produce this sequence efficiently. The GENERATE_SERIES function takes two numeric inputs -- `start` & `stop` -- & returns a result set with a single column named

-- `value`, containing all numbers in the specified range. For example, we can call it as follows:

SELECT value
FROM GENERATE_SERIES(0, 13);

-- This returns 14 rows (0 through 13), representing each 12-bucket in the week. We can then use DATEADD to convert these numeric offsets into actual timestamps:

SELECT DATEADD(HOUR, value * 12, '20220609 00:00:00.000') AS bucket_start
FROM GENERATE_SERIES(0, 13);

-- This produces all bucket start times for the period of interest -- ready to be joined with the aggregate temperature data to fill any gaps.



-- All of this logic can be easily parameterised. Suppose we receive the start & end delimiters of the period of interest as parameters named `@startperiod` & `@endperiod`. We'll also define a parameter `@bucketwidth` to control the bucket size in hours.

-- The number of buckets to generate can be computed as:

	-- `DATEDIFF(hour, @startperiod, @endperiod) / @bucketwidth`

-- Each bucket's start time can then be calculated as:

	-- `DATEADD(hour, value * @bucketwidth, @startperiod)`



-- Here's a complete query that generates all possible 12-hour bucket start times during the week of interest, using local variables to represent the parameters:

DECLARE
	@bucketwidth AS INT = 12,
	@startperiod AS DATETIME2(0) = '20220609 00:00:00',
	@endperiod AS DATETIME2(0) = '20220615 12:00:00';

SELECT DATEADD(hour, value * @bucketwidth, @startperiod) AS ts
FROM GENERATE_SERIES(0, DATEDIFF(hour, @startperiod, @endperiod) / @bucketwidth) AS N;

-- This produces a list of all bucket start times in the specified period -- one per row per 12-hour interval.



-- We can now use this logic as part of a multi-CTE (common table expression) query, with each step defined in its own CTE for clarity & modularity:

	-- 1. `TS` - Generates all possible bucket start times in the period of interest (based on the query above).

	-- 2. `C1` - Computes the bucket start time for each measurement in the `dbo.SensorMeasurements` table using the `DATE_BUCKET` function.

	-- 3. `C2` - Groups & aggregates the data from `C1` to compute the minimum, maximum, & average temperature for each existing bucket.

-- Finally, the outer query performs:

	-- a CROSS JOIN between the `dbo.Sensors` table & the `TS` CTE to create a row for every possible pair of sensor & bucket start time.

	-- a LEFT OUTER JOIN between that result & `C2`, joining on both `sensorid` & bucket start time.
		
		-- The left side contributes all sensor-bucket combinations.

		-- The right side contributes existing aggregated data.

-- This ensures that even missing buckets appear in the result, with NULL values for aggregates where no data exists.

DECLARE
	@bucketwidth AS INT = 12,
	@startperiod AS DATETIME2(0) = '20220609 00:00:00',
	@endperiod AS DATETIME2(0) = '20220615 12:00:00';

WITH TS AS (
	SELECT DATEADD(hour, value * @bucketwidth, @startperiod) AS ts
	FROM GENERATE_SERIES(0, DATEDIFF(hour, @startperiod, @endperiod) / @bucketwidth) AS N
),
C1 AS (
	SELECT sensorid, ts, temperature,
		DATE_BUCKET(hour, @bucketwidth, ts, @startperiod) AS bucketstart
	FROM dbo.SensorMeasurements
),
C2 AS (
	SELECT sensorid, bucketstart,
		MIN(temperature) AS mintemp,
		MAX(temperature) AS maxtemp,
		AVG(temperature) AS avgtemp
	FROM C1
	GROUP BY sensorid, bucketstart
)
SELECT S.sensorid, TS.ts AS bucketstart,
	DATEADD(hour, @bucketwidth, TS.ts) AS bucketend,
	mintemp, maxtemp, avgtemp
FROM dbo.Sensors AS S
	CROSS JOIN TS
	LEFT OUTER JOIN C2
		ON S.sensorid = C2.sensorid
			AND TS.ts = C2.bucketstart
ORDER BY sensorid, bucketstart;

-- This query produces one row per sensor per bucket -- filling in any missing time intervals with NULL aggregate values for `mintemp`, `maxtemp`, & `avgtemp`.

