CREATE TABLE emails (
	email_id smallint,
	user_id smallint,
	signup_date timestamp
);

INSERT INTO emails
VALUES (125, 7771, '06/14/2022 00:00:00'),
	   (433, 1052, '07/09/2022 00:00:00');

SELECT * FROM emails;

CREATE TABLE texts (
	text_id smallint,
	email_id smallint,
	signup_action text,
	action_date timestamp
);

INSERT INTO texts
VALUES (6878, 125, 'Confirmed', '06/14/2022 00:00:00'),
	   (6997, 433, 'Not Confirmed', '07/09/2022 00:00:00'),
	   (7000, 433, 'Confirmed', '07/10/2022 00:00:00');

SELECT * FROM texts;

SELECT *
FROM emails
LEFT JOIN texts 
	ON emails.email_id = texts.email_id
WHERE signup_date + '1 day'::interval = action_date;
