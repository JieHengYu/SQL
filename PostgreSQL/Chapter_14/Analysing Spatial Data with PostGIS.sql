CREATE EXTENSION postgis

SELECT srtext
FROM spatial_ref_sys
WHERE srid = 4326;

SELECT ST_GeomFromText(
           'POINT(-74.9233606 42.699992)', 4326);

SELECT ST_GeomFromText(
           'LINESTRING(-74.9 42.7, -75.1 42.7)',
           4326);

SELECT ST_GeomFromText(
           'POLYGON((-74.8 42.7, -75.1 42.7,
            -75.1 42.6, -74.8 42.7))', 4326);

SELECT ST_GeomFromText(
           'MULTIPOINT(-74.9 42.7, -75.1 42.7)',
           4326);

SELECT ST_GeomFromText(
           'MULTILINESTRING((-76.27 43.1,
           -76.06 43.08), (-76.2 43.3, -76.2 43.3,
           -76.4, 43.1))', 4326);

SELECT ST_GeomFromText(
           'MULTIPOLYGON(((-74.92 42.7, -75.06 42.71,
           -75.07 42.64, -74.92 42.7), (-75.0 42.66,
           -75.0 42.64, -74.98 42.64, -74.98 42.66,
           -75.0 42.66)))', 4326);

SELECT ST_GeogFromText('SRID=4326;MULTIPOINT(
           -74.9 42.7, -76.1 42.7, -74.924 42.6)');

SELECT ST_PointFromText(
           'POINT(-74.9233606 42.699992)', 4326);

SELECT ST_MakePoint(-74.9233606, 42.699992);

SELECT ST_SetSRID(ST_MakePoint(
           -74.9233606, 42.699992), 4326);

SELECT ST_LineFromText('LINESTRING(-105.90 35.67,
           -105.91 35.67)', 4326);

SELECT ST_MakeLine(ST_MakePoint(-74.9, 42.7),
           ST_MakePoint(-74.1, 42.4));

SELECT ST_PolygonFromText('POLYGON((-74.9 42.7,
           -75.1 42.7, -75.1 42.6, -74.9 42.7))', 4326);

SELECT ST_MakePolygon(ST_GeomFromText('LINESTRING(
           -74.92 42.7, -75.06 42.71, -75.07 42.64,
           -74.92 42.7)', 4326));

SELECT ST_MPolyFromText('MULTIPOLYGON(((-74.92 42.7,
           -75.06 42.71, -75.07 42.64, -74.92 42.7),
           (-75.0 42.66, -75.0 42.64, -74.98 42.64,
           -74.98 42.66, -75.0 42.66)))', 4326);

CREATE TABLE farmers_markets (
    fmid bigint PRIMARY KEY,
    market_name text NOT NULL,
    street text,
    city text,
    county text,
    st text NOT NULL,
    zip text,
    longitude numeric(10, 7),
    latitude numeric(10, 7),
    organic text NOT NULL
);

COPY farmers_markets
FROM '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_15/farmers_markets.csv'
WITH (FORMAT CSV, HEADER);

SELECT count(*) FROM farmers_markets;

ALTER TABLE farmers_markets
ADD COLUMN geog_point geography (POINT, 4326);

UPDATE farmers_markets
SET geog_point = ST_SetSRID(ST_MakePoint(
        longitude, latitude)::geography, 4326);

CREATE INDEX market_pts_idx ON farmers_markets
USING GIST (geog_point);

SELECT longitude, latitude, geog_point,
       ST_AsEWKT(geog_point)
FROM farmers_markets
WHERE longitude IS NOT NULL
LIMIT 5;

SELECT market_name, city, st, geog_point
FROM farmers_markets
WHERE ST_DWithin(geog_point, ST_GeogFromText(
		  'POINT(-93.6204386 41.5853202)'), 10000)
ORDER BY market_name;

SELECT ST_Distance(ST_GeogFromText('POINT(
           -73.9283685 40.8296466)'),
           ST_GeogFromText('POINT(-73.8480153
           40.7570917)')) / 1609.344
           AS mets_to_yanks;

SELECT market_name, city,
       round((ST_Distance(geog_point, ST_GeogFromText(
       'POINT(-93.6204386 41.5853202)')) /
       1609.344)::numeric, 2) AS miles_from_dt
FROM farmers_markets
WHERE ST_DWithin(geog_point, ST_GeogFromText('POINT(
          -93.6204386 41.5853202)'), 10000)
ORDER BY miles_from_dt ASC;

SELECT market_name, city, st,
       round((ST_Distance(geog_point, ST_GeogFromText(
           'POINT(-68.2041607 44.3876414)')) /
           1609.344)::numeric, 2) AS miles_from_bh
FROM farmers_markets
ORDER BY geog_point <-> ST_GeogFromText('POINT(
             -68.2041607 44.3876414)')
LIMIT 3;

SELECT ST_AsText(geom)
FROM us_counties_2019_shp
ORDER BY gid
LIMIT 1;

SELECT name,
       statefp AS st,
       round((ST_Area(geom::geography) /
           2589988.110336)::numeric, 2)
           AS square_miles
FROM us_counties_2019_shp
ORDER BY square_miles DESC
LIMIT 5;

SELECT sh.name,
       c.state_name
FROM us_counties_2019_shp AS sh
JOIN us_counties_pop_est_2019 AS c
ON sh.statefp = c.state_fips
    AND sh.countyfp = c.county_fips
WHERE ST_Within('SRID=4269;POINT(-118.3419063
          34.0977076)'::geometry, geom);

SELECT sum(c.pop_est_2019) AS pop_est_2019
FROM us_counties_2019_shp AS sh
JOIN us_counties_pop_est_2019 AS c
ON sh.statefp = c.state_fips
    AND sh.countyfp = c.county_fips
WHERE ST_DWithin(sh.geom::geography,
    ST_GeogFromText('SRID=4269;POINT(-96.699656
    40.811567)'), 80467);

SELECT sh.name,
       c.state_name,
       c.pop_est_2019,
       ST_Transform(sh.geom, 4326) AS geom
FROM us_counties_2019_shp AS sh
JOIN us_counties_pop_est_2019 AS c
ON sh.statefp = c.state_fips
    AND sh.countyfp = c.county_fips
WHERE ST_DWithin(geom::geography, ST_GeogFromText(
          'SRID=4269;POINT(-96.699656 40.811567)'),
          80467);

SELECT * FROM santafe_linearwater_2019;

SELECT * FROM santafe_roads_2019;

SELECT ST_GeometryType(geom)
FROM santafe_linearwater_2019
LIMIT 1;

SELECT ST_GeometryType(geom)
FROM santafe_roads_2019
LIMIT 1;

SELECT water.fullname AS waterway,
       roads.rttyp,
       roads.fullname AS road
FROM santafe_linearwater_2019 AS water
JOIN santafe_roads_2019 AS roads
    ON ST_Intersects(water.geom, roads.geom)
WHERE water.fullname = 'Santa Fe Riv'
    AND roads.fullname IS NOT NULL
ORDER BY roads.fullname;

SELECT water.fullname AS waterway,
       roads.rttyp,
       roads.fullname AS road,
       ST_AsText(ST_Intersection(water.geom, roads.geom))
FROM santafe_linearwater_2019 AS water
JOIN santafe_roads_2019 AS roads
    ON ST_Intersects(water.geom, roads.geom)
WHERE water.fullname = 'Santa Fe Riv'
    AND roads.fullname IS NOT NULL
ORDER BY roads.fullname;
