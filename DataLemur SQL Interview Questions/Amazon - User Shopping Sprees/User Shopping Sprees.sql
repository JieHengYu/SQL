CREATE TABLE transactions2 (
	user_id smallint,
	amount numeric(5, 2),
	transaction_date timestamp
);

COPY transactions2
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/Amazon - User Shopping Sprees/transactions2.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM transactions2;

SELECT t.user_id,
	   t.transaction_date AS day1,
	   t.amount AS day1_spent,
	   t1.transaction_date AS day2,
	   t1.amount AS day2_spent,
	   t2.transaction_date AS day3,
	   t2.amount AS day3_spent
FROM transactions2 AS t
LEFT JOIN transactions2 AS t1
	ON t.user_id = t1.user_id
LEFT JOIN transactions2 AS t2
	ON t.user_id = t2.user_id
WHERE t.transaction_date + '1 day'::interval = 
    t1.transaction_date AND t1.transaction_date +
	'1 day'::interval = t2.transaction_date;
