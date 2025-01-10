CREATE TABLE search_frequency (
	searches smallint,
	num_users smallint
);

INSERT INTO search_frequency
VALUES (1, 2),
	   (4, 1),
	   (2, 2),
	   (3, 3),
	   (6, 1),
	   (5, 3),
	   (7, 2);

SELECT * FROM search_frequency;

SELECT *,
	  sum(num_users) OVER (ORDER BY searches) 
		  AS sum_freq,
	  sum(num_users) OVER () AS total_freq
FROM search_frequency
ORDER BY searches;

SELECT round(avg(searches), 1) AS median
FROM (
	SELECT *,
	      sum(num_users) OVER (ORDER BY searches) 
		  	  AS sum_freq,
		  sum(num_users) OVER () AS total_freq
	FROM search_frequency
	ORDER BY searches
)
WHERE total_freq <= 2 * sum_freq
	AND total_freq >= 2 * (sum_freq - num_users);

CREATE TABLE freq_table (
	number smallserial,
	freq smallint
);

INSERT INTO freq_table (freq)
VALUES (5),
	   (3),
	   (2),
	   (7),
	   (6),
	   (4),
	   (5),
	   (1);

SELECT * FROM freq_table;

SELECT round(avg(number), 1) AS median
FROM (
	SELECT *,
		   sum(freq) OVER (ORDER BY number) 
		   	   AS sum_freq,
		   sum(freq) OVER () AS total_freq
	FROM freq_table
)
WHERE total_freq <= 2 * sum_freq
	AND total_freq >= 2 * (sum_freq - freq);
