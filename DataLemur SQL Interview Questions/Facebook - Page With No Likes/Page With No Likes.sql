CREATE TABLE pages (
	page_id integer,
	page_name varchar(25)
);

INSERT INTO pages
VALUES (20001, 'SQL Solutions'),
	   (20045, 'Brain Exercises'),
	   (20701, 'Tips for Data Analysts');

CREATE TABLE page_likes (
	user_id smallint,
	page_id integer,
	liked_date timestamp
);

INSERT INTO page_likes
VALUES (111, 20001, '04/08/2022 00:00:00'),
	   (121, 20045, '03/12/2022 00:00:00'),
	   (156, 20001, '07/25/2022 00:00:00');

SELECT * FROM pages;

SELECT * FROM page_likes;

SELECT * 
FROM pages
LEFT JOIN page_likes
	ON pages.page_id = page_likes.page_id
WHERE liked_date IS NULL
ORDER BY pages.page_id;
