CREATE TABLE pls_fy2018_libraries (
    stabr text NOT NULL,
    fscskey text 
		CONSTRAINT fscskey_2018_pkey PRIMARY KEY,
    libid text NOT NULL,
    libname text NOT NULL,
    address text NOT NULL,
    city text NOT NULL,
    zip text NOT NULL,
    county text NOT NULL,
    phone text NOT NULL,
    c_relatn text NOT NULL,
    c_legbas text NOT NULL,
    c_admin text NOT NULL,
    c_fscs text NOT NULL,
    geocode text NOT NULL,
    lsabound text NOT NULL,
    startdate text NOT NULL,
    enddate text NOT NULL,
    popu_lsa integer NOT NULL,
    popu_und integer NOT NULL,
    centlib integer NOT NULL,
    branlib integer NOT NULL,
    bkmob integer NOT NULL,
    totstaff numeric(8,2) NOT NULL,
    bkvol integer NOT NULL,
    ebook integer NOT NULL,
    audio_ph integer NOT NULL,
    audio_dl integer NOT NULL,
    video_ph integer NOT NULL,
    video_dl integer NOT NULL,
    ec_lo_ot integer NOT NULL,
    subscrip integer NOT NULL,
    hrs_open integer NOT NULL,
    visits integer NOT NULL,
    reference integer NOT NULL,
    regbor integer NOT NULL,
    totcir integer NOT NULL,
    kidcircl integer NOT NULL,
    totpro integer NOT NULL,
    gpterms integer NOT NULL,
    pitusr integer NOT NULL,
    wifisess integer NOT NULL,
    obereg text NOT NULL,
    statstru text NOT NULL,
    statname text NOT NULL,
    stataddr text NOT NULL,
    longitude numeric(10,7) NOT NULL,
    latitude numeric(10,7) NOT NULL
);

COPY pls_fy2018_libraries
FROM '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_09/pls_fy2018_libraries.csv'
WITH (FORMAT CSV, HEADER);

CREATE INDEX libname_2018_idx 
ON pls_fy2018_libraries (libname);

SELECT * FROM pls_fy2018_libraries;

CREATE TABLE pls_fy2017_libraries (
    stabr text NOT NULL,
    fscskey text CONSTRAINT fscskey_17_pkey PRIMARY KEY,
    libid text NOT NULL,
    libname text NOT NULL,
    address text NOT NULL,
    city text NOT NULL,
    zip text NOT NULL,
    county text NOT NULL,
    phone text NOT NULL,
    c_relatn text NOT NULL,
    c_legbas text NOT NULL,
    c_admin text NOT NULL,
    c_fscs text NOT NULL,
    geocode text NOT NULL,
    lsabound text NOT NULL,
    startdate text NOT NULL,
    enddate text NOT NULL,
    popu_lsa integer NOT NULL,
    popu_und integer NOT NULL,
    centlib integer NOT NULL,
    branlib integer NOT NULL,
    bkmob integer NOT NULL,
    totstaff numeric(8,2) NOT NULL,
    bkvol integer NOT NULL,
    ebook integer NOT NULL,
    audio_ph integer NOT NULL,
    audio_dl integer NOT NULL,
    video_ph integer NOT NULL,
    video_dl integer NOT NULL,
    ec_lo_ot integer NOT NULL,
    subscrip integer NOT NULL,
    hrs_open integer NOT NULL,
    visits integer NOT NULL,
    reference integer NOT NULL,
    regbor integer NOT NULL,
    totcir integer NOT NULL,
    kidcircl integer NOT NULL,
    totpro integer NOT NULL,
    gpterms integer NOT NULL,
    pitusr integer NOT NULL,
    wifisess integer NOT NULL,
    obereg text NOT NULL,
    statstru text NOT NULL,
    statname text NOT NULL,
    stataddr text NOT NULL,
    longitude numeric(10,7) NOT NULL,
    latitude numeric(10,7) NOT NULL
);

CREATE TABLE pls_fy2016_libraries (
    stabr text NOT NULL,
    fscskey text CONSTRAINT fscskey_16_pkey PRIMARY KEY,
    libid text NOT NULL,
    libname text NOT NULL,
    address text NOT NULL,
    city text NOT NULL,
    zip text NOT NULL,
    county text NOT NULL,
    phone text NOT NULL,
    c_relatn text NOT NULL,
    c_legbas text NOT NULL,
    c_admin text NOT NULL,
    c_fscs text NOT NULL,
    geocode text NOT NULL,
    lsabound text NOT NULL,
    startdate text NOT NULL,
    enddate text NOT NULL,
    popu_lsa integer NOT NULL,
    popu_und integer NOT NULL,
    centlib integer NOT NULL,
    branlib integer NOT NULL,
    bkmob integer NOT NULL,
    totstaff numeric(8,2) NOT NULL,
    bkvol integer NOT NULL,
    ebook integer NOT NULL,
    audio_ph integer NOT NULL,
    audio_dl integer NOT NULL,
    video_ph integer NOT NULL,
    video_dl integer NOT NULL,
    ec_lo_ot integer NOT NULL,
    subscrip integer NOT NULL,
    hrs_open integer NOT NULL,
    visits integer NOT NULL,
    reference integer NOT NULL,
    regbor integer NOT NULL,
    totcir integer NOT NULL,
    kidcircl integer NOT NULL,
    totpro integer NOT NULL,
    gpterms integer NOT NULL,
    pitusr integer NOT NULL,
    wifisess integer NOT NULL,
    obereg text NOT NULL,
    statstru text NOT NULL,
    statname text NOT NULL,
    stataddr text NOT NULL,
    longitude numeric(10,7) NOT NULL,
    latitude numeric(10,7) NOT NULL
);

COPY pls_fy2017_libraries
FROM '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_09/pls_fy2017_libraries.csv'
WITH (FORMAT CSV, HEADER);

COPY pls_fy2016_libraries
FROM '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_09/pls_fy2016_libraries.csv'
WITH (FORMAT CSV, HEADER);

CREATE INDEX lib_name_2017_idx
ON pls_fy2017_libraries (libname);

CREATE INDEX lib_name_2016_idx
ON pls_fy2016_libraries (libname);

SELECT count(*)
FROM pls_fy2018_libraries;

SELECT count(*)
FROM pls_fy2017_libraries;

SELECT count(*)
FROM pls_fy2016_libraries;

SELECT count(phone)
FROM pls_fy2018_libraries;

SELECT count(libname)
FROM pls_fy2018_libraries;

SELECT count(DISTINCT libname)
FROM pls_fy2018_libraries;

SELECT max(visits), min(visits)
FROM pls_fy2018_libraries;

SELECT stabr
FROM pls_fy2018_libraries
GROUP BY stabr
ORDER BY stabr;

SELECT city, stabr
FROM pls_fy2018_libraries
GROUP BY city, stabr
ORDER BY city, stabr;

SELECT stabr, count(*)
FROM pls_fy2018_libraries
GROUP BY stabr
ORDER BY count(*) DESC;

SELECT stabr, stataddr, count(*)
FROM pls_fy2018_libraries
GROUP BY stabr, stataddr
ORDER BY stabr, stataddr;

SELECT sum(visits) AS visits_2018
FROM pls_fy2018_libraries
WHERE visits >= 0;

SELECT sum(visits) AS visits_2017
FROM pls_fy2017_libraries
WHERE visits >= 0;

SELECT sum(visits) AS visits_2016
FROM pls_fy2016_libraries
WHERE visits >= 0;

SELECT sum(pls18.visits) AS visits_2018,
       sum(pls17.visits) AS visits_2017,
       sum(pls16.visits) AS visits_2016
FROM pls_fy2018_libraries AS pls18
JOIN pls_fy2017_libraries AS pls17
    ON pls18.fscskey = pls17.fscskey
JOIN pls_fy2016_libraries AS pls16
    ON pls18.fscskey = pls16.fscskey
WHERE pls18.visits >= 0
    AND pls17.visits >= 0
    AND pls16.visits >= 0;

SELECT sum(pls18.wifisess) AS wifi_2018,
       sum(pls17.wifisess) AS wifi_2017,
       sum(pls16.wifisess) AS wifi_2016
FROM pls_fy2018_libraries AS pls18
JOIN pls_fy2017_libraries as pls17
    ON pls18.fscskey = pls17.fscskey
JOIN pls_fy2016_libraries as pls16
    ON pls18.fscskey = pls16.fscskey
WHERE pls18.visits >= 0
    AND pls17.visits >= 0
    AND pls16.visits >= 0;

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
HAVING sum(pls18.visits) > 50000000
ORDER BY chg_2018_17 DESC;
