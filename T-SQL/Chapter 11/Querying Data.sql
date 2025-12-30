--------------------

-- Querying Data

--------------------

-- Querying graph data is one of the key advantages of SQL Graph. With the specialised graph extensions to T-SQL, we can write queries that are more elegant, intuitive, & concise than those built using traditional tools like

-- joins.



------------------------------
-- Using the MATCH Clause
------------------------------

-- The primary language extension for querying graph data is the MATCH clause. In this section, we'll focus on how to use it in SELECT queries, & later we'll cover how it applies to data modification statements. The general

-- syntax for a SELECT query against graph objects looks like this:

	-- `SELECT <select_list>
	--	FROM <commalist of graph objects>
	--  WHERE MATCH(<match_specifications_1>) [... AND MATCH(<match_specification_n>)];`

-- The match specification defines the relationships between graph objects using an elegant ASCII-art-style pattern. More advanced features are also available -- such as the SHORTEST_PATH option, which we'll discuss later.



-- The best way to learn this syntax is through examples. We'll start by comparing traditional T-SQL querying with graph querying, & once the differences are clear, we'll focus solely on graph-based syntax. Let's begin with a

-- simple example. Suppose we need to retrieve accounts with their associated posts. In the traditional relational model, we would use a join:

USE TSQLV6;

SELECT A.accountid, A.accountname, P.postid, P.posttext
FROM Norm.Accounts AS A
	INNER JOIN Norm.Posts AS P
		ON A.accountid = P.accountid;



-- In the traditional relational model, we connect an account to its posts by storing an `accountid` column in the `Norm.Posts` table. This design works without an additional junction table because each post is associated with 

-- exactly one account. From the posts' perspective, the relationship is one-to-one, & from the account's perspective, it is one-to-many. If the relationship were many-to-many, we would need a third table (a junction table) &

-- the query would require two joins instead of one.



-- In a graph model, nodes are linked through edges, so we typically use a separate edge table to connect two nodes, regardless of whether the relationship is one-to-one, one-to-many, or many-to-many. In our case, the edge table

-- linking the `Graph.Post` & `Graph.Account` nodes is the `Graph.Posted` table. Therefore, to match accounts with their respective posts using graph syntax, we include all three objects in the FROM clause, separated by commas, 

-- like this:

	-- `FROM Graph.Account, Graph.Posted, Graph.Post`



-- Next, we need to define the WHERE clause. In the MATCH predicate, we express relationships using an ASCII-art-style pattern. The basic form for connecting two nodes through an edge looks like this:

	-- `from_node-(edge)->to_node`

-- The key detail is the direction of the arrow. We can represent the same relationship by reversing both the arrow direction & the node order:

	-- `to_node<-(edge)-from_node`

-- In a simple case like this, either option works the same. However, as we'll see with more complex scenarios, being able to point the arrow left or right becomes extremely useful when expressing more intricate relationships.

-- For our example, the WHERE clause should look like this:

	-- `WHERE MATCH(Account-(Posted)->Post)`

-- Finally, we add the SELECT list to return the fields we need. Here's the complete graph query:

SELECT accountid, accountname, postid, posttext
FROM Graph.Account, Graph.Posted, Graph.Post
WHERE MATCH(Account-(Posted)->Post);



-- We can assign aliases to graph tables in the FROM clause. When we do, those aliases must also be used in the MATCH clause, replacing the original table names. For instance, if we alias `Graph.Account AS Act`, the match 

-- specification becomes `Act-(Posted)->Post`. Here's the full query:

SELECT accountid, accountname, postid, posttext
FROM Graph.Account AS Act, Graph.Posted, Graph.Post
WHERE MATCH(Act-(Posted)->Post);

-- In this simple case, our alias doesn't provide much benefit. However, as we'll see later, aliases become essential when we need to reference the same table multiple times within a single query.



-- Earlier, we showed a traditional query using an inner join to match posts with their accounts, alongside the graph-based alternative. That comparison may give the impression that the two approaches are logically equivalent.

-- However, the semantics of the graph query are actually closer to those of an outer join, where the edge table represents the preserved side of the relationship. For example, querying the graph with the pattern

-- `Account-(Posted)->Post` is more accurately matched by the following traditional query:

SELECT A.accountid, A.accountname, P.postid, P.posttext
FROM Norm.Posts AS P
	LEFT OUTER JOIN Norm.Accounts AS A
		ON P.accountid = A.accountid;

-- In practice, we typically enforce constraints that ensure every edge connects existing nodes. In a relational model, this is achieved with foreign keys; in a graph model, with edge constraints. When such constraints guarantee

-- that no orphaned edges can exist, both the inner join & outer join forms will produce the same results -- so the original comparison still holds in a well-designed system.



-- So far, we've shown traditional T-SQL queries against the relational model & graph queries against the graph model. We might wonder whether we can still use traditional join-based T-SQL when working with graph tables, & the

-- answer is yes. This is fully supported. In our example, we simply join the three relevant tables -- the edge table & the two node tables. To reflect the same logic as the graph path, we use outer joins, preserving the edge

-- table. The join predicates explicitly match the `$from_id` & `$to_id` columns in the edge table with the `$node_id` columns in the node tables, like so:

SELECT Account.accountid, Account.accountname,
	Post.postid, Post.posttext
FROM Graph.Posted
	LEFT OUTER JOIN Graph.Account
		ON Posted.$from_id = Account.$node_id
	LEFT OUTER JOIN Graph.Post
		ON Posted.$to_id = Post.$node_id;

-- There are two main advantages to being able to use traditional T-SQL syntax with graph objects:

	-- 1. Troubleshooting & validation: It allows us to confirm that our MATCH patterns reflect the expected logic.

	-- 2. Feature flexibility: Some scenarios, such as recursive queries, are not yet supported in graph syntax, but work using traditional joins.

-- In general, when both options are supported, the specialised graph syntax is preferred for querying graph relationships. But because graph syntax can only be used with graph objects, & not with traditional relational tables,

-- the ability to fall back on standard T-SQL ensures we always have a reliable alternative.



-- Our next task is to return accounts along with their publications. We'll start with the traditional relational model. The relationship between accounts (in the `Accounts` table) & publications (in the `Publications` table) is

-- many-to-many, so the model includes a third table `AuthorsPublications` to link them. We can solve the task using a three-way join:

SELECT A.accountid, A.accountname, P.pubid, P.title
FROM Norm.Accounts AS A
	INNER JOIN Norm.AuthorsPublications AS AP
		ON A.accountid = AP.accountid
	INNER JOIN Norm.Publications AS P
		ON AP.pubid = P.pubid;

-- With graph querying, we list the relevant graph objects, the `Graph.Account` node, the `Graph.Authored` edge, & the `Graph.Publication` node in the FROM clause, & express the relationship pattern in the MATCH clause:

SELECT accountid, accountname, pubid, title
FROM Graph.Account, Graph.Authored, Graph.Publication
WHERE MATCH(Account-(Authored)->Publication);

-- Notice again that the traditional query uses inner joins, while graph queries follow outer-join semantics. The following version, using outer joins & preserving the edge table, more accurately reflects the logical behaviour

-- of the graph query:

SELECT A.accountid, A.accountname, P.pubid, P.title
FROM Norm.AuthorsPublications AS AP
	LEFT OUTER JOIN Norm.Accounts AS A
		ON AP.accountid = A.accountid
	LEFT OUTER JOIN Norm.Publications AS P
		ON AP.pubid = P.pubid;



