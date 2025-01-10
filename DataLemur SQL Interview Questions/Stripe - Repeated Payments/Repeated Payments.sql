CREATE TABLE transactions3 (
	transaction_id smallint,
	merchant_id smallint,
	credit_card_id smallint,
	transaction_timestamp timestamp,
	amount smallint
);

COPY transactions3
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/Stripe - Repeated Payments/transactions3.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM transactions3;

SELECT count(t2.transaction_id) AS num_repeated_payments
FROM transactions3 AS t1
LEFT JOIN transactions3 AS t2 
	USING (merchant_id, credit_card_id)
WHERE t1.transaction_timestamp < t2.transaction_timestamp
	AND t2.transaction_timestamp - 
		t1.transaction_timestamp < '10 minutes'::interval;
