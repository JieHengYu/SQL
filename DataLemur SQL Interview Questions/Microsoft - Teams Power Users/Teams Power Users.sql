CREATE TABLE messages (
	message_id smallint,
	sender_id smallint,
	receiver_id smallint,
	content text,
	sent_date timestamp
);

INSERT INTO messages 
VALUES (901, 3601, 4500, 'You up?', '08/03/2022 00:00:00'),
	   (902, 4500, 3601, 'Only if you''re buying', '08/03/2022 00:00:00'),
	   (743, 3601, 8752, 'Let''s take this offline', '06/14/2022 00:00:00'),
	   (922, 3601, 4500, 'Get on the call', '08/10/2022 00:00:00');

SELECT * FROM messages;

WITH messages_aug_2022
AS (
	SELECT *
	FROM messages
	WHERE date_part('month', sent_date) = 8
		AND date_part('year', sent_date) = 2022
)
SELECT sender_id,
	   count(*) AS messages_sent
FROM messages_aug_2022
GROUP BY sender_id
ORDER BY count(*) DESC;
