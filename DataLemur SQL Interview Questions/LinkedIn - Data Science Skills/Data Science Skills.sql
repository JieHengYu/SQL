CREATE TABLE candidates (
	candidate_id smallint,
	skill varchar(10)
);

INSERT INTO candidates
VALUES (123, 'Python'),
	   (123, 'Tableau'),
	   (123, 'PostgreSQL'),
	   (234, 'R'),
	   (234, 'PowerBI'),
	   (234, 'SQL Server'),
	   (345, 'Python'),
	   (345, 'Tableau');

SELECT * FROM candidates;

SELECT candidate_id,
	   array_agg(skill)::text AS skills
FROM candidates
GROUP BY candidate_id
HAVING array_agg(skill)::text ILIKE '%python%'
	AND array_agg(skill)::text ILIKE '%tableau%'
	AND array_agg(skill)::text ILIKE '%postgresql%'
ORDER BY candidate_id;
