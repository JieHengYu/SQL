CREATE TABLE posts (
	user_id integer,
	post_id integer,
	post_content text,
	post_date timestamp
);

INSERT INTO posts
VALUES (151652, 599415, 'Need a hug', '07/10/2021 12:00:00'),
	   (661093, 624356, 'Bed. Class 8-12. Work 12-3. Gym 3-5 or 6. Then class 6-10. Another day that''s gonna fly by. I miss my girlfriend', '07/29/2021 13:00:00'),
	   (004239, 784254, 'Happy 4th of July!', '07/04/2021 11:00:00'),
	   (661093, 442560, 'Just going to cry myself to sleep after watching Marley and Me.', '07/08/2021 14:00:00'),
	   (151652, 111766, 'I''m so done with covid - need travelling ASAP!', '07/12/2021 19:00:00');

SELECT * FROM posts;

SELECT user_id,
	   count(*) AS num_posts,
	   round((extract(epoch from max(post_date)) - 
	   	   extract(epoch from min(post_date))) / 86400)
	   	   AS days_between
FROM posts
GROUP BY user_id
HAVING count(*) >= 2;
