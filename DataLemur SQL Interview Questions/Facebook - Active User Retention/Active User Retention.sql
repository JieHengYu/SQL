CREATE TABLE user_actions (
	user_id smallint,
	event_id smallint,
	event_type varchar(10),
	event_date timestamp
);

COPY user_actions
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/Facebook - Active User Retention/user_actions.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM user_actions;

WITH jul2022_active_users
AS (
	SELECT ua1.user_id,
		   ua1.event_type AS prev_event,
		   ua1.event_date AS prev_event_date,
		   ua2.event_type AS curr_event,
		   ua2.event_date AS curr_event_date
	FROM user_actions AS ua1
	LEFT JOIN user_actions AS ua2
		ON ua1.user_id = ua2.user_id
	WHERE date_part('month', ua1.event_date) + 1 = 
		date_part('month', ua2.event_date) AND
		to_char(ua2.event_date, 'Mon-YYYY') = 'Jul-2022'
)
SELECT date_part('month', curr_event_date),
	   count(DISTINCT user_id) 
FROM jul2022_active_users
GROUP BY date_part('month', curr_event_date);
