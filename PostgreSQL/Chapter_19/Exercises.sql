CREATE DATABASE dump_and_restore;

CREATE TABLE cereals (
	name text,
	mfr char(1),
	type char(1),
	calories smallint,
	protein smallint,
	fat smallint,
	sodium smallint,
	fiber numeric,
	carbo numeric,
	sugars smallint,
	potass smallint,
	vitamins smallint,
	shelf smallint,
	weight numeric,
	cups numeric,
	rating numeric
);

COPY cereals 
FROM '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_19/cereal.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM cereals;
