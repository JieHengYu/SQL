CREATE TABLE events (
	app_id smallint,
	event_type varchar(20),
	timestamp timestamp
);

INSERT INTO events
VALUES (123, 'impression', '07/18/2022 11:36:12'),
	   (123, 'impression', '07/18/2022 11:37:12'),
	   (123, 'click', '07/18/2022 11:37:42'),
	   (234, 'impression', '07/18/2022 14:15:12'),
	   (234, 'click', '07/18/2022 14:16:12');

SELECT * FROM events;

SELECT app_id,
	   count(*) FILTER (WHERE event_type = 'click')
	   	   AS num_clicks,
	   count(*) FILTER (WHERE event_type = 'impression')
	   	   AS num_impressions,
	   round((count(*) FILTER (WHERE event_type = 
	   	   'click'))::numeric / (count(*) FILTER (WHERE 
		   event_type = 'impression')), 2) AS ctr
FROM events
GROUP BY app_id;
