CREATE TABLE trades (
	order_id integer,
	user_id smallint,
	quantity smallint,
	status varchar(10),
	date timestamp,
	price numeric(5, 2)
);

INSERT INTO trades
VALUES (100101, 111, 10, 'Cancelled', '08/17/2022 12:00:00', 9.80),
	   (100102, 111, 10, 'Completed', '08/17/2022 12:00:00', 10.00),
	   (100259, 148, 35, 'Completed', '08/25/2022 12:00:00', 5.10),
	   (100264, 148, 40, 'Completed', '08/26/2022 12:00:00', 4.80),
	   (100305, 300, 15, 'Completed', '09/05/2022 12:00:00', 10.00),
	   (100400, 178, 32, 'Completed', '09/17/2022 12:00:00', 12.00),
	   (100565, 265, 2, 'Completed', '09/27/2022 12:00:00', 8.70);

SELECT * FROM trades;

CREATE TABLE users (
	user_id smallint,
	city text,
	email text,
	signup_date timestamp
);

INSERT INTO users
VALUES (111, 'San Francisco', 'rrok10@gmail.com', '08/03/2021 12:00:00'),
	   (148, 'Boston', 'sailor9820@gmail.com', '08/20/2021 12:00:00'),
	   (178, 'San Francisco', 'harrypotterfan182@gmail.com', '01/05/2022 12:00:00'),
	   (265, 'Denver', 'shadower_@hotmail.com', '02/26/2022 12:00:00'),
	   (300, 'San Francisco', 'houstoncowboy1122@hotmail.com', '06/30/2022 12:00:00');

SELECT * FROM users;

WITH completed_trades
AS (
	SELECT trades.order_id,
		   trades.user_id,
		   trades.quantity,
		   trades.price,
		   users.city,
		   users.email
	FROM trades
	LEFT JOIN users
		ON trades.user_id = users.user_id
	WHERE trades.status = 'Completed'
)
SELECT city,
	   count(*) AS total_orders
FROM completed_trades
GROUP BY city
ORDER BY count(*) DESC;
