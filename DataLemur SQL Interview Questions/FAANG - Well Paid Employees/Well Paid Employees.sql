CREATE TABLE employee (
	employee_id smallserial,
	name text,
	salary integer,
	department_id smallint,
	manager_id smallint
);

INSERT INTO employee (
	name, salary, department_id, manager_id
)
VALUES ('Emma Thompson', 3800, 1, 6),
	   ('Daniel Rodriguez', 2230, 1, 7),
	   ('Olivia Smith', 7000, 1, 8),
	   ('Noah Johnson', 6800, 2, 9),
	   ('Sophia Martinez', 1750, 1, 11),
	   ('Liam Brown', 13000, 3, NULL),
	   ('Ava Garcia', 12500, 3, NULL),
	   ('William Davis', 6800, 2, NULL);

SELECT emp1.department_id,
       emp1.employee_id,
       emp1.name AS employee_name,
       emp1.salary AS employee_salary,
       emp2.employee_id AS manager_id,
       emp2.name AS manager_name,
       emp2.salary AS manager_salary
FROM employee AS emp1
LEFT JOIN employee AS emp2
    ON emp1.manager_id = emp2.employee_id;

SELECT emp1.employee_id,
	   emp1.name AS employee_name,
	   emp1.salary AS employee_salary,
	   emp2.name AS manager_name,
	   emp2.salary AS manager_salary
FROM employee AS emp1
LEFT JOIN employee AS emp2
	ON emp1.manager_id = emp2.employee_id
WHERE emp1.salary > emp2.salary;