-- Earlier, we noted that with edge constraints enforcing graph data integrity, orphaned edges cannot exist. In that case, graph queries will never produce "outer" rows. However, if edge constraints are not enforced, SQL Server

-- will not prevent orphaned edges -- & if they appear, graph queries may return rows containing NULL values. Their presence is a clear indicator of inconsistencies in the data. To demonstrate this using our sample data, we'll

-- temporarily disable the integrity enforcement on the `Graph.Authored` edge table. Use the following code to disable the edge constraint `EC_Authored`:

ALTER TABLE Graph.Authored NOCHECK CONSTRAINT EC_Authored;

-- With this constraint active, SQL Server ensures that each authored edge connects an existing account node to an existing publication node. Next, insert a few edges that reference node IDs not found in the corresponding node

-- tables:

INSERT INTO Graph.Authored ($from_id, $to_id)
VALUES (NODE_ID_FROM_PARTS(OBJECT_ID(N'Graph.Account'), -1), NODE_ID_FROM_PARTS(OBJECT_ID(N'Graph.Publication'), -1));

INSERT INTO Graph.Authored ($from_id, $to_id)
VALUES (NODE_ID_FROM_PARTS(OBJECT_ID(N'Graph.Account'), -1), NODE_ID_FROM_PARTS(OBJECT_ID(N'Graph.Publication'), 0));

INSERT INTO Graph.Authored ($from_id, $to_id)
VALUES (NODE_ID_FROM_PARTS(OBJECT_ID(N'Graph.Account'), 0), NODE_ID_FROM_PARTS(OBJECT_ID(N'Graph.Publication'), -1));

-- Recall that SQL Server generates node IDs starting at 0. Here, we're using -1 to guarantee orphaned references, but an orphaned edge could just as easily result from deleting a node row that once existed -- if no edge

-- constraint is in place to prevent the deletion. Now, run the graph query that returns accounts & their publications:

SELECT accountid, accountname, pubid, title
FROM Graph.Account, Graph.Authored, Graph.Publication
WHERE MATCH(Account-(Authored)->Publication);

-- This time, the result set includes outer rows: edges pointing to missing nodes show NULL values for the attributes of the nonexistent account or publication. We may see cases where the account side is orphaned, the publication

-- is orphaned, or both, highlighting why edge constraints are so important for maintaining data integrity. When finished, remove the orphaned edges:

DELETE FROM Graph.Authored
WHERE -1 IN (GRAPH_ID_FROM_NODE_ID($from_id), GRAPH_ID_FROM_NODE_ID($to_id));

-- Then, re-enable the edge constraint:

ALTER TABLE Graph.Authored WITH CHECK CHECK CONSTRAINT EC_Authored;



-- Let's move on to graph queries with more elaborate match patterns. Our next goal is to return all posts, some of which may be replies to other posts, along with their direct replies. For both the original post & the reply, we

-- want to return the posting account's name & the post text. To express this scenario, we need three relationships:

	-- 1. Account 1 posted Post 1

	-- 2. Account 2 posted Post 2

	-- 3. Post 2 is a reply to Post 1

-- Each of the graph objects involved, the `Graph.Account` node, the `Graph.Posted` edge, & the `Graph.Post` node, play two distinct roles. Therefore, we must reference each of these tables twice in the FROM clause & assign

-- aliases to distinguish the roles.



-- We'll alias the two `Account` references as `Account1` & `Account2`. For `Post`, we'll use `Post` for the original post & `Reply` for reply. The `Posted` edge will also appear twice: once connecting `Account1` to `Post`, & 

-- again connecting `Account2` to `Reply`, which we'll alias as `RepliedWith`. Finally, we include the `IsReplyTo` edge once, since it plays a single role. The `FROM` clause looks like this:

	-- `FROM Graph.Account AS Account 1, Graph.Posted, Graph.Post,
	--		Graph.Account AS Account 2, Graph.Posted AS RepliedWith,
	--		Graph.Post AS Reply, Graph.IsReplyTo`

-- Now, let's translate the three relationships into base match patterns:

	-- 1. `Account1-(Posted)->Post`

	-- 2. `Account2-(RepliedWith)->Reply`

	-- 3. `Reply-(IsReplyTo)->Post`

-- Applying this to our scenario, first, we'll merge pattern 1 & 3 since both share `Post` as the "to node":

	-- `Account1-(Posted)->(Post)<-(IsReplyTo)-Reply`

-- Then, we merge this with pattern 2, since `Reply` plays a role in both patterns:

	-- `Account1-(Posted)->(Post)<-(IsReplyTo)-Reply`<-(RepliedWith)-Account2

-- With the aliases, table list, & merged match pattern in place, we can write the complete query:

SELECT Account1.accountname AS account1, Post.posttext,
	Account2.accountname AS account2, Reply.posttext AS replytext
FROM Graph.Account AS Account1, Graph.Posted, Graph.Post,
	Graph.Account AS Account2, Graph.Posted AS RepliedWith,
	Graph.Post AS Reply, Graph.IsReplyTo
WHERE MATCH(Account1-(Posted)->Post<-(IsReplyTo)-Reply<-(RepliedWith)-Account2)
ORDER BY Post.dt, Post.postid, Reply.dt;

-- If a single complex pattern feels too dense, T-SQL offers two equivalent alternatives for expressing multiple base relationships:

	-- 1. Multiple patterns combined inside one MATCH clause:

SELECT Account1.accountname AS account1, Post.posttext,
	Account2.accountname AS account2, Reply.posttext AS replytext
FROM Graph.Account AS Account1, Graph.Posted, Graph.Post,
	Graph.Account AS Account2, Graph.Posted AS RepliedWith,
	Graph.Post AS Reply, Graph.IsReplyTo
WHERE MATCH(Account1-(Posted)->Post
	AND Account2-(RepliedWith)->Reply
	AND Reply-(IsReplyTo)->Post)
ORDER BY Post.dt, Post.postid, Reply.dt;

	-- 2. Multiple MATCH clauses combined with AND:

SELECT Account1.accountname AS account1, Post.posttext,
	Account2.accountname AS account2, Reply.posttext AS replytext
FROM Graph.Account AS Account1, Graph.Posted, Graph.Post,
	Graph.Account AS Account2, Graph.Posted AS RepliedWith,
	Graph.Post AS Reply, Graph.IsReplyTo
WHERE MATCH(Account1-(Posted)->Post)
	AND MATCH(Account2-(RepliedWith)->Reply)
	AND MATCH(Reply-(IsReplyTo)->Post)
ORDER BY Post.dt, Post.postid, Reply.dt;

-- All three approaches are logically identical. SQL Server normalises them internally, so we can choose whichever style offers the best clarity & maintainability for our scenario.



-- Let's extend the previous task. We still want to return posts & their direct replies, but now we have an added condition: the replying account must follow the account that created the original post. We'll continue using the

-- single, merged pattern for clarity & compactness. Previously, we combined the posting & reply relationships into the pattern: `Account1-(Posted)->Post<-(IsReplyTo)-Reply<-(RepliedWith)-Account2`. Now, we introduce one more

-- base relationship: `Account2-(Follows)->Account1`. Applying the same pattern-merging rules as before, it fits naturally into our existing structure, giving us: 

-- `Account-(Posted)->Post<-(IsReplyTo)-Reply<-(RepliedWith)-Account2-(Follows)->Account1`. Because we've added the `Graph.Follows` edge to the pattern, we must also include its table in the FROM clause. Here's the complete

-- query:

SELECT Account1.accountname AS account1, Post.posttext,
	Account2.accountname AS account2, Reply.posttext AS replytext
FROM Graph.Account AS Account1, Graph.Posted, Graph.Post,
	Graph.Account AS Account2, Graph.Posted AS RepliedWith,
	Graph.Post AS Reply, Graph.IsReplyTo, Graph.Follows
WHERE MATCH(Account1-(Posted)->Post<-(IsReplyTo)-Reply<-(RepliedWith)-Account2-(Follows)->Account1)
ORDER BY Post.dt, Post.postid, Reply.dt;

-- Notice that `Account1` appears twice in the pattern. This is intentional & perfectly valid; it simply reflects its two different roles in the matching logic.



-- At this point, our pattern involves four base relationships. As the number of relationships grows, the advantage of using graph-based syntax becomes increasingly clear: the MATCH pattern allows us to express complex paths with 

-- much less code than traditional join-based T-SQL. For comparison, here is the equivalent solution written using join-based syntax (inner joins shown for simplicity):

SELECT Account1.accountname AS account1, Post.posttext,
	Account2.accountname AS account2, Reply.posttext AS replytext
FROM Graph.Account AS Account1
	INNER JOIN Graph.Posted
		ON Posted.$from_id = Account1.$node_id
	INNER JOIN Graph.Post
		ON Posted.$to_id = Post.$node_id
	INNER JOIN Graph.IsReplyTo
		ON IsReplyTo.$to_id = Post.$node_id
	INNER JOIN Graph.Post AS Reply
		ON IsReplyTo.$from_id = Reply.$node_id
	INNER JOIN Graph.Posted AS RepliedWith
		ON RepliedWith.$to_id = Reply.$node_id
	INNER JOIN Graph.Account AS Account2
		ON RepliedWith.$from_id = Account2.$node_id
	INNER JOIN Graph.Follows
		ON Follows.$from_id = Account2.$node_id
			AND Follows.$to_id = Account1.$node_id
ORDER BY Post.dt, Post.postid, Reply.dt;

-- While both queries produce the same results, the difference in expressiveness is clear. With the graph pattern `Account1-(Posted)->Post<-(IsReplyTo)-Reply<-(RepliedWith)-Account2-(Follows)->Account1`, we can almost read the

-- logic directly as English: "Account 1 posted a post. The reply is a reply to that post. Account 2 posted that reply. And Account 2 follows Account 1." By contrast, the join-based version is far harder to parse mentally, & 

-- doesn't translate naturally into plain language. One of SQL's original design goals was to provide declarative, English-like ways to express data requests. In many cases, graph syntax is a step closer to that goal than 

-- traditional joins.



-- Currently, T-SQL allows us to combine base match patterns only with AND logic. We can do so in several ways:

	-- 1. A single MATCH clause with multiple patterns separated by AND

	-- 2. Multiple MATCH clauses separated by AND

	-- 3. A single merged pattern

	-- 4. Any combination of the aforementioned techniques

-- SQL Server doesn't support applying OR or NOT directly to match patterns. To incorporate OR & NOT conditions in graph queries, we can take one of two approaches. One option is to use set operators like UNION instead of OR, &

-- EXCEPT instead of NOT. The other approach is to use subqueries with EXISTS or NOT EXISTS; this is often more concise & reads more naturally.



-- To express OR logic in SQL Graph, we can use set operators such as UNION. Each branch of the OR condition becomes its own query, & we combine the results with UNION. In our example, the first match pattern is 

-- `Account1-(Posted)->Post<-(IsReplyTo)-Reply<-(RepliedWith)-Account2-(Follows)->Account1`. This pattern represents the scenario where Account 1 posts something, & Account 2, who follows Account 1, replies to that post. The

-- second match pattern is `Account1-(Posted)->Post<-(IsReplyTo)-Reply<-(RepliedWith)-Account2-(IsFriendOf)->Account1`. This represents the similar scenario where Account 2, who is friends with Account 1, replies to Account 1's 

-- post. The only difference between the two queries is the type of relationship between Account 1 & Account 2 (`Follows` vs. `IsFriendOf`). Accordingly, the first query references the `Graph.Follows` edge table, while the second

-- references `Graph.IsFriendOf`. Here's the complete solution:

SELECT Account1.accountname AS account1, Post.posttext,
	Account2.accountname AS account2, Reply.posttext AS replytext
FROM Graph.Account AS Account1, Graph.Posted, Graph.Post,
	Graph.Account AS Account2, Graph.Posted AS RepliedWith,
	Graph.Post AS Reply, Graph.IsReplyTo, Graph.Follows
WHERE MATCH(Account1-(Posted)->Post<-(IsReplyTo)-Reply<-(RepliedWith)-Account2-(Follows)->Account1)

UNION

SELECT Account1.accountname AS account1, Post.posttext,
	Account2.accountname AS account2, Reply.posttext AS replytext
FROM Graph.Account AS Account1, Graph.Posted, Graph.Post,
	Graph.Account AS Account2, Graph.Posted AS RepliedWith,
	Graph.Post AS Reply, Graph.IsReplyTo, Graph.IsFriendOf
WHERE MATCH(Account1-(Posted)->Post<-(IsReplyTo)-Reply<-(RepliedWith)-Account2-(IsFriendOf)->Account1);

-- This works, but the duplication makes the code longer & harder to maintain.



-- Another way to implement OR logic is by using EXISTS predicates with correlated subqueries. In this approach, the outer query defines the portion of the MATCH pattern that both branches of the OR conditions share (in this 

-- example, Account 2 replying to Account 1). Then, for each relationship type we want to check, `Follows` or `IsFriendOf`, we introduce a separate EXISTS subquery & combine them with an OR operator. Each subquery specifies the

-- additional relationship pattern in its own WHERE clause:

SELECT Account1.accountname AS account1, Post.posttext,
	Account2.accountname AS account2, Reply.posttext AS replytext
FROM Graph.Account AS Account1, Graph.Posted, Graph.Post,
	Graph.Account AS Account2, Graph.Posted AS RepliedWith,
	Graph.Post as Reply, Graph.IsReplyTo
WHERE MATCH(Account1-(Posted)->Post<-(IsReplyTo)-Reply<-(RepliedWith)-Account2)
	AND (EXISTS (SELECT * FROM Graph.Follows
				 WHERE MATCH(Account2-(Follows)->Account1))
	OR EXISTS (SELECT * FROM Graph.IsFriendOf
			   WHERE MATCH(Account2-(IsFriendOf)->Account1)));

-- Notice how the subqueries reference `Account1` & `Account2` from the outer query. These correlated references ensure that each subquery checks the correct relationship between the same two accounts identified in the main

-- match pattern.



-- The previous examples showed how to work with OR logic. Handling NOT logic follows a similar approach. For instance, suppose we want to return posts & their direct replies only when the account that replied did not like the 

-- original post. Using a set-based solution, we can rely on the EXCEPT operator, as shown below:

SELECT Account1.accountname AS account1, Post.posttext,
	Account2.accountname AS account2, Reply.posttext AS replytext
FROM Graph.Account AS Account1, Graph.Posted, Graph.Post,
	Graph.Account AS Account2, Graph.Posted AS RepliedWith,
	Graph.Post as Reply, Graph.IsReplyTo
