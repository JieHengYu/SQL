CREATE TABLE films (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    film jsonb NOT NULL
);

COPY films (film)
FROM '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_16/films.json';

CREATE INDEX idx_film ON films USING GIN (film);

SELECT * FROM films;

SELECT id, film -> 'title' AS title
FROM films
ORDER BY id;

SELECT id, film ->> 'title' AS title
FROM films
ORDER BY id;

SELECT id, film -> 'genre' AS genre
FROM films
ORDER BY id;

SELECT id, film -> 'genre' -> 0 AS genres
FROM films
ORDER BY id;

SELECT id, film -> 'genre' -> -1 AS genres
FROM films
ORDER BY id;

SELECT id, film -> 'genre' -> 2 AS genres
FROM films
ORDER BY id;

SELECT id, film -> 'genre' ->> 0 AS genres
FROM films
ORDER BY id;

SELECT id, film #> '{rating, MPAA}' AS mpaa_rating
FROM films
ORDER BY id;

SELECT id, film #> '{characters, 0, name}' AS name
FROM films
ORDER BY id;

SELECT id, film #>> '{characters, 0, name}' AS name
FROM films
ORDER BY id;

SELECT id, film ->> 'title' AS title,
       film @> '{"title": "The Incredibles"}'::jsonb
           AS is_incredible
FROM films
ORDER BY id;

SELECT film ->> 'title' AS title,
       film ->> 'year' AS year
FROM films
WHERE film @> '{"title": "The Incredibles"}'::jsonb;

SELECT film ->> 'title' AS title,
       film ->> 'year' AS year
FROM films
WHERE '{"title": "The Incredibles"}'::jsonb <@ film;

SELECT film ->> 'title' AS title
FROM films
WHERE film ? 'rating';

SELECT film ->> 'title' AS title,
       film ->> 'rating' AS rating,
       film ->> 'genre' AS genre
FROM films
WHERE film ?| '{rating, genre}';

SELECT film ->> 'title' AS title,
       film ->> 'rating' AS rating,
       film ->> 'genre' AS genre
FROM films
WHERE film ?& '{rating, genre}';

CREATE TABLE earthquakes (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    earthquake jsonb NOT NULL
);

COPY earthquakes (earthquake)
FROM '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_16/earthquakes.json';

CREATE INDEX idx_earthquakes ON earthquakes 
USING GIN (earthquake);

SELECT * FROM earthquakes;

SELECT id,
       earthquake #>> '{properties, time}' AS time
FROM earthquakes
ORDER BY id
LIMIT 5;

SELECT id,
       earthquake #>> '{properties, time}' AS time,
       to_timestamp((earthquake #>> '{properties,
           time}')::bigint / 1000) AS time_formatted
FROM earthquakes
ORDER BY id LIMIT 5;

SELECT min(to_timestamp((earthquake #>> '{properties,
           time}')::bigint / 1000)) AT TIME ZONE 'UTC'
           AS min_timestamp,
       max(to_timestamp((earthquake #>> '{properties,
           time}')::bigint / 1000)) AT TIME ZONE 'UTC'
           AS max_timestamp
FROM earthquakes;

SELECT earthquake #>> '{properties, place}' AS place,
       to_timestamp((earthquake #>> '{properties,
           time}')::bigint / 1000) AT TIME ZONE 'UTC'
           AS time,
       (earthquake #>> '{properties, mag}')::numeric
           AS magnitude
FROM earthquakes
ORDER BY (earthquake #>> '{properties,
             mag}')::numeric DESC NULLS LAST
LIMIT 5;

SELECT earthquake #>> '{properties, place}' AS place,
       to_timestamp((earthquake #>> '{properties,
           time}')::bigint / 1000) AT TIME ZONE 'UTC'
           AS time,
       (earthquake #>> '{properties, mag}')::numeric
           AS magnitude,
       (earthquake #>> '{properties, felt}')::integer
           AS felt
FROM earthquakes
ORDER BY (earthquake #>> '{properties,
             felt}')::integer DESC NULLS LAST
LIMIT 5;

SELECT id,
       earthquake #>> '{geometry, coordinates}'
           AS coordinates,
       earthquake #>> '{geometry, coordinates, 0}'
           AS longitude,
       earthquake #>> '{geometry, coordinates, 1}'
           AS latitude
FROM earthquakes
ORDER BY id
LIMIT 5;

SELECT ST_SetSRID(ST_MakePoint((earthquake #>>
           '{geometry, coordinates, 0}')::numeric,
           (earthquake #>> '{geometry, coordinates,
           1}')::numeric), 4326):: geography
           AS earthquake_point
FROM earthquakes
ORDER BY id;

ALTER TABLE earthquakes
ADD COLUMN earthquake_point geography(POINT, 4326);

UPDATE earthquakes
SET earthquake_point = ST_SetSRID(ST_MakePoint(
        (earthquake #>> '{geometry, coordinates,
        0}')::numeric, (earthquake #>> '{geometry,
        coordinates, 1}')::numeric), 4326)::geography;

CREATE INDEX quake_pt_idx ON earthquakes
USING GIST (earthquake_point);

SELECT earthquake #>> '{properties, place}' AS place,
       to_timestamp((earthquake -> 'properties' ->>
           'time')::bigint / 1000) AT TIME ZONE 'UTC'
           AS time,
       (earthquake #>> '{properties, mag}')::numeric
           AS magnitude,
       earthquake_point
FROM earthquakes
WHERE ST_DWithin(earthquake_point, ST_GeogFromText(
          'POINT(-95.989505 36.155007)'), 80468)
ORDER BY time;

SELECT to_json(employees) AS json_rows
FROM employees;

SELECT to_json(row(emp_id, last_name)) AS json_rows
FROM employees;

SELECT to_json(employees) AS json_rows
FROM (SELECT emp_id, last_name AS ln
      FROM employees) AS employees;

SELECT json_agg(to_json(employees)) AS json
FROM (SELECT emp_id, last_name AS ln
      FROM employees) AS employees;

UPDATE films
SET film = film || '{"studio": "Pixar"}'::jsonb
WHERE film @> '{"title": "The Incredibles"}'::jsonb;

UPDATE films
SET film = film || jsonb_build_object('studio', 'Pixar')
WHERE film @> '{"title": "The Incredibles"}'::jsonb;
	  
SELECT * FROM films;

UPDATE films
SET film = jsonb_set(film, '{genre}',
        film #> '{genre}' || '["World War II"]', true)
WHERE film @> '{"title": "Cinema Paradiso"}'::jsonb;

SELECT * FROM films;

UPDATE films
SET film = film - 'studio'
WHERE film @> '{"title": "The Incredibles"}'::jsonb;

UPDATE films
SET film = film #- '{genre, 2}'
WHERE film @> '{"title": "Cinema Paradiso"}'::jsonb;

SELECT * FROM films;

SELECT id,
       film ->> 'title' AS title,
       jsonb_array_length(film -> 'characters')
           AS num_characters
FROM films
ORDER BY id;

SELECT id,
       jsonb_array_elements(film -> 'genre')
           AS genre_jsonb,
       jsonb_array_elements_text(film -> 'genre')
           AS genre_text
FROM films
ORDER BY id;

SELECT id,
       jsonb_array_elements(film -> 'characters')
FROM films
ORDER BY id;

WITH characters (id, json)
AS (
    SELECT id,
           jsonb_array_elements(film -> 'characters')
    FROM films
)
SELECT id,
       json ->> 'name' AS name,
       json ->> 'actor' AS actor
FROM characters
ORDER BY id;
