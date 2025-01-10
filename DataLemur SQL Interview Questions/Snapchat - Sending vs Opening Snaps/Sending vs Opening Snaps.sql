CREATE TABLE activities (
	activity_id smallint,
	user_id smallint,
	activity_type varchar(4),
	time_spent numeric(4, 2),
	activity_date timestamp
);

COPY activities
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/Snapchat - Sending vs Opening Snaps/activities.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM activities;

CREATE TABLE age_breakdown (
	user_id smallint,
	age_bucket varchar(5)
);

INSERT INTO age_breakdown
VALUES (123, '31-35'),
	   (456, '26-30'),
	   (789, '21-25');

SELECT * FROM age_breakdown;	   

SELECT *
FROM activities
LEFT JOIN age_breakdown
	ON activities.user_id = age_breakdown.user_id;

SELECT age_bucket,
       round(sum(CASE WHEN activity_type = 'send' 
	   	   THEN time_spent ELSE NULL END) /
		   sum(CASE WHEN activity_type IN ('send', 'open')
		   THEN time_spent ELSE NULL END) * 100.0, 2)
		   AS send_pct,
	   round(sum(CASE WHEN activity_type = 'open' 
	   	   THEN time_spent ELSE NULL END) /
		   sum(CASE WHEN activity_type IN ('send', 'open')
		   THEN time_spent ELSE NULL END) * 100.0, 2)
		   AS open_pct
FROM activities
LEFT JOIN age_breakdown
	ON activities.user_id = age_breakdown.user_id
GROUP BY age_bucket
ORDER BY age_bucket;