WHERE MATCH(Account1-(Posted)->Post<-(IsReplyTo)-Reply<-(RepliedWith)-Account2)

EXCEPT

SELECT Account1.accountname AS account1, Post.posttext,
	Account2.accountname AS account2, Reply.posttext AS replytext
FROM Graph.Account AS Account1, Graph.Posted, Graph.Post,
	Graph.Account AS Account2, Graph.Posted AS RepliedWith,
	Graph.Post AS Reply, Graph.IsReplyTo, Graph.Likes
WHERE MATCH(Account1-(Posted)->Post<-(IsReplyTo)-Reply<-(RepliedWith)-Account2-(Likes)->Post);

-- Alternatively, when using a solution based on predicates, we simply apply NOT EXISTS:

SELECT Account1.accountname AS account1, Post.posttext,
	Account2.accountname AS account2, Reply.posttext AS replytext
FROM Graph.Account AS Account1, Graph.Posted, Graph.Post,
	Graph.account AS Account2, Graph.Posted AS RepliedWith,
	Graph.Post AS Reply, Graph.IsReplyTo
WHERE MATCH(Account1-(Posted)->Post<-(IsReplyTo)-Reply<-(RepliedWith)-Account2)
	AND NOT EXISTS (SELECT * FROM Graph.Likes
					WHERE MATCH(Account2-(Likes)->Post));

-- In short, these techniques allow us to express OR & NOT logic using standard SQL operators, even though SQL Graph does not yet support these operations directly within or across match patterns.



--------------------------
-- Recursive Queries
--------------------------

-- Before SQL Graph was introduced in T-SQL, developers typically relied on recursive queries using recursive CTEs to work with graph structures stored in traditional relational tables. This approach was especially common when

-- handling graphs that require traversal over arbitrarily long paths. For example, we might need to return the subtree of posts beneath a given post, or retrieve th chain of ancestor posts leading to a given post. Although SQL

-- Graph provides native graph traversal capabilities, it does not currently support arbitrary-length path patterns in standard MATCH clauses. Such patterns are only supported when using the specialised SHORTEST_PATH option. As

-- a result, recursive queries & other iterative techniques remain common solutions for traversing graph structures stored in SQL Graph tables. In this section, we'll talk through how to query SQL Graph objects using recursive 

-- queries, including syntax limitations & practical workarounds.



-- A typical traversal task suitable for recursive queries is returning the full subgraph under a given input node. For instance, given a post ID stored in `@postid`, we want to return the input post as well as all of its

-- descendants: direct replies, replies to those replies, & so forth. For each post, we should return the parent post ID, the post ID, & the post text. If you're familiar with recursive CTEs but new to querying SQL Graph objects

-- with them, your first attempt may look like this (using the sample input post ID 13):

DECLARE @postid AS INT = 13;

WITH C AS (
	SELECT NULL AS parentpostid, postid, posttext
	FROM Graph.Post
	WHERE postid = @postid

	UNION ALL

	SELECT ParentPost.postid AS parentpostid,
		ChildPost.postid, ChildPost.posttext
	FROM C AS ParentPost, Graph.IsReplyTo, Graph.Post AS ChildPost
	WHERE MATCH(ChildPost-(IsReplyTo)->ParentPost)
)
SELECT parentpostid, postid, posttext
FROM C;

-- The anchor member returns the input post, using NULL for its parent ID because it serves as the root of the subgraph. The recursive member attempts to use a MATCH pattern (`ChildPost-(IsReplyTo)->ParentPost`) to find replies

-- to each post from the previous iteration (`C AS ParentPost`). However, as of now, the MATCH clause does not allow a recursive reference to a CTE in place of a graph object within the pattern. Running the query results in the

-- following error: "Cannot use a derived table 'ParentPost' in a MATCH clause."



-- At this point, many people abandon graph-based syntax in recursive queries, assuming it simply isn't supported. They usually switch to join-based logic & explicitly handle graph relationships in the join predicates. However,

-- there is a simple workaround that allows us to continue using MATCH patterns in the recursive member of a CTE. It does require adding an additional node table to the query, so there is a small performance cost. The key idea is

-- this: instead of treating the recursive reference to the CTE as a node table within the MATCH clause, we explicitly include the relevant node table in the query (in our case, `Graph.Post AS ParentPost`). We then correlate the

-- node table to the CTE using a standard predicate (`ParentPost.postid = C.postid`). Once that relationship is established, we are free to reference the alias of that node table (`ParentPost`) inside the MATCH pattern. Here is

-- the updated graph-based recursive query using this technique:

DECLARE @postid AS INT = 13;

WITH C AS (
	SELECT NULL AS parentpostid, postid, posttext
	FROM Graph.Post
	WHERE postid = @postid

	UNION ALL

	SELECT ParentPost.postid AS parentpostid,
		ChildPost.postid, ChildPost.posttext
	FROM C, Graph.Post AS ParentPost, Graph.IsReplyTo,
		Graph.Post AS ChildPost
	WHERE ParentPost.postid = C.postid
		AND MATCH(ChildPost-(IsReplyTo)->ParentPost)
)
SELECT parentpostid, postid, posttext
FROM C;

-- Alternatively, we can always rely on traditional join-based syntax. In this approach, we work directly with the internal graph ID columns (such as `$node_id`, `$from_id`, & `$to_id`), eliminating the need for the additional

-- proxy table:

DECLARE @postid AS INT = 13;

WITH C AS (
	SELECT $node_id AS nodeid, NULL AS parentpostid, postid, posttext
	FROM Graph.Post
	WHERE postid = @postid

	UNION ALL

	SELECT CP.$node_id AS nodeid, PP.postid AS parentpostid,
		CP.postid, CP.posttext
	FROM C AS PP
		INNER JOIN Graph.IsReplyTo AS R
			ON R.$to_id = PP.nodeid
		INNER JOIN Graph.Post AS CP
			ON R.$from_id = CP.$node_id
)
SELECT parentpostid, postid, posttext
FROM C;

-- The join-based approach has a small performance edge since it avoids the extra node table required by the MATCH workaround. On the other hand, the graph-based syntax is often more intuitive, more expressive, & less verbose.



--------------------------------------
-- Adding Sorting & Indentation
--------------------------------------

-- When we fetch a subtree from a graph (like a post & all of its replies), we usually want the results in topological order. That just means:

	-- A parent should appear before any of its descendants.

	-- If two nodes are siblings, & one comes before the other, then all of its children should also come before the sibling.

-- We also often want to indent each node according to its depth in the tree; so the root is not indented, its children are indented once, their children twice, & so on. This makes the structure easier to read. To make this work

-- in T-SQL using a recursive CTE, we add two helper columns:

	-- 1. `lvl`: the depth of the node

		-- The root node gets level 0, & each recursive step adds 1 to the parent's level.

	-- 2. `sortkey`: a string that lets us sort nodes in the correct topological order
		
		-- The root starts with `'.'`, & each child appends its post ID to its parent's `sortkey`. For example, consider post ID 1061. Its parent is post 1031, whose parent is post 449, whose parent is post 13, the root post in

		-- this example. Based on this chain, the code should produce the sort key `'.449.1031.1061.` for post 1061. Sorting by this string automatically puts parents before children & keeps siblings in the right order.

-- Finally, in the outer query, we:

	-- Sort the rows by `sortkey`

	-- Create indentation by repeating a small string (like `' . '`) `lvl` times

	-- Concatenate that indentation with the post's text

