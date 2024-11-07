CREATE TABLE truck_company (
	record smallint GENERATED ALWAYS AS IDENTITY,
	date text,
	last_name text,
	first_name text,
	mileage numeric(4, 1)
);

INSERT INTO truck_company (date, last_name, first_name,
						    mileage)
VALUES ('4//2021', 'Martinez', 'Erik', 378.1);

SELECT date::timestamp FROM truck_company;