CREATE TABLE artists (
	artist_id smallint,
	artist_name text,
	label_owner text
);

COPY artists
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/Spotify - Top 5 Artists/artists.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM artists;

CREATE TABLE songs (
	song_id integer,
	artist_id smallint,
	name text
);

COPY songs
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/Spotify - Top 5 Artists/songs.csv'
WITH (FORMAT CSV, HEADER, QUOTE '"');

SELECT * FROM songs;

CREATE TABLE global_song_rank (
	day smallint,
	song_id integer,
	rank smallint
);

COPY global_song_rank
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/Spotify - Top 5 Artists/global_song_rank.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM global_song_rank;

SELECT *
FROM (
	WITH top10_songs_global
	AS (
		SELECT global_song_rank.day,
			   artists.artist_name,
			   songs.name,
			   global_song_rank.rank
		FROM global_song_rank
		LEFT JOIN songs
			ON global_song_rank.song_id = songs.song_id
		LEFT JOIN artists
			ON songs.artist_id = artists.artist_id
		WHERE global_song_rank.rank <= 10
	)
	SELECT artist_name,
		   count(*),
		   dense_rank() OVER (ORDER BY count(*) DESC)
	FROM top10_songs_global
	GROUP BY artist_name
	ORDER BY count(*) DESC
)
WHERE dense_rank <= 5;