-- The result is a nicely ordered, readable, indented tree of posts:

DECLARE @postid AS INT = 13;

WITH C AS (
	SELECT NULL AS parentpostid, postid, posttext,
		0 AS lvl,
		CAST('.' AS VARCHAR(MAX)) AS sortkey
	FROM Graph.Post
	WHERE postid = @postid

	UNION ALL

	SELECT ParentPost.postid AS parentpostid,
		ChildPost.postid, ChildPost.posttext,
		C.lvl + 1 AS lvl,
		CONCAT(C.sortkey, ChildPost.postid, '.') AS sortkey
	FROM C, Graph.Post AS ParentPost, Graph.IsReplyTo,
		Graph.Post AS ChildPost
	WHERE ParentPost.postid = C.postid
		AND MATCH(ChildPost-(IsReplyTo)->ParentPost)
)
SELECT REPLICATE(' | ', lvl) + posttext AS post
FROM C
ORDER BY sortkey;



--------------------------------------
-- Using the SHORTEST_PATH Option
--------------------------------------

-- Finding the shortest path between two nodes is a common requirement when working with SQL graph. This could mean calculating the quickest route between locations on a map or, in our case, identifying the shortest friendship

-- or following connection between two accounts. Sometimes we want the absolute shortest path regardless of the number of hops. Other times, we may want to cap the number of hops allowed. T-SQL supports these scenarios using the

-- SHORTEST_PATH subclause within the MATCH clause. SHORTEST_PATH can be used to find the shortest path between a single source node & multiple target nodes, the shortest path between two specific nodes, or the shortest path 

-- between multiple sources & multiple targets. We'll start with a simple case: finding the shortest friendship paths between Orli & all of her direct & indirect friends. We already know how to identify direct friends with a 

-- basic match pattern:

SELECT Account1.accountname AS account1,
	Account2.accountname AS account2
FROM Graph.Account AS Account1, Graph.IsFriendOf,
	Graph.Account AS Account2
WHERE MATCH(Account1-(IsFriendOf)->Account2)
	AND Account1.accountname = N'Orli';



-- To include indirect relationships, we need an arbitrary-length match pattern. This is where SHORTEST_PATH is useful: `MATCH(SHORTEST_PATH(arbitrary_length_pattern))`. An arbitrary-length pattern builds on a simple match

-- pattern by dividing it into:

	-- 1. A part evaluated once (the starting node)

	-- 2. A part that repeats (the navigated edges/nodes)

-- In our example, the fixed part is `Account1`, & the repeated part is the friendship edge & "to node": `-(IsFriendOf)->Account2`. To express repetition, the repeating tables must be listed in the FROM clause with FOR PATH. The

-- repeating pattern appears in parentheses with the quantifier `+` for unlimited hops, or `{1, N}` to limit the number of hops to N.



-- To support the repeating portion of the pattern, we add the relevant tables to the FROM clause using FOR PATH, such as `Graph.IsFriendOf FOR PATH AS IFO` & `Graph.Account FOR PATH AS Account2`. In the match pattern, we then

-- express the repeated segment as `(-(IFO)->Account2)+`, where the `+` quantifier allows for any number of hops. The result is the arbitrary-length pattern `Account1(-(IFO)->Account2)+`, which we wrap in SHORTEST_PATH & place

-- within the MATCH predicate:

	-- `MATCH(SHORTEST_PATH(Account1(-(IFO)->Account2)+))`

