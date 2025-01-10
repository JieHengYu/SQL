CREATE TABLE user_transactions (
	product_id smallint,
	user_id smallint,
	spend numeric(5, 2),
	transaction_date timestamp
);

COPY user_transactions
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/Walmart - Histogram of Users & Purchases/user_transactions.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM user_transactions;

SELECT recent_trans.user_id,
	   recent_trans.transaction_date,
	   count(product_id) AS purchases
FROM (
	SELECT user_id,
		   max(transaction_date) AS transaction_date
	FROM user_transactions
	GROUP BY user_id
) AS recent_trans
LEFT JOIN user_transactions AS ut
	ON recent_trans.user_id = ut.user_id
		AND recent_trans.transaction_date = 
		ut.transaction_date
GROUP BY recent_trans.user_id, 
	recent_trans.transaction_date
ORDER BY transaction_date;
