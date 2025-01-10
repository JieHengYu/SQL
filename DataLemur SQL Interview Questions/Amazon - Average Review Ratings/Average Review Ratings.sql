CREATE TABLE reviews (
	review_id smallint,
	user_id smallint,
	submit_date timestamp,
	product_id integer,
	stars smallint CHECK (stars IN (1, 2, 3, 4, 5))
);

INSERT INTO reviews
VALUES (6171, 123, '06/08/2022 00:00:00', 50001, 4),
	   (7802, 265, '06/10/2022 00:00:00', 69852, 4),
	   (5293, 362, '06/18/2022 00:00:00', 50001, 3),
	   (6352, 192, '07/26/2022 00:00:00', 69852, 3),
	   (4517, 981, '07/05/2022 00:00:00', 69852, 2);

SELECT * FROM reviews;

SELECT date_part('month', submit_date) AS month,
	   product_id,
	   round(avg(stars), 2) AS rating
FROM reviews
GROUP BY date_part('month', submit_date), product_id
ORDER BY month, product_id;