-- Finally, we filter for Orli as the starting node using an additional predicate in the WHERE clause. At this point, we have the query's FROM & WHERE clauses figured out:

	-- `FROM Graph.Account AS Account2,
	--		Graph.IsFriendOf FOR PATH AS IFO,
	--		Graph.Account FOR PATH AS Account2
	--  WHERE MATCH(SHORTEST_PATH(Account1(-(IFO)->Account2)+))
	--		AND Account1.accountname = N'Orli'



-- In shortest-path queries, values from tables in the repeating part of the pattern are returned as ordered collections rather than single scalar values. For example, one result path might be Orli->Tami->Miko->Omer where,

-- as shown in the table below, column `Account1.accountname` stores singular values & column `Account2.accountname` stores collections of values. Because `Account2.accountname` represents multiple values, we cannot select it

-- directly.

-- | Account1.accountname | Account2.accountname |
-- | -------------------- | -------------------- |
-- |                      | Tami                 |
-- |                      | -------------------- |
-- | Orli                 | Miko                 |
-- |                      | -------------------- |
-- |                      | Omer                 |
-- | -------------------- | -------------------- |

SELECT Account1.accountname, Account2.accountname
FROM Graph.Account AS Account1,
	Graph.IsFriendOf FOR PATH AS IFO,
	Graph.Account FOR PATH AS Account2
WHERE MATCH(SHORTEST_PATH(Account1(-(IFO)->Account2)+))
	AND Account1.accountname = N'Orli';

-- The reference to `Account2.accountname` is invalid, since the column value in each result row represents a collection. We get an error: "The alias or identifier 'Account2.accountname' cannot be used in the select list, order

-- by, group by, or having context." T-SQL instead requires the use of graph path aggregate functions, such as STRING_AGG, LAST_VALUE, SUM, COUNT, AVG, MIN, or MAX, & these functions must include the expression

-- `WITHIN GROUP (GRAPH PATH)`.



-- As an example, to form a character string-based path with the names of the accounts in the shortest friendship paths in our query, we can use the expression:

	-- `Account1.accountname + N'->' + STRING_AGG(Account2.accountname, N'->') WITHIN GROUP(GRAPH PATH)`.

-- We begin with `Account1.accountname`, then insert the separator `'->'` & append the aggregated list of `Account2.accountname` values using STRING_AGG, again with the `'->'` separator. Putting it all together, the query 

-- becomes:

SELECT Account1.accountname + N'->' + STRING_AGG(Account2.accountname, N'->')
	WITHIN GROUP(GRAPH PATH) AS friendships
FROM Graph.Account AS Account1,
	Graph.IsFriendOf FOR PATH AS IFO,
	Graph.Account FOR PATH AS Account2
WHERE MATCH(SHORTEST_PATH(Account1(-(IFO)->Account2)+))
	AND Account1.accountname = N'Orli';

-- You'll notice that the result may include paths where the first & last nodes are the same; we'll address filtering those out shortly. Finally, note that when multiple shortest paths exist, the arbitrary-length match pattern

-- may return any one of them. At present, there's no way to control which shortest path is selected.



-- In the previous query, we used the `+` quantifier to allow any number of hops in the shortest path. Alternatively, we can limit the number of hops by using the `{1, N}` quantifier, where N specifies the maximum number of

-- allowed hops. For example, the following version of the query restricts the shortest paths to at most two hops:

SELECT Account1.accountname + N'->' + STRING_AGG(Account2.accountname, N'->')
	WITHIN GROUP(GRAPH PATH) AS friendships
FROM Graph.Account AS Account1,
	Graph.IsFriendOf FOR PATH AS IFO,
	Graph.Account FOR PATH AS Account2
WHERE MATCH(SHORTEST_PATH(Account1(-(IFO)->Account2){1, 2}))
	AND Account1.accountname = N'Orli';



-- Note that arbitrary-length patterns don't need to start with the portion considered only once & then continue with the portion that repeats. For example, suppose that instead of returning from Orli, we now need to return the 

-- shortest paths to Orli. To accomplish this, we'll make a few adjustments to the earlier query that found all paths starting from Orli. One of these adjustments is to define an arbitrary-length pattern in which the repeating

-- portion comes first, `(Account1-(IFO)->)+`, followed by the non-repeating portion `Account2`, resulting in the pattern `(Account1-(IFO)->)+Account2`. In addition, we'll filter on `Account2.accountname = N'Orli'` in the WHERE

-- clause. We'll discuss the remaining modifications in the following paragraphs.



-- When using a pattern where the repeating portion comes first, the returned collection appears in what could be viewed as the reverse of the logical path direction. In this example, `Account2.accountname` holds the single

-- end node value Orli, while `Account1.accountname` contains the collection values (Tami, Miko, Alma, Stav), in that specific order. This makes intuitive sense from a physical execution standpoint: processing begins with the 

-- singular end node & then traverses backward along the path towards its beginning. That traversal likely explains the order in which the collection elements are returned.



-- To construct a readable character-based representation of the path, we can start with `Account2.accountname`, then concatenate a left-arrow (`'<-'`) separator, & finally concatenate the string produced by

-- `STRING_AGG(Account1.accountname, N'<-') WITHIN GROUP (GRAPH PATH)`. Here's the full query:

SELECT Account2.accountname + N'<-' + STRING_AGG(Account1.accountname, N'<-')
	WITHIN GROUP(GRAPH PATH) AS friendships
FROM Graph.Account FOR PATH AS Account1,
	Graph.IsFriendOf FOR PATH AS IFO,
	Graph.Account AS Account2
WHERE MATCH(SHORTEST_PATH((Account1-(IFO)->)+Account2))
	AND Account2.accountname = N'Orli';

-- Currently, SQL Server does not support specifying a descending graph path order direction.



-- Our next task is to return the shortest path between two specific nodes, for example, the shortest friendship path between Orli & Stav. To begin, we can check whether they are directly connected. The following query uses a 

-- simple match pattern along with two straightforward filter predicates for their account names:

SELECT Account1.accountname AS account1,
	Account2.accountname AS account2
FROM Graph.Account AS Account1, Graph.IsFriendOf,
	Graph.Account AS Account2
WHERE MATCH(Account1-(IsFriendOf)->Account2)
	AND Account1.accountname = N'Orli'
	AND Account2.accountname = N'Stav';

-- Orli & Stav are not direct friends, so this query returns no rows. To continue, we'll modify the query to incorporate the SHORTEST_PATH option. As a starting point, we can reuse the query that found the shortest path between

-- Orli & her direct or indirect friends using the arbitrary-length pattern `Account1(-(IFO)->Account2)+`. In that version, we filtered on `Account1.accountname = N'Orli'`. It may seem natural to simply add another predicate for

-- `Account2.accountname = N'Stav'`, as shown below:

SELECT Account1.accountname + N'->' + STRING_AGG(Account2.accountname, N'->')
	WITHIN GROUP(GRAPH PATH) AS friendships
FROM Graph.Account AS Account1,
	Graph.IsFriendOf FOR PATH AS IFO,
	Graph.Account FOR PATH AS Account2
WHERE MATCH(SHORTEST_PATH(Account1(-(IFO)->Account2)+))
	AND Account1.accountname = N'Orli'
	AND Account2.accountname = N'Stav';

-- Unfortunately, this approach fails because `Account2.accountname` represents a collection of values along the path, not a single value. Attempting to use it directly in a filtering context results in the error: "The alias or 

-- identifier 'Account2.accountname' cannot be used in the select list, order by, group by, or having context." What we actually need is the final account name in that collection, the end of the path. We can extract that value 

-- using the LAST_VALUE function with `WITHIN GROUP (GRAPH PATH)`. We compute it in the SELECT list, assign an alias `lastnode`, & filter on it in an outer query. We continue to filter the starting node 

-- (`Account1.accountname = N'Orli'`) inside the SHORTEST_PATH query. Here's the complete solution:

WITH C AS (
	SELECT Account1.accountname + N'->' + STRING_AGG(Account2.accountname, N'->') WITHIN GROUP(GRAPH PATH) AS friendships,
		LAST_Value(Account2.accountname) WITHIN GROUP (GRAPH PATH) AS lastnode
	FROM Graph.Account AS Account1,
		Graph.IsFriendOf FOR PATH AS IFO,
		Graph.Account FOR PATH AS Account2
	WHERE MATCH(SHORTEST_PATH(Account1(-(IFO)->Account2)+))
		AND Account1.accountname = N'Orli'
)
SELECT friendships
FROM C
WHERE lastnode = N'Stav';

-- This query confirms that a valid friendship path exists between Orli & Stav.



-- Returning to the task of retrieving all paths that lead to Orli, & ensuring that the path is returned in the proper graph order rather than the reversed order, we can accomplish this with a small modification to the previous

-- query. Instead of filtering on `Account1.accountname` inside the SHORTEST_PATH query, we remove that predicate entirely & apply the filter in the outer query by checking where `lastnode = N'Orli'`, as shown below:

WITH C AS (
	SELECT Account1.accountname + N'->' + STRING_AGG(Account2.accountname, N'->') WITHIN GROUP(GRAPH PATH) AS friendships,
		LAST_VALUE(Account2.accountname) WITHIN GROUP (GRAPH PATH) AS lastnode
	FROM Graph.Account AS Account1,
		Graph.IsFriendOf FOR PATH AS IFO,
		Graph.Account FOR PATH AS Account2
	WHERE MATCH(SHORTEST_PATH(Account1(-(IFO)->Account2)+))
)
SELECT friendships
FROM C
WHERE lastnode = N'Orli';



-- To return the shortest paths between multiple source nodes & multiple target nodes, for example, all shortest friendship paths among every account, we simply remove both account name filter predicates. Since we no longer need

-- to reference or filter by the last node in the path, the CTE is unnecessary. The final query looks like this:

SELECT Account1.accountname + N'->' + STRING_AGG(Account2.accountname, N'->')
	WITHIN GROUP(GRAPH PATH) AS friendships
FROM Graph.Account AS Account1,
	Graph.IsFriendOf FOR PATH AS IFO,
	Graph.Account FOR PATH AS Account2
WHERE MATCH(SHORTEST_PATH(Account1(-(IFO)->Account2)+));



-- We are now very close to addressing a classic graph-theory task, returning the transitive closure of a graph. The transitive closure of an input graph G is a graph TC that contains a pair of nodes for every source-target pair

-- in G that is connected by a path, either direct or indirect. In our case, the transitive closure of the friendships graph contains all account pairs where some friendship path exists between them. We can accomplish this using

-- our multi-source/multi-target shortest-paths approach. We simply return the first & last nodes of each shortest path, as shown below:

SELECT Account1.accountname AS firstnode,
	LAST_VALUE(Account2.accountname)
		WITHIN GROUP (GRAPH PATH) AS lastnode
FROM Graph.Account AS Account1,
	Graph.IsFriendOf FOR PATH AS IFO,
	Graph.Account FOR PATH AS Account2
WHERE MATCH(SHORTEST_PATH(Account1(-(IFO)->Account2)+));

-- This output includes self-pairs (e.g., (Inka, Inka)) as well as mirrored pairs such as (Inka, Miko) & (Miko, Inka). To remove these & keep only distinct pairs, we can filter to where `firstnode < lastnode`. Because this filter

-- must reference the computed aliases `firstnode` & `lastnode`, we wrap the query in a table expression (such as a CTE). If we also want to report the number of hops in each shortest path, we can use COUNT with `WITHIN GROUP

