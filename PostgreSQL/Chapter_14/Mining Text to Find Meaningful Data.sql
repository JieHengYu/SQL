SELECT char_length(' Pat ');

SELECT char_length(trim(' Pat '));

SELECT substring('The game starts at 7 p.m. on 
	May 2, 2024' from '\d{4}');

SELECT county_name
FROM us_counties_pop_est_2019
WHERE county_name ~* '(lade|lare)'
ORDER BY county_name;

SELECT county_name
FROM us_counties_pop_est_2019
WHERE county_name ~* 'ash' AND county_name != 'Wash'
ORDER BY county_name;

SELECT regexp_replace('05/12/2024', '\d{4}', '2023');

SELECT regexp_split_to_table(
	   	   'Four,score,and,seven,years,ago', ',');

SELECT regexp_split_to_array(
       	   'Phil Mike Tony Steve', ' ');

SELECT array_length(regexp_split_to_array(
           'Phil Mike Tony Steve', ' '), 1);

CREATE TABLE crime_reports (
    crime_id integer PRIMARY KEY
        GENERATED ALWAYS AS IDENTITY,
    case_number text,
    date_1 timestamptz,
    date_2 timestamptz,
    street text,
    city text,
    crime_type text,
    description text,
    original_text text NOT NULL
);

COPY crime_reports (original_text)
FROM '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_14/crime_reports.csv'
WITH (FORMAT CSV, HEADER OFF, QUOTE '"');

SELECT original_text FROM crime_reports;

SELECT crime_id,
       regexp_match(original_text, 
		   '\d{1,2}\/\d{1,2}\/\d{2}')
FROM crime_reports
ORDER BY crime_id;

SELECT crime_id,
       regexp_match(original_text, 
	   	   '-\d{1,2}\/\d{1,2}\/\d{2}')
FROM crime_reports
ORDER BY crime_id;

SELECT crime_id,
       regexp_match(original_text,
           '-(\d{1,2}\/\d{1,2}\/\d{2})')
FROM crime_reports
ORDER BY crime_id;

SELECT crime_id,
       regexp_match(original_text,
           '\/\d{2}\n(\d{4})')
FROM crime_reports
ORDER BY crime_id;

SELECT crime_id,
       regexp_match(original_text,
           '\/\d{2}\n\d{4}-(\d{4})')
FROM crime_reports
ORDER BY crime_id;

SELECT crime_id,
       regexp_match(original_text,
           'hrs.\n(\d+ .+(?:Sq.|Plz.|Dr.|Ter.|Rd.))')
FROM crime_reports
ORDER BY crime_id;

SELECT crime_id,
       regexp_match(original_text,
           '(?:Sq.|Plz.|Dr.|Ter.|Rd.)\n(\w+ \w+|\w+)\n')
FROM crime_reports
ORDER BY crime_id;

SELECT crime_id,
       regexp_match(original_text,
           '\n(?:\w+ \w+|\w+)\n(.*):')
FROM crime_reports
ORDER BY crime_id;

SELECT crime_id,
       regexp_match(original_text,
           ':\s(.+)(?:C0|SO)')
FROM crime_reports
ORDER BY crime_id;

SELECT crime_id,
       regexp_match(original_text,
           '(?:C0|SO)[0-9]+')
FROM crime_reports
ORDER BY crime_id;

SELECT regexp_match(original_text,
           '(?:C0|SO)[0-9]+') AS case_number,
       regexp_match(original_text,
           '\d{1,2}\/\d{1,2}\/\d{2}') AS date_1,
       regexp_match(original_text,
           '\n(?:\w+ \w+|\w+)\n(.*):') AS crime_type,
       regexp_match(original_text,
           '(?:Sq.|Plz.|Dr.|Ter.|Rd.)\n(\w+ \w+|\w+)\n')
           AS city
FROM crime_reports
ORDER BY crime_id;

SELECT crime_id,
       (regexp_match(original_text,
           '(?:C0|SO)[0-9]+'))[1] AS case_number
FROM crime_reports
ORDER BY crime_id;

UPDATE crime_reports
SET date_1 = (
    (regexp_match(original_text,
    '\d{1,2}\/\d{1,2}\/\d{2}'))[1]
        || ' ' ||
    (regexp_match(original_text,
    '\/\d{2}\n(\d{4})'))[1]
        ||' US/Eastern'
)::timestamptz
RETURNING crime_id, date_1, original_text;

UPDATE crime_reports
SET date_1 = (
        (regexp_match(original_text,
        '\d{1,2}\/\d{1,2}\/\d{2}'))[1]
            || ' ' ||
        (regexp_match(original_text,
        '\/\d{2}\n(\d{4})'))[1]
            ||' US/Eastern'
              )::timestamptz,
    date_2 =
        CASE
            WHEN (SELECT regexp_match(original_text,
                 '-(\d{1,2}\/\d{1,2}\/\d{2})') 
				 IS NULL)
                 AND (SELECT regexp_match(original_text,
                     '\/\d{2}\n\d{4}-(\d{4})') 
					 IS NOT NULL)
            THEN ((regexp_match(original_text,
                  '\d{1,2}\/\d{1,2}\/\d{2}'))[1]
                      || ' ' ||
                  (regexp_match(original_text,
                  '\/\d{2}\n\d{4}-(\d{4})'))[1]
                      ||' US/Eastern'
                  )::timestamptz
            WHEN (SELECT regexp_match(original_text,
                 '-(\d{1,2}\/\d{1,2}\/\d{2})') 
				 IS NOT NULL)
                 AND (SELECT regexp_match(original_text,
                     '\/\d{2}\n\d{4}-(\d{4})') 
					 IS NOT NULL)
            THEN ((regexp_match(original_text,
                  '-(\d{1,2}\/\d{1,2}\/\d{1,2})'))[1]
                      || ' ' ||
                  (regexp_match(original_text,
                  '\/\d{2}\n\d{4}-(\d{4})'))[1]
                      ||' US/Eastern'
                  )::timestamptz
        END,
    street = (regexp_match(original_text,
        'hrs.\n(\d+ .+(?:Sq.|Plz.|Dr.|Ter.|Rd.))'))[1],
    city = (regexp_match(original_text,
        '(?:Sq.|Plz.|Dr.|Ter.|Rd.)\n(\w+ \w+|\w+)\n'))[1],
    crime_type = (regexp_match(original_text,
        '\n(?:\w+ \w+|\w+)\n(.*):'))[1],
    description = (regexp_match(original_text,
        ':\s(.+)(?:C0|SO)'))[1],
    case_number = (regexp_match(original_text,
        '(?:C0|SO)[0-9]+'))[1];

SELECT date_1, street, city, crime_type
FROM crime_reports
ORDER BY crime_id;

SELECT to_tsvector('english',
           'I am walking across the sitting
           room to sit with you.');

SELECT to_tsquery('english',
           'walking & sitting');

SELECT to_tsvector('english',
           'I am walking across the sitting
           room') @@ to_tsquery('english',
           'walking & sitting');

SELECT to_tsvector('english',
           'I am walking across the sitting
           room') @@ to_tsquery('english',
           'walking & running');		   

CREATE TABLE president_speeches (
    president text NOT NULL,
    title text NOT NULL,
    speech_date date NOT NULL,
    speech_text text NOT NULL,
    search_speech_text tsvector,
    CONSTRAINT speech_key PRIMARY KEY (
        president, speech_date)
);

COPY president_speeches (president, title,
         speech_date, speech_text)
FROM '/Users/jiehengyu/Desktop/PostgreSQL/Chapter_14/president_speeches.csv'
WITH (FORMAT CSV, DELIMITER '|', HEADER OFF, QUOTE '@');

SELECT * FROM president_speeches;

UPDATE president_speeches
SET search_speech_text = to_tsvector(
        'english', speech_text);

CREATE INDEX search_idx ON president_speeches
USING gin(search_speech_text);

SELECT president, speech_date
FROM president_speeches
WHERE search_speech_text @@ to_tsquery(
          'english', 'Vietnam')
ORDER BY speech_date;

SELECT president,
       speech_date,
       ts_headline(speech_text, to_tsquery('english',
           'tax'), 'StartSel = <, StopSel = >,
           MinWords = 5, MaxWords = 7, 
		   MaxFragments = 1')
FROM president_speeches
WHERE search_speech_text @@ to_tsquery('english', 'tax')
ORDER BY speech_date;

SELECT president,
       speech_date,
       ts_headline(speech_text, to_tsquery('english',
           'transportation & !roads'), 'StartSel = <,
           StopSel = >, MinWords = 5, MaxWords = 7,
           MaxFragments = 1')
FROM president_speeches
WHERE search_speech_text @@ to_tsquery('english',
          'transportation & !roads')
ORDER BY speech_date;

SELECT president,
       speech_date,
       ts_headline(speech_text, to_tsquery('english',
           'military <-> defense'), 'StartSel = <,
           StopSel = >, MinWords = 5, MaxWords = 7,
           MaxFragments = 1')
FROM president_speeches
WHERE search_speech_text @@ to_tsquery('english',
          'military <-> defense')
ORDER BY speech_date;

SELECT president,
       speech_date,
       ts_rank(search_speech_text, to_tsquery('english',
           'war & security & threat & enemy')) AS score
FROM president_speeches
WHERE search_speech_text @@ to_tsquery('english',
          'war & security & threat & enemy')
ORDER BY score DESC
LIMIT 5;

SELECT president,
       speech_date,
       ts_rank(search_speech_text,
           to_tsquery('english',
           'war & security & threat & enemy'),
           2)::numeric AS score
FROM president_speeches
WHERE search_speech_text @@ to_tsquery('english',
          'war & security & threat & enemy')
ORDER BY score DESC
LIMIT 5;















