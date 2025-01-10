SELECT pls18.stabr,
       sum(pls18.totstaff) AS staff_2018,
       sum(pls17.totstaff) AS staff_2017,
       sum(pls16.totstaff) AS staff_2016,
       round((sum(pls18.totstaff) -
           sum(pls17.totstaff)) / sum(pls17.totstaff) *
           100, 1) AS chg_2018_17,
       round((sum(pls17.totstaff) -
           sum(pls16.totstaff)) / sum(pls16.totstaff) *
           100, 1) AS chg_2017_16
FROM pls_fy2018_libraries AS pls18
JOIN pls_fy2017_libraries AS pls17
    ON pls18.fscskey = pls17.fscskey
JOIN pls_fy2016_libraries AS pls16
    ON pls18.fscskey = pls16.fscskey
WHERE pls18.totstaff >= 0 AND pls18.visits >= 0
    AND pls17.totstaff >= 0 AND pls17.visits >= 0
    AND pls16.totstaff >= 0 AND pls16.visits >= 0
GROUP BY pls18.stabr
ORDER BY chg_2018_17 DESC;

SELECT pls18.stabr,
       sum(pls18.totstaff) AS staff_2018,
       sum(pls17.totstaff) AS staff_2017,
       sum(pls16.totstaff) AS staff_2016,
       round((sum(pls18.totstaff) -
           sum(pls17.totstaff)) / sum(pls17.totstaff) *
           100, 1) AS chg_2018_17,
       round((sum(pls17.totstaff) -
           sum(pls16.totstaff)) / sum(pls16.totstaff) *
           100, 1) AS chg_2017_16
FROM pls_fy2018_libraries AS pls18
JOIN pls_fy2017_libraries AS pls17
    ON pls18.fscskey = pls17.fscskey
JOIN pls_fy2016_libraries AS pls16
    ON pls18.fscskey = pls16.fscskey
WHERE pls18.totstaff >= 0 AND pls18.visits >= 0
    AND pls17.totstaff >= 0 AND pls17.visits >= 0
    AND pls16.totstaff >= 0 AND pls16.visits >= 0
GROUP BY pls18.stabr
HAVING sum(pls18.visits) > 50000000
ORDER BY chg_2018_17 DESC;

CREATE TABLE obereg_definitions (
    obereg text PRIMARY KEY,
    obereg_description text
);

INSERT INTO obereg_definitions
VALUES ('01', 'New England'),
       ('02', 'Mid East'),
       ('03', 'Great Lakes'),
       ('04', 'Plains'),
       ('05', 'Southeast'),
       ('06', 'Southwest'),
       ('07', 'Rocky Mountains'),
       ('08', 'Far West'),
       ('09', 'Outlying Areas');

SELECT * FROM obereg_definitions;

SELECT pls18.obereg, 
	   obe_def.obereg_description,
	   sum(pls18.visits) AS visits_2018,
	   sum(pls17.visits) AS visits_2017,
	   sum(pls16.visits) AS visits_2016,
	   round((sum(pls18.visits::numeric) - 
	   	   sum(pls17.visits)) / sum(pls18.visits) * 100,
		   2) AS change_2018_17,
	   round((sum(pls17.visits::numeric) - 
	   	   sum(pls16.visits)) / sum(pls17.visits) * 100,
		   2) AS change_2017_16
FROM pls_fy2018_libraries AS pls18
JOIN pls_fy2017_libraries AS pls17
	ON pls18.fscskey = pls17.fscskey
JOIN pls_fy2016_libraries AS pls16
	ON pls18.fscskey = pls16.fscskey
JOIN obereg_definitions AS obe_def
	ON pls18.obereg = obe_def.obereg
WHERE pls18.visits >= 0 
	AND pls17.visits >= 0
	AND pls16.visits >= 0
GROUP BY pls18.obereg, obe_def.obereg_description
ORDER BY obereg;

SELECT pls18.stabr,
       sum(pls18.visits) AS visits_2018,
       sum(pls17.visits) AS visits_2017,
       sum(pls16.visits) AS visits_2016,
       round((sum(pls18.visits::numeric) -
           sum(pls17.visits)) / sum(pls17.visits) *
           100, 1) AS chg_2018_17,
       round((sum(pls17.visits::numeric) -
           sum(pls16.visits)) / sum(pls16.visits) *
           100, 1) AS chg_2017_16
FROM pls_fy2018_libraries AS pls18
JOIN pls_fy2017_libraries AS pls17
    ON pls18.fscskey = pls17.fscskey
JOIN pls_fy2016_libraries AS pls16
    ON pls18.fscskey = pls16.fscskey
WHERE pls18.visits >= 0
    AND pls17.visits >= 0
    AND pls16.visits >= 0
GROUP BY pls18.stabr
ORDER BY chg_2018_17 DESC;

SELECT pls18.libname AS lib2018,
	   pls17.libname AS lib2017,
	   pls16.libname AS lib2016
FROM pls_fy2018_libraries AS pls18
FULL JOIN pls_fy2017_libraries AS pls17
	ON pls18.fscskey = pls17.fscskey
FULL JOIN pls_fy2016_libraries AS pls16
	ON pls18.fscskey = pls16.fscskey
WHERE pls18.libname IS NULL
	OR pls17.libname IS NULL
	OR pls16.libname IS NULL;
