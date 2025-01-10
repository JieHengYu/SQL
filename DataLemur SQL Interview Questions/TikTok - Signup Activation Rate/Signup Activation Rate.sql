CREATE TABLE emails2 (
	email_id smallint,
	user_id smallint,
	signup_date timestamp
);

INSERT INTO emails2
VALUES (125, 7771, '2022-06-14 00:00:00'),
	   (236, 6950, '2022-07-01 00:00:00'),
	   (433, 1052, '2022-07-09 00:00:00'),
	   (450, 8963, '2022-08-02 00:00:00'),
	   (555, 6633, '2022-08-09 00:00:00'),
	   (499, 2500, '2022-08-08 00:00:00');

SELECT * FROM emails2;

CREATE TABLE texts2 (
	text_id smallint,
	email_id smallint,
	signup_action text
);

INSERT INTO texts2
VALUES (6878, 125, 'Confirmed'),
	   (6994, 236, 'Confirmed'),
	   (8950, 450, 'Not Confirmed'),
	   (6920, 236, 'Not Confirmed'),
	   (8966, 450, 'Not Confirmed'),
	   (8010, 499, 'Not Confirmed');

SELECT * FROM texts2;

SELECT round((count(*) FILTER (WHERE signup_action = 
	   	   'Confirmed'))::numeric / count(*), 2)
		   AS confirm_rate
FROM emails2
FULL OUTER JOIN texts2
	ON emails2.email_id = texts2.email_id
WHERE signup_action IS NOT NULL;
