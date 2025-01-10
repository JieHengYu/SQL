SELECT (earthquake #>> '{properties, place}') AS location,
	   to_timestamp((earthquake #>> '{properties, 
	   	   time}')::bigint / 1000) AT TIME ZONE 'UTC' 
		   AS time,
	   (earthquake #>> '{properties, mag}')::numeric
	   	   AS magnitude,
	   (earthquake #>> '{properties, tsunami}')::smallint
		   AS tsunami
FROM earthquakes
WHERE (earthquake #>> '{properties, tsunami}')::smallint = 1
ORDER BY magnitude DESC;

CREATE TABLE earthquakes_from_json (
    id text PRIMARY KEY,
    title text,
    type text,
    quake_date timestamp with time zone,
    mag numeric,
    place text,
    earthquake_point geography(POINT, 4326),
    url text
);

SELECT id,
	   (earthquake #>> '{properties, title}') AS title,
	   (earthquake #>> '{properties, type}') AS type,
	   to_timestamp((earthquake #>> '{properties,
	   	   time}')::bigint / 1000) AS quake_date,
	   (earthquake #>> '{properties, mag}')::numeric 
	   	   AS magnitude,
	   (earthquake #>> '{properties, place}') AS place,
	   earthquake_point,
	   (earthquake #>> '{properties, detail}') AS url
FROM earthquakes
ORDER BY id;

INSERT INTO earthquakes_from_json
SELECT id,
	   (earthquake #>> '{properties, title}') AS title,
	   (earthquake #>> '{properties, type}') AS type,
	   to_timestamp((earthquake #>> '{properties,
	   	   time}')::bigint / 1000) AS quake_date,
	   (earthquake #>> '{properties, mag}')::numeric 
	   	   AS magnitude,
	   (earthquake #>> '{properties, place}') AS place,
	   earthquake_point,
	   (earthquake #>> '{properties, detail}') AS url
FROM earthquakes
ORDER BY id;

SELECT * FROM earthquakes_from_json;

WITH tl 
AS (
	SELECT *
	FROM teachers AS t
	LEFT JOIN teachers_lab_access AS tla
		ON t.id = tla.teacher_id
	WHERE t.id = 6 AND tla.access_id != 4
	ORDER BY tla.access_time DESC
)
SELECT lab_exercise
FROM (
	SELECT id, first_name, last_name,
		   json_build_object(
		'id', id,
		'fn', first_name,
		'ln', last_name,
		'lab_access', (
			(SELECT json_agg(json_build_object(
				'lab_name', lab_name,
				'access_time', access_time
			)) AS lab_access
			FROM tl)
		)) AS lab_exercise
	FROM tl
	GROUP BY id, first_name, last_name
);
