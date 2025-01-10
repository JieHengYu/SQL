CREATE TABLE advertiser (
	user_id varchar(10),
	status varchar(10)
);

INSERT INTO advertiser
VALUES ('bing', 'NEW'),
	   ('yahoo', 'NEW'),
	   ('alibaba', 'EXISTING'),
	   ('baidu', 'EXISTING'),
	   ('target', 'CHURN'),
	   ('tesla', 'CHURN'),
	   ('morgan', 'RESURRECT'),
	   ('chase', 'RESURRECT');

SELECT * FROM advertiser;

CREATE TABLE daily_pay (
	user_id varchar(10),
	paid numeric(5, 2)
);

INSERT INTO daily_pay
VALUES ('yahoo', 45.00),
	   ('alibaba', 100.00),
	   ('target', 13.00),
	   ('morgan', 600.00),
	   ('fitdata', 25.00);

SELECT * FROM daily_pay;

SELECT *,
	   (CASE
	   	   WHEN advertiser.status IN ('NEW', 'EXISTING',
			   'RESURRECT') AND daily_pay.paid IS NOT NULL
			   THEN 'EXISTING'
		   WHEN advertiser.status = 'CHURN' AND
		   	   daily_pay.paid IS NOT NULL THEN 'RESURRECT'
	    ELSE 'CHURN'
		END) AS updated_status
FROM advertiser
LEFT JOIN daily_pay USING (user_id);
