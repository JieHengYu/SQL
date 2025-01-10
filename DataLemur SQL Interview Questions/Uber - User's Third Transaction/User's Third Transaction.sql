CREATE TABLE transactions (
	user_id smallint,
	spend numeric(5, 2),
	transaction_date timestamp
);

INSERT INTO transactions
VALUES (111, 100.50, '01/08/2022 12:00:00'),
	   (111, 55.00, '01/10/2022 12:00:00'),
	   (121, 36.00, '01/18/2022 12:00:00'),
	   (145, 24.99, '01/26/2022 12:00:00'),
	   (111, 89.60, '02/05/2022 12:00:00'),
	   (145, 45.30, '02/28/2022 12:00:00'),
	   (121, 22.20, '04/01/2022 12:00:00'),
	   (121, 67.90, '04/03/2022 12:00:00'),
	   (263, 156.00, '04/11/2022 12:00:00'),
	   (230, 78.30, '06/14/2022 12:00:00'),
	   (263, 68.12, '07/11/2022 12:00:00'),
	   (263, 100.00, '07/12/2022 12:00:00');

SELECT * FROM transactions;

SELECT user_id, spend, transaction_date
FROM (
	SELECT *,
		   dense_rank() OVER (PARTITION BY user_id 
		   	   ORDER BY transaction_date) 
			   AS transaction_num
	FROM transactions
)
WHERE transaction_num = 3;
