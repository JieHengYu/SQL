CREATE TABLE phone_calls (
	caller_id smallint,
	receiver_id smallint,
	call_time timestamp
);

COPY phone_calls
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/Verizon - International Call Percentage/phone_calls.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM phone_calls;

CREATE TABLE phone_info (
	caller_id smallint,
	country_id varchar(2),
	network text,
	phone_number text
);

COPY phone_info
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/Verizon - International Call Percentage/phone_info.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM phone_info;

SELECT count(*) AS total_calls,
	   count(*) FILTER (WHERE caller.country_id !=
	   	   receiver.country_id) AS intn_calls,
	   round(((count(*) FILTER (WHERE caller.country_id != 
	   	   receiver.country_id))::numeric / count(*)) * 
		   100, 1) AS intn_call_pct
FROM phone_calls AS calls
LEFT JOIN phone_info AS caller
	ON calls.caller_id = caller.caller_id
LEFT JOIN phone_info AS receiver
	ON calls.receiver_id = receiver.caller_id;