-- (GRAPH PATH)`. The complete solution, including filtering & hop counting, is shown here:

WITH C AS (
	SELECT Account1.accountname AS firstnode,
		COUNT(Account2.accountid) WITHIN GROUP (GRAPH PATH) AS hops,
		LAST_VALUE(Account2.accountname) WITHIN GROUP (GRAPH PATH) AS lastnode
	FROM Graph.Account AS Account1,
		Graph.IsFriendOf FOR PATH AS IFO,
		Graph.Account FOR PATH AS Account2
	WHERE MATCH(SHORTEST_PATH(Account1(-(IFO)->Account2)+))
)
SELECT firstnode AS account1, lastnode AS account2, hops
FROM C
WHERE firstnode < lastnode;



-------------------------------------
-- Using the LAST_NODE Function
-------------------------------------

-- The LAST_NODE function is designed to support chaining multiple arbitrary-length patterns together. It is used within the SHORTEST_PATH option & applied to a node table reference to represent the last node of the shortest path

-- found so far. By doing so, we can connect the endpoint of one shortest path to the start of another, effectively allowing us to chain shortest paths at their endpoints. For example, suppose we need to identify the shortest

-- friendship chain from Orli to Yatzek via Stav, ensuring that neither Orli nor Yatzek appear as intermediate accounts in the path. This scenario requires two shortest paths:

	-- 1. A shortest path from Orli to Stav (without Yatzek as an intermediary).

	-- 2. A shortest path from Stav to Yatzek (without Orli as an intermediary).

-- To express this pattern, we reference `Graph.Account` three times:

	-- `Account1`: a singular node that serves as the starting point of the first shortest path

	-- `Account2`: a "for path" collection representing the continuation & endpoint of the first shortest path

	-- `Account3`: a "for path" collection representing the continuation & endpoint of the second shortest path

-- To enforce the "no Orli/Yatzek in the middle" rule, we wrap `Account2` in a derived table that excludes Yatzek, & wrap `Account3` in a derived table that excludes Orli. We also reference `Graph.IsFriendOf` twice, `IFO1` for

-- connecting `Account1` to `Account2`, & `IFO2` for connecting `Account2` to `Account3`. The arbitrary-length patterns are:

	-- First path: `Account1(-(IFO)->Account2)+`

	-- Second path, starting where the first one ends: `LAST_NODE(Account2)(-(IFO2)->Account3)+`

-- Both patterns are included inside SHORTEST_PATH, combined with AND. As before, we use a CTE so that we can filter based on computed values. We apply the starting-point filter (`Account1.accountname = N'Orli'`) inside the inner

-- query. We then use LAST_VALUE to extract:

	-- `midnode`: the last node in the first shortest path

	-- `lastnode`: the last node in the second shortest path

-- Finally, the outer query filters the row where `midnode = N'Stav'` & `lastnode = N'Yatzek'`. Here is the complete solution:

WITH C AS (
	SELECT Account1.accountname + N'->' 
		+ STRING_AGG(Account2.accountname, N'->') 
			WITHIN GROUP (GRAPH PATH) + N'->'
		+ STRING_AGG(Account3.accountname, N'->')
			WITHIN GROUP (GRAPH PATH) AS friendships,
		LAST_VALUE(Account2.accountname)
			WITHIN GROUP (GRAPH PATH) AS midnode,
		LAST_VALUE(Account3.accountname)
			WITHIN GROUP (GRAPH PATH) AS lastnode
	FROM Graph.Account AS Account1,
		(SELECT * FROM Graph.Account
		 WHERE accountname <> N'Yatzek') FOR PATH AS Account2,
		(SELECT * FROM Graph.Account
		 WHERE accountname <> N'Orli') FOR PATH AS Account3,
		Graph.IsFriendOf FOR PATH AS IFO1,
		Graph.IsFriendOf FOR PATH AS IFO2
	WHERE MATCH(SHORTEST_PATH(Account1(-(IFO1)->Account2)+)
			    AND SHORTEST_PATH(LAST_NODE(Account2)(-(IFO2)->Account3)+))
		AND Account1.accountname = N'Orli'
)
SELECT friendships
FROM C
WHERE midnode = N'Stav'
	AND lastnode = N'Yatzek';

-- This result confirms that there exists a valid shortest path from Orli to Yatzek through Stav, while ensuring that neither Orli nor Yatzek appear as intermediate nodes.



-- Now imagine we want to return all accounts that connect Orli & Yatzek, without either of them appearing as intermediates, as well as the shortest path that links them through that connecting account. This time, the connecting

-- account does not have to be Stav specifically. In other words:

	-- The connecting account must be the endpoint of the shortest path starting at Orli (with Yatzek excluded as an intermediary).

	-- The same account must be the starting point of the shortest path ending at Yatzek (with Orli excluded as an intermediary).

-- To implement this, we can start from the previous query. We simply remove the filter on `midnode` in the outer query & add a condition ensuring that the connecting account (`midnode`) is different from both the first & last

-- nodes. The complete solution is shown below:

WITH C AS (
	SELECT Account1.accountname AS firstnode,
		Account1.accountname + N'->'
			+ STRING_AGG(Account2.accountname, N'->')
				WITHIN GROUP (GRAPH PATH) + N'->'
			+ STRING_AGG(Account3.accountname, N'->')
				WITHIN GROUP (GRAPH PATH) AS friendships,
		LAST_VALUE(Account2.accountname)
			WITHIN GROUP (GRAPH PATH) AS midnode,
		LAST_VALUE(Account3.accountname)
			WITHIN GROUP (GRAPH PATH) AS lastnode
	FROM Graph.Account AS Account1,
		(SELECT * FROM Graph.Account
		 WHERE accountname <> N'Yatzek') FOR PATH AS Account2,
		(SELECT * FROM Graph.Account
		 WHERE accountname <> N'Orli') FOR PATH AS Account3,
		Graph.IsFriendOf FOR PATH AS IFO1,
		Graph.IsFriendOf FOR PATH AS IFO2
	WHERE MATCH(SHORTEST_PATH(Account1(-(IFO1)->Account2)+)
				AND SHORTEST_PATH(LAST_NODE(Account2)(-(IFO2)->Account3)+))
		AND Account1.accountname = N'Orli'
)
SELECT friendships, midnode
FROM C
WHERE lastnode = N'Yatzek'
	AND midnode NOT IN (firstnode, lastnode);

-- This query returns all valid connecting accounts along with the shortest path that links Orli & Yatzek through them.



-- Let's move on to chaining shortest paths as their endpoints. Suppose we want to pair shortest paths where one begins with Orli, the other begins with Yatzek, & both end at the same account. Additionally, neither Orli nor 

-- Yatzek can appear as intermediaries in either path. The following query solves this requirement:

WITH C AS (
	SELECT Account1.accountname AS firstnode1,
		Account1.accountname + N'->'
			+ STRING_AGG(Account2.accountname, N'->')
				WITHIN GROUP (GRAPH PATH) + N'<-'
			+ STRING_AGG(Account3.accountname, N'<-')
				WITHIN GROUP (GRAPH PATH) AS friendships,
		LAST_VALUE(Account2.accountname)
			WITHIN GROUP (GRAPH PATH) AS midnode,
		LAST_VALUE(Account3.accountname)
			WITHIN GROUP (GRAPH PATH) AS firstnode2
	FROM Graph.Account AS Account1,
		(SELECT * FROM Graph.Account
		 WHERE accountname <> N'Yatzek') FOR PATH AS Account2,
		(SELECT * FROM Graph.Account
		 WHERE accountname <> N'Orli') FOR PATH AS Account3,
		Graph.IsFriendOf FOR PATH AS IFO1,
		Graph.IsFriendOf FOR PATH AS IFO2
	WHERE MATCH(SHORTEST_PATH(Account1(-(IFO1)->Account2)+)
				AND SHORTEST_PATH((Account3-(IFO2)->)+LAST_NODE(Account2)))
		AND Account1.accountname = N'Orli'
)
SELECT friendships, midnode
FROM C
WHERE firstnode2 = N'Yatzek'
	AND midnode NOT IN (firstnode1, firstnode2);

-- Notice how `LAST_NODE(Account2)` is used here to end the second arbitrary-length pattern, rather than start it as in earlier examples. Also note the use of a left-arrow separator (`'<-'`) to reflect the direction of the second

-- path. Applying `LAST_VALUE` to `Account3.accountname` returns the first node in that second path, because it is the final node visited by the arbitrary-length traversal. 



-- This output appears similar to earlier results, differing mainly in the arrow direction of the second path. That's because a friendship relationship is undirected. If Buzi is friends with Alma, then Alma is also friends with 

-- Buzi. Therefore, chaining two shortest paths where the end of one is the beginning of the other is effectively equivalent to chaining two shortest paths that simply end at the same node, but only when the graph is undirected. 



-- In contrast, applying these solutions to a directed graph (a digraph), like a `Follows` relationship instead of friendship, will produce different interpretations & potentially different results.



-- Here is a version of the solution that applies to a directed `Follows` relationship, returning the shortest directed paths from Orli to an intermediate account & onward to Yatzek, again ensuring neither Orli nor Yatzek appear

-- as intermediaries:

WITH C AS (
	SELECT Account1.accountname AS firstnode,
		Account1.accountname + N'->'
			+ STRING_AGG(Account2.accountname, N'->')
				WITHIN GROUP (GRAPH PATH) + N'->'
			+ STRING_AGG(Account3.accountname, N'->')
				WITHIN GROUP (GRAPH PATH) AS followings,
		LAST_VALUE(Account2.accountname)
			WITHIN GROUP (GRAPH PATH) AS midnode,
		LAST_VALUE(Account3.accountname)
			WITHIN GROUP (GRAPH PATH) AS lastnode
	FROM Graph.Account AS Account1,
		(SELECT * FROM Graph.Account
		 WHERE accountname <> N'Yatzek') FOR PATH AS Account2,
		(SELECT * FROM Graph.Account
		 WHERE accountname <> N'Orli') FOR PATH AS Account3,
		Graph.Follows FOR PATH AS Follows1,
		Graph.Follows FOR PATH AS Follows2
	WHERE MATCH(SHORTEST_PATH(Account1(-(Follows1)->Account2)+)
				AND SHORTEST_PATH(LAST_NODE(Account2)(-(Follows2)->Account3)+))
		AND Account1.accountname = N'Orli'
)
SELECT followings, midnode
FROM C
WHERE lastnode = N'Yatzek'
	AND midnode NOT IN (firstnode, lastnode);

-- Here is the directed-graph equivalent of the earlier chaining approach, pairing paths that start from Orli & Yatzek respectively, both ending at the same target account:

WITH C AS (
	SELECT Account1.accountname AS firstnode1,
		Account1.accountname + N'->'
			+ STRING_AGG(Account2.accountname, N'->')
				WITHIN GROUP (GRAPH PATH) + N'<-'
			+ STRING_AGG(Account3.accountname, N'<-')
				WITHIN GROUP (GRAPH PATH) AS followings,
		LAST_VALUE(Account2.accountname)
			WITHIN GROUP (GRAPH PATH) AS midnode,
		LAST_VALUE(Account3.accountname)
			WITHIN GROUP (GRAPH PATH) AS firstnode2
	FROM Graph.Account AS Account1,
		(SELECT * FROM Graph.Account
		 WHERE accountname <> N'Yatzek') FOR PATH AS Account2,
		(SELECT * FROM Graph.Account
		 WHERE accountname <> N'Orli') FOR PATH AS Account3,
		Graph.Follows FOR PATH AS Follows1,
		Graph.Follows FOR PATH AS Follows2
	WHERE MATCH(SHORTEST_PATH(Account1(-(Follows1)->Account2)+)
				AND SHORTEST_PATH((Account3-(Follows2)->)+LAST_NODE(Account2)))
		AND Account1.accountname = N'Orli'
)
SELECT followings, midnode
FROM C
WHERE firstnode2 = N'Yatzek'
	AND midnode NOT IN (firstnode1, firstnode2);



-- Suppose we want to return pairs of shortest friendship & follow chains that both start & end with the same accounts, while showing their node sequences from left to right. To achieve this, T-SQL lets us compare results from

-- two LAST_NODE function calls directly, as shown below:

SELECT Account1.accountname + N'->' + STRING_AGG(Account2.accountname, N'->') WITHIN GROUP (GRAPH PATH) AS friendships,
	Account1.accountname + N'->' + STRING_AGG(Account3.accountname, N'->') WITHIN GROUP (GRAPH PATH) AS follows,
	Account1.accountname AS firstnode
FROM Graph.Account AS Account1,
	Graph.Account FOR PATH AS Account2,
	Graph.Account FOR PATH AS Account3,
	Graph.IsFriendOf FOR PATH AS IFO,
	Graph.Follows FOR PATH AS FLO
WHERE MATCH(SHORTEST_PATH(Account1(-(IFO)->Account2)+)
		    AND SHORTEST_PATH(Account1(-(FLO)->Account3)+)
			AND LAST_NODE(Account2) = LAST_NODE(Account3));

-- Because both arbitrary-length patterns begin with `Account1`, we don't need an additional filter to ensure their starting accounts match. We can achieve the same result without using LAST_NODE by instead calling LAST_VALUE to

-- extract the final account name in each path, & then filtering only those pairs where both final nodes match. As before, a CTE helps apply the filtering after path evaluation. Here's the full alternative solution:

WITH C AS (
	SELECT Account1.accountname + N'->' + STRING_AGG(Account2.accountname, N'->') WITHIN GROUP (GRAPH PATH) AS friendships,
		Account1.accountname + N'->' + STRING_AGG(Account3.accountname, N'->') WITHIN GROUP (GRAPH PATH) AS followings,
		Account1.accountname AS firstnode,
		LAST_VALUE(Account2.accountname)
			WITHIN GROUP (GRAPH PATH) AS lastnode1,
		LAST_VALUE(Account3.accountname)
			WITHIN GROUP (GRAPH PATH) AS lastnode2
	FROM Graph.Account AS Account1,
		Graph.Account FOR PATH AS Account2,
		Graph.Account FOR PATH AS Account3,
		Graph.IsFriendOf FOR PATH AS IFO,
		Graph.Follows FOR PATH AS FLO
	WHERE MATCH(SHORTEST_PATH(Account1(-(IFO)->Account2)+)
				AND SHORTEST_PATH(Account1(-(FLO)->Account3)+))
)
SELECT friendships, followings
FROM C
WHERE lastnode1 = lastnode2;
