CREATE TABLE parts_assembly (
	part varchar(10),
	finish_date timestamp,
	assembly_step smallint
);

INSERT INTO parts_assembly
VALUES ('battery', '01/22/2022 00:00:00', 1),
	   ('battery', '02/22/2022 00:00:00', 2),
	   ('battery', '03/22/2022 00:00:00', 3),
	   ('bumper', '01/22/2022 00:00:00', 1),
	   ('bumper', '02/22/2022 00:00:00', 2),
	   ('bumper', NULL, 3),
	   ('bumper', NULL, 4);

SELECT * FROM parts_assembly;

SELECT *
FROM parts_assembly
WHERE finish_date IS NULL;
