SELECT DISTINCT activities
FROM meat_poultry_egg_establishments;

CREATE TABLE meat_poultry_egg_establishments_processing
AS (SELECT *,
           False::boolean AS meat_processing,
           False::boolean AS poultry_processing
    FROM meat_poultry_egg_establishments);

DROP TABLE meat_poultry_egg_establishments_backup;

ALTER TABLE meat_poultry_egg_establishments
RENAME TO meat_poultry_egg_establishments_backup;

ALTER TABLE meat_poultry_egg_establishments_processing
RENAME TO meat_poultry_egg_establishments;

SELECT * 
FROM meat_poultry_egg_establishments;

SELECT *
FROM meat_poultry_egg_establishments_backup;

UPDATE meat_poultry_egg_establishments
SET meat_processing = True
WHERE activities LIKE '%Meat Processing%';

UPDATE meat_poultry_egg_establishments
SET poultry_processing = True
WHERE activities LIKE '%Poultry Processing%';

SELECT activities, meat_processing
FROM meat_poultry_egg_establishments
WHERE activities LIKE '%Meat Processing%';

SELECT activities, poultry_processing
FROM meat_poultry_egg_establishments
WHERE activities LIKE '%Poultry Processing%';

SELECT activities,
       meat_processing,
       poultry_processing
FROM meat_poultry_egg_establishments;

SELECT meat_processing,
       poultry_processing,
       count(*) AS num_plants
FROM meat_poultry_egg_establishments
GROUP BY meat_processing, poultry_processing;
