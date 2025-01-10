CREATE TABLE tweets2 (
	user_id smallint,
	tweet_date timestamp,
	tweet_count smallint
);

COPY tweets2
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/Twitter - Tweets'' Rolling Averages/tweets2.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM tweets2;

SELECT user_id, tweet_date,
	   round(avg(tweet_count) OVER (ORDER BY user_id, 
	   	   tweet_date ROWS BETWEEN 2 PRECEDING AND
		   CURRENT ROW), 2) AS three_day_avg
FROM tweets2;
