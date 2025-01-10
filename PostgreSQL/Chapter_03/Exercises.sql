SELECT school, first_name, last_name 
FROM teachers
ORDER BY school, last_name;

SELECT first_name, last_name, salary
FROM teachers
WHERE first_name LIKE 'S%'
	AND salary > 40000;

SELECT * 
FROM teachers
WHERE hire_date >= '2010-01-01'
ORDER BY salary DESC;
