CREATE TABLE server_utilization (
	server_id smallint,
	session_status varchar(5),
	status_time timestamp
);

COPY server_utilization
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/Amazon - Server Utilisation Time/server_utilization.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM server_utilization;

SELECT floor(sum(up_time_sec) / 86400) 
	   	   AS total_uptime_days
FROM (
	SELECT extract(epoch FROM s2.status_time - 
		   	   s1.status_time) AS up_time_sec
	FROM server_utilization AS s1
	LEFT JOIN server_utilization AS s2 USING (server_id)
	WHERE s1.session_status = 'start'
		AND s2.session_status = 'stop'
		AND s1.status_time < s2.status_time
	ORDER BY server_id
);
