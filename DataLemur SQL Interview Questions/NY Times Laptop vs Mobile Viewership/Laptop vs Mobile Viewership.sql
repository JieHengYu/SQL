CREATE TABLE viewership (
	user_id smallint,
	device_type varchar(10),
	view_time timestamp
);

INSERT INTO viewership
VALUES (123, 'tablet', '01/02/2022 00:00:00'),
	   (125, 'laptop', '01/07/2022 00:00:00'),
	   (128, 'laptop', '02/09/2022 00:00:00'),
	   (129, 'phone', '02/09/2022 00:00:00'),
	   (145, 'tablet', '02/24/2022 00:00:00');

SELECT * FROM viewership;

SELECT count(*) FILTER (WHERE device_type = 'laptop')
		   AS laptop_views,
	   count(*) FILTER (WHERE device_type IN ('tablet',
	   	   'phone')) AS mobile_views
FROM viewership;
