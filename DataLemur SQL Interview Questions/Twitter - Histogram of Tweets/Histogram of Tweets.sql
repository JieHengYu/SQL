CREATE TABLE tweets (
	tweet_id integer,
	user_id integer,
	msg text,
	tweet_date timestamp
);

INSERT INTO tweets
VALUES (214252, 111, 'Am considering taking Tesla private at $420. Funding secured.', '12/30/2021 00:00:00'),
	   (759252, 111, 'Despite the constant negative covfefe', '01/01/2022 00:00:00'),
	   (846402, 111, 'Following @NickSinghTech on Twitter changed my life!', '02/14/2022 00:00:00'),
	   (241425, 254, 'If the salary is so competitive why won''t you tell me what it is?', '03/01/2022 00:00:00'),
	   (231574, 148, 'I no longer have a manager. I can''t be managed', '03/23/2022 00:00:00');

SELECT * FROM tweets;

SELECT date_part('year', tweet_date) AS year,
	   user_id,
	   count(*) AS tweet_bucket
FROM tweets
GROUP BY user_id, date_part('year', tweet_date)
HAVING date_part('year', tweet_date) = 2022;

WITH tweets_2022 
AS (
	SELECT date_part('year', tweet_date) AS year,
		   user_id,
		   count(*) AS tweet_bucket
	FROM tweets
	GROUP BY user_id, date_part('year', tweet_date)
	HAVING date_part('year', tweet_date) = 2022
)
SELECT year, tweet_bucket,
	   count(*) AS users_num
FROM tweets_2022
GROUP BY year, tweet_bucket;
