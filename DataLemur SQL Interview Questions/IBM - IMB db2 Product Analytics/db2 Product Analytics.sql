CREATE TABLE queries (
	employee_id smallint,
	query_id integer,
	query_starttime timestamp,
	execution_time smallint
);

COPY queries
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/IBM - IMB db2 Product Analytics/queries.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM queries;

CREATE TABLE employees (
	employee_id smallserial,
	full_name text,
	gender varchar(10)
);

COPY employees
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/IBM - IMB db2 Product Analytics/employees.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM employees;

WITH emp_unique_queries
AS (
	WITH emp_queries_q3_2023
	AS (
		SELECT employees.employee_id,
			   queries.query_id
		FROM queries
		FULL OUTER JOIN employees
			ON queries.employee_id = employees.employee_id
		WHERE query_id IS NULL
			OR (date_part('year', 
				queries.query_starttime) = 2023
				AND date_part('month', 
				queries.query_starttime) IN (7, 8, 9))
	)
	SELECT employee_id,
		   count(DISTINCT query_id) AS unique_queries
	FROM emp_queries_q3_2023
	GROUP BY employee_id
	)
SELECT unique_queries,
	   count(employee_id) AS employee_count
FROM emp_unique_queries
GROUP BY unique_queries
ORDER BY unique_queries;
