CREATE TABLE movies (
	movie_id smallint PRIMARY KEY,
	movie text,
	actor text
);

COPY movies
FROM '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_05/imaginary_text_file.txt'
WITH (FORMAT CSV, HEADER, DELIMITER ':', QUOTE '#');

SELECT * FROM movies;

SELECT county_name, state_name, births_2019
FROM us_counties_pop_est_2019
ORDER BY births_2019 DESC
LIMIT 20;

COPY (
    SELECT county_name, state_name, births_2019
	FROM us_counties_pop_est_2019
    ORDER BY births_2019 DESC
    LIMIT 20
)
TO '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_05/us_counties_top20_births.csv'
WITH (FORMAT CSV, HEADER);
