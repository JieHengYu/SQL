SELECT replace('Alvarez, Jr.', ',', '');

SELECT replace('Williams, Sr.', ',', '');

SELECT regexp_replace('Alvarez, Jr.', ',', '');

SELECT regexp_replace('Williams, Sr.', ',', '');

CREATE TABLE names_suffix (name text);

INSERT INTO names_suffix
VALUES ('Alvarez, Jr.'),
	   ('Williams, Sr.');

SELECT name,
	   (regexp_match(name, ',\s(\w+.)'))[1] AS suffix
FROM names_suffix;

SELECT regexp_replace(words, '[$,|$.]', '') AS words,
	   count(*)
FROM (
	SELECT regexp_split_to_table(speech_text, 
		   	   '\s+') AS words
	FROM president_speeches
	WHERE president = 'Joseph R. Biden'
)
GROUP BY regexp_replace(words, '[$,|$.]', '')
HAVING char_length(regexp_replace(words, 
		   '[$,|$.]', '')) > 5
ORDER BY count(*) DESC;

WITH biden_speech (words)
AS (
    SELECT regexp_replace(words, '[$,|$.]', '') AS words
    FROM (
        SELECT regexp_split_to_table(speech_text, 
    		   	   '\s+') AS words
    	FROM president_speeches
    	WHERE president = 'Joseph R. Biden'
    )
)
SELECT words,
	   count(*)
FROM biden_speech
GROUP BY words
HAVING char_length(words) > 5
ORDER BY count(*) DESC;

SELECT president,
       speech_date,
       ts_rank_cd(search_speech_text, to_tsquery(
           'english', 'war & security & threat & enemy'))
           AS score
FROM president_speeches
WHERE search_speech_text @@ to_tsquery('english',
          'war & security & threat & enemy')
ORDER BY score DESC
LIMIT 5;

SELECT speech_text
FROM president_speeches
WHERE president = 'William J. Clinton' 
	AND speech_date = '1997-02-04';
