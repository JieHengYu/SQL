SELECT * FROM employee2;

CREATE TABLE salary (
	salary_id smallint,
	employee_id smallint,
	amount smallint,
	payment_date timestamp
);

COPY salary
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/FAANG - Department vs Company Salary/salary.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM salary;

WITH march_salary
AS (
	SELECT *
	FROM employee2
	LEFT JOIN salary USING (employee_id)
	WHERE to_char(payment_date, 'MM-YYYY') = '03-2024'
)
SELECT *,
	   (CASE WHEN dep_avg > comp_avg THEN 'higher'
	   	     WHEN dep_avg < comp_avg THEN 'lower'
	    ELSE 'same' END) AS comparison
FROM (
	SELECT department_id,
		   round(avg(salary), 2) AS dep_avg,
		   round((SELECT avg(salary) FROM march_salary), 2)
		   	   AS comp_avg
	FROM march_salary
	GROUP BY department_id
	ORDER BY department_id
);
