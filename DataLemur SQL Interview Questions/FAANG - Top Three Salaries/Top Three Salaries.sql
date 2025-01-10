SELECT * FROM employee2;

CREATE TABLE department (
	department_id smallserial,
	department_name text
);

INSERT INTO department (department_name)
VALUES ('Data Analytics'),
	   ('Data Science'),
	   ('Data Engineering');

SELECT * FROM department;

SELECT *,
	   rank() OVER (PARTITION BY department_id
	   	   ORDER BY salary DESC)
FROM employee2
ORDER BY department_id, salary DESC;

SELECT department.department_name,
	   dep_sal.name,
	   dep_sal.salary,
	   dep_sal.rank
FROM (
	SELECT *,
		   rank() OVER (PARTITION BY department_id
		   	   ORDER BY salary DESC)
	FROM employee2
	ORDER BY department_id, salary DESC, name
) AS dep_sal
LEFT JOIN department
	ON dep_sal.department_id = department.department_id
WHERE dep_sal.rank <= 3;
