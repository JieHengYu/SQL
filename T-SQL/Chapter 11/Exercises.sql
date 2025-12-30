-----------------

-- Exercise

-----------------

-- This section provides exercises to help us familiarise ourselves with the subjects discussed in this lesson. 

USE TSQLV6;



------------------
-- Exercise 1
------------------

-- In this exercise, we'll query data from the tables `Graph.Account` & `Graph.Follows`.

-------------------
-- Exercise 1-1
-------------------

-- Write a query that identifies who follows Stav:

SELECT Account1.accountname
FROM Graph.Account AS Account1, Graph.Follows,
	Graph.Account AS Account2
WHERE MATCH(Account1-(Follows)->Account2)
	AND Account2.accountname = N'Stav';



-------------------
-- Exercise 1-2
-------------------

-- Write a query that identifies who follows Stav, Yatzek, or both:

SELECT Account1.accountname, Account2.accountname AS follows
FROM Graph.Account AS Account1, Graph.Follows,
	Graph.Account AS Account2
WHERE MATCH(Account1-(Follows)->Account2)
	AND Account2.accountname IN (N'Stav', N'Yatzek');



--------------------
-- Exercise 1-3
--------------------

-- Write a query that identifies who follows both Stav & Yatzek:

SELECT Account1.accountname AS account, Account2.accountname AS follows,
	Account3.accountname AS alsofollows
FROM Graph.Account AS Account1, Graph.Follows AS F1,
	Graph.Account AS Account2, Graph.Follows AS F2,
	Graph.Account AS Account3
WHERE MATCH(Account2<-(F1)-Account1-(F2)->Account3)
	AND Account2.accountname = N'Stav'
	AND Account3.accountname = N'Yatzek';
	


--------------------
-- Exercise 1-4
--------------------

-- Write a query that identifies who follows Stav but not Yatzek:

SELECT Account1.accountname
FROM Graph.Account AS Account1, Graph.Follows AS F1,
	Graph.Account AS Account2
WHERE MATCH(Account1-(F1)->Account2)
	AND Account2.accountname = N'Stav'
	AND NOT EXISTS (SELECT *
					FROM Graph.Account AS Account3, Graph.Follows AS F2
					WHERE MATCH(Account1-(F2)->Account3)
						AND Account3.accountname = N'Yatzek');



-----------------
-- Exercise 2
-----------------

-- In this exercise, we'll query data from the tables `Graph.Account`, `Graph.IsFriendOf`, & `Graph.Follows`:

-------------------
-- Exercise 2-1
-------------------

-- Write a query that returns relationships where the first account is a friend of the second account, follows the second account, or both.

SELECT Account1.accountid AS actid1, Account1.accountname AS act1,
	Account2.accountid AS actid2, Account2.accountname AS act2
FROM Graph.Account AS Account1, Graph.Account AS Account2
WHERE EXISTS (SELECT * FROM Graph.IsFriendOf
			  WHERE MATCH(Account1-(IsFriendOf)->Account2))
	OR EXISTS (SELECT * FROM Graph.Follows
		       WHERE MATCH(Account1-(Follows)->Account2));



--------------------
-- Exercise 2-2
--------------------

-- Write a query that returns relationships where the first account is a friend of, but doesn't follow the second account:

SELECT Account1.accountid AS actid1, Account1.accountname AS act1,
	Account2.accountid AS actid2, Account2.accountname AS act2
FROM Graph.Account AS Account1, Graph.Account AS Account2
WHERE EXISTS (SELECT * FROM Graph.IsFriendOf
			  WHERE MATCH(Account1-(IsFriendOf)->Account2))
	AND NOT EXISTS (SELECT * FROM Graph.Follows
				    WHERE MATCH(Account1-(Follows)->Account2));



------------------
-- Exercise 3
------------------

-- Given an input post ID, possibly representing a reply to another post, return the chain of posts leading to the input one. Use a recursive query. Use the tables `Graph.Post` & `Graph.IsReplyTo`:

DECLARE @postid AS INT = 1187;

WITH C AS (
	SELECT postid, posttext, 0 AS ordervalue
	FROM Graph.Post
	WHERE Post.postid = @postid

	UNION ALL

	SELECT ParentPost.postid, ParentPost.posttext,
		ordervalue + 1 AS ordervalue
	FROM C, Graph.Post AS ChildPost, Graph.IsReplyTo,
		Graph.Post AS ParentPost
	WHERE C.postid = ChildPost.postid
		AND MATCH(ChildPost-(IsReplyTo)->ParentPost)
)
SELECT postid, posttext
FROM C
ORDER BY ordervalue DESC;



------------------
-- Exercise 4
------------------

-- Solve Exercise 3 again, only this time using the SHORTEST_PATH option:

DECLARE @postid AS INT = 1187;

WITH C AS (
	SELECT postid, posttext, 0 AS ordervalue
	FROM Graph.Post
	WHERE Post.postid = @postid

	UNION ALL

	SELECT LAST_VALUE(ParentPost.postid) WITHIN GROUP (GRAPH PATH) AS postid,
		LAST_VALUE(ParentPost.posttext) WITHIN GROUP (GRAPH PATH) AS posttext,
		COUNT(ParentPost.postid) WITHIN GROUP (GRAPH PATH) AS ordervalue
	FROM Graph.Post AS ChildPost,
		Graph.IsReplyTo FOR PATH AS IRT,
		Graph.Post FOR PATH AS ParentPost
	WHERE MATCH(SHORTEST_PATH(ChildPost(-(IRT)->ParentPost)+))
		AND ChildPost.postid = 1187
)
SELECT postid, posttext
FROM C
ORDER BY ordervalue DESC;