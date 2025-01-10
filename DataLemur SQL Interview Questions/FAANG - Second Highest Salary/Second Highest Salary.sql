CREATE TABLE employee2 (
	employee_id smallserial,
	name text,
	salary smallint,
	department_id smallint,
	manager_id smallint
);

COPY employee2
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/FAANG - Second Highest Salary/employee2.csv'
WITH (FORMAT CSV, HEADER, NULL 'NULL');

SELECT * FROM employee2;

SELECT *,
	   dense_rank() OVER (ORDER BY salary DESC)
FROM employee2
ORDER BY salary DESC;

SELECT salary AS second_highest_salary
FROM (
    SELECT *,
    	   dense_rank() OVER (ORDER BY salary DESC)
    FROM employee2
    ORDER BY salary DESC
)
WHERE dense_rank = 2;
