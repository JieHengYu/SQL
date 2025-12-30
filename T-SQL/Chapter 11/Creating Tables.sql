-----------------------

-- Creating Tables

-----------------------

-- The following examples entertain a fictitious social network scenario. We'll begin by describing the entities in the system & the ways they interact. Then, we'll look at how to design & implement the data model using both

-- traditional relational modeling & graph-based modeling.



-- Our social network includes three entities:

	-- Accounts: Personal or company accounts, each having an ID, a name, a join date, & a reputation score.

	-- Posts: Status messages or news updates authored by a single account. Each post contains an ID, a posting date & time, & the post text.

	-- Publications: Books, articles, or blog posts that may have one or more authors. Each publication has an ID, a publication date, & a title. (For simplicity, we won't include additional metadata such as publisher & ISBN.)



-- These entities interact in several ways:

	-- Two accounts can become friends, forming a bidirectional relationship. One account sends a friend request & the other confirms. Once the friendship is established, we record the friendship start date & both accounts gain 
	
		-- access to features available only to friends.

	-- One account can follow another account to receive updates, forming a unidirectional relationship. Account A can follow Account B without being followed back. We record the follower, the followee, as well as the start date 
	
		-- of the follow relationship.

	-- Each post is created by exactly one account.

	-- A post may reference a parent post, forming a reply chain.

	-- An account can like a post, in which we need to record the date & time of the like.

	-- A publication may be authored by one or more accounts.



-- To clearly distinguish the traditional relational model from the graph model, we'll place each set of tables in its own schema. The `Norm` schema will contain the relational version of the design, & the `Graph` schema will

-- contain the graph-node & graph-edge tables. Run the following code to create the schemas in the `TSQLV6` sample database:

USE TSQLV6;

GO
CREATE SCHEMA Norm; -- schema for traditional modeling
GO
CREATE SCHEMA Graph; -- schema for graph modeling



-----------------------------
-- Traditional Modeling
-----------------------------

-- The diagram "Traditional Data Model.png" shows a proposed relational design for our fictitious social network. It illustrates the core tables, their columns, primary keys, & foreign key relationships.



-- The model is largely straightforward, but a few design choices are worth calling out, especially because they differ from how graph modeling handles the same concepts:

	-- 1. A recurring debate in data modeling is whether table names should be singular or plural. In relational theory, a table represents a relation, & the body of a relation is a set of tuples/rows. Because a table contains

		-- many rows, using plural table names (e.g., `Accounts`, `Posts`, `Publications`) is a reasonable & common convention in traditional modeling.

	-- 2. Friendships are naturally commutative: If account A is friends with account B, then account B is also friends with account A. In the traditional relational design, the `Friendships` table stores one row per friendship 
	
		-- pair. However, if we simply store two foreign keys (e.g., `accountid1` & `accountid2`), there is nothing preventing someone from inserting both (71, 379) & (379, 71), which would be redundant. A common pattern to avoid 
		
		-- this duplication is:

			-- Always store the smaller account ID in `accountid1`

			-- Always store the larger account ID in `accountid2`

		-- We can enforce this behaviour with a check constraint, e.g.: `CHECK (accountid1 < accountid2)` ensuring a unique, consistent representation of each friendship.

	-- 3. Contrary to a friendship relationship, following isn't commutative. Account A can follow account B without being followed back. If they do follow each other, it could be that account A followed account B at a different

		-- date than when account B followed account A. Because the relationships has clear directionality, each follower-followee pair is stored as a separate row in the `Followings` table, along with the follow date, without

		-- any ordering constraint. Here, `accountid1` represents the follower, & `accountid2` represents the followee.

	-- 4. A post is created by exactly one account, so it's stored as `Posts.accountid` with a foreign key referencing `Accounts.accountid`. A post may also reply to another post, which we can implement with a nullable 

		-- `parentpostid` column & a self-referencing foreign key. Since each post belongs to exactly one author & has at most one parent, no separate relationship table is needed for authorship or reply threading.

	-- 5. Unlike posts, publications may have multiple authors. This creates a many-to-many relationship between `Accounts` & `Publications`. The traditional relational design uses a junction table 
	
		-- `Norm.AuthorsPublications(accountid, pubid)`. Each row represents one author-publication pair.



-- The traditional model results in seven relational tables:

	-- `Accounts`

	-- `Posts`

	-- `Publications`

	-- `Friendships`

	-- `Followings`

	-- `Likes`

	-- `AuthorsPublications`

-- Each table uses standard relational constructs:

	-- Primary keys to enforce entity identity

	-- Foreign keys to maintain referential integrity

	-- A check constraint to enforce the commutativity rule in friendships

	-- Default constraints for timestamp fields

-- The following SQL script creates & populates all the tables in the `Norm` schema:

CREATE TABLE Norm.Accounts (
	accountid        INT          NOT NULL,
	accountname      NVARCHAR(50) NOT NULL,
	joindate         DATE         NOT NULL
		CONSTRAINT DFT_Accounts_joindate DEFAULT(SYSDATETIME()),
	reputationpoints INT          NOT NULL
		CONSTRAINT DFT_Accounts_reputationpoints DEFAULT(0),
		CONSTRAINT PK_Accounts PRIMARY KEY(accountid)
);

INSERT INTO Norm.Accounts (accountid, accountname, joindate, reputationpoints) 
VALUES (641, N'Inka', '20200801', 5),
	   (71, N'Miko', '20210514', 8),
	   (379, N'Tami', '20211003', 5),
	   (421, N'Buzi', '20210517', 8),
	   (661, N'Alma', '20210119', 13),
	   (2, N'Orli', '20220202', 2),
	   (941, N'Stav', '20220105', 1),
	   (953, N'Omer', '20220315', 0),
	   (727, N'Mitzi', '20200714', 3),
	   (883, N'Yatzek', '20210217', 3),
	   (199, N'Lilach', '20220112', 1);

CREATE TABLE Norm.Posts (
	postid       INT            NOT NULL,
	parentpostid INT            NULL,
	accountid    INT            NOT NULL,
	dt           DATETIME2(0)   NOT NULL
		CONSTRAINT DFT_Posts_dt DEFAULT(SYSDATETIME()),
	posttext     NVARCHAR(1000) NOT NULL,
	CONSTRAINT PK_Posts PRIMARY KEY(postid),
	CONSTRAINT FK_Posts_Accounts FOREIGN KEY(accountid)
		REFERENCES Norm.Accounts(accountid),
	CONSTRAINT FK_Posts_Posts FOREIGN KEY(parentpostid)
		REFERENCES Norm.Posts(postid)
);

INSERT INTO Norm.Posts (postid, parentpostid, accountid, dt, posttext) 
VALUES (13, NULL, 727, '20200921 13:09:46', N'Got a new kitten. Any suggestions for a name?'),
	   (109, NULL, 71, '20210515 17:00:00', N'Starting to hike the PCT today. Wish me luck!'),
	   (113, NULL, 421, '20210517 10:21:33', N'Buzi here. This is my first post.'),
	   (149, NULL, 421, '20210519 14:05:45', N'Buzi here. This is my second post.' + N' Aren''t my posts exciting?'),
	   (179, NULL, 421, '20210520 09:12:17', N'Buzi here. Guess what; this is my third post!'),
	   (199, NULL, 71, '20210802 15:56:02', N'Made it to Oregon!'),
	   (239, NULL, 883, '20220219 09:31:23', N'I''m thinking of growing a mustache,' + N' but am worried about milk drinking...'),
	   (281, NULL, 953, '20220318 08:14:24', N'Burt Shavits: "A good day is when no one shows up' + N' and you don''t have to go anywhere."'),
	   (449, 13, 641, '20200921 13:10:30', N'Maybe Pickle?'),
	   (677, 13, 883, '20200921 13:12:22', N'Ambrosius?'),
	   (857, 109, 883, '20210515 17:02:13', N'Break a leg. I mean, don''t!'),
	   (859, 109, 379, '20210515 17:04:21', N'The longest I''ve seen you hike was...' + N'wait, I''ve never seen you hike ;)'),
	   (883, 109, 199, '20210515 17:23:43', N'Ha ha ha!'),
	   (1021, 449, 2, '20200921 13:44:17', N'It does look a bit sour faced :)'),
	   (1031, 449, 379, '20200921 14:02:03', N'How about Gherkin?'),
	   (1051, 883, 71, '20210515 17:24:35', N'Jokes aside, is 95lbs reasonable for my backpack?'),
	   (1061, 1031, 727, '20200921 14:07:51', N'I love Gherkin!'),
	   (1151, 1051, 379, '20210515 18:40:12', N'Short answer, no! Long answer, nooooooo!!!'),
	   (1153, 1051, 883, '20210515 18:47:17', N'Say what!?'),
	   (1187, 1061, 641, '20200921 14:07:52', N'So you don''t like Pickle!? I''M UNFRIENDING YOU!!!'),
	   (1259, 1151, 71, '20210515 19:05:54', N'Did I say that was without water?');

CREATE TABLE Norm.Publications (
	pubid   INT				NOT NULL,
	pubdate DATE			NOT NULL,
	title   NVARCHAR(100)	NOT NULL,
	CONSTRAINT PK_Publications PRIMARY KEY(pubid)
);

INSERT INTO Norm.Publications (pubid, pubdate, title) 
VALUES (23977, '20200912' , N'When Mitzi met Inka'),
	   (4967, '20210304', N'When Mitzi left Inka'),
	   (27059, '20210401', N'It''s actually Inka who left Mitzi'),
	   (14563, '20210802', N'Been everywhere, seen it all; there''s no place like home!'),
	   (46601, '20220119', N'Love at first second');

CREATE TABLE Norm.Friendships (
	accountid1 INT  NOT NULL,
	accountid2 INT  NOT NULL,
	startdate  DATE NOT NULL
		CONSTRAINT DFT_Friendships_startdate DEFAULT(SYSDATETIME()),
	CONSTRAINT PK_Friendships PRIMARY KEY(accountid1, accountid2),
	CONSTRAINT CHK_Friendships_act1_lt_act2 CHECK (accountid1 < accountid2),
	CONSTRAINT FK_Friendships_Accounts_act1 FOREIGN KEY(accountid1)
		REFERENCES Norm.Accounts(accountid),
	CONSTRAINT FK_Friendships_Accounts_act2 FOREIGN KEY(accountid2)
		REFERENCES Norm.Accounts(accountid)
);

INSERT INTO Norm.Friendships (accountid1, accountid2, startdate) 
VALUES (2, 379, '20220202'),
	   (2, 641, '20220202'),
	   (2, 727, '20220202'),
	   (71, 199, '20220112'),
	   (71, 379, '20211003'),
	   (71, 661, '20210514'),
	   (71, 883, '20210514'),
	   (71, 953, '20220315'),
	   (199, 661, '20220112'),
	   (199, 883, '20220112'),
	   (199, 941, '20220112'),
	   (199, 953, '20220315'),
	   (379, 421, '20211003'),
	   (379, 641, '20211003'),
	   (421, 661, '20210517'),
	   (421, 727, '20210517'),
	   (641, 727, '20200801'),
	   (661, 883, '20210217'),
	   (661, 941, '20220105'),
	   (727, 883, '20210217'),
	   (883, 953, '20220315');

CREATE TABLE Norm.Followings (
	accountid1 INT  NOT NULL,
	accountid2 INT  NOT NULL,
	startdate  DATE NOT NULL
	CONSTRAINT DFT_Followings_startdate DEFAULT(SYSDATETIME()),
	CONSTRAINT PK_Followings PRIMARY KEY(accountid1, accountid2),
	CONSTRAINT FK_Followings_Accounts_act1 FOREIGN KEY(accountid1)
		REFERENCES Norm.Accounts(accountid),
	CONSTRAINT FK_Followings_Accounts_act2 FOREIGN KEY(accountid2)
		REFERENCES Norm.Accounts(accountid)
);

INSERT INTO Norm.Followings (accountid1, accountid2, startdate) 
VALUES (641, 727, '20200802'),
	   (883, 199, '20220113'),
	   (71, 953, '20220316'),
	   (661, 421, '20210518'),
	   (199, 941, '20220114'),
	   (71, 883, '20210516'),
	   (199, 953, '20220317'),
	   (661, 941, '20220106'),
	   (953, 71, '20220316'),
	   (379, 2, '20220202'),
	   (421, 661, '20210518'),
	   (661, 71, '20210516'),
	   (2, 727, '20220202'),
	   (2, 379, '20220203'),
	   (379, 641, '20211004'),
	   (941, 199, '20220112'),
	   (727, 421, '20210518'),
	   (379, 71, '20211005'),
	   (941, 661, '20220105'),
	   (641, 2, '20220204'),
	   (953, 199, '20220316'),
	   (727, 883, '20210218'),
	   (421, 379, '20211004'),
	   (71, 379, '20211004'),
	   (641, 379, '20211003'),
	   (199, 883, '20220114'),
	   (727, 2, '20220203'),
	   (199, 71, '20220113'),
	   (953, 883, '20220317'),
	   (71, 661, '20210514');

CREATE TABLE Norm.Likes (
	accountid INT          NOT NULL,
	postid    INT          NOT NULL,
	dt        DATETIME2(0) NOT NULL
		CONSTRAINT DFT_Likes_dt DEFAULT(SYSDATETIME()),
	CONSTRAINT PK_Likes PRIMARY KEY(accountid, postid),
	CONSTRAINT FK_Likes_Accounts FOREIGN KEY(accountid)
		REFERENCES Norm.Accounts(accountid),
	CONSTRAINT FK_Likes_Posts FOREIGN KEY(postid)
		REFERENCES Norm.Posts(postid)
);

INSERT INTO Norm.Likes (accountid, postid, dt) 
VALUES (2, 13, '2020-09-21 15:33:46'),
	   (199, 109, '2021-05-16 03:24:00'),
	   (379, 109, '2021-05-15 21:48:00'),
	   (379, 113, '2021-05-19 04:45:33'),
	   (661, 113, '2021-05-17 21:33:33'),
	   (727, 113, '2021-05-18 09:33:33'),
	   (379, 179, '2021-05-21 10:00:17'),
	   (661, 179, '2021-05-20 22:00:17'),
	   (727, 179, '2021-05-21 00:24:17'),
	   (199, 199, '2021-08-02 22:20:02'),
	   (71, 239, '2022-02-20 07:55:23'),
	   (199, 239, '2022-02-21 04:43:23'),
	   (661, 239, '2022-02-19 12:43:23'),
	   (727, 239, '2022-02-20 21:31:23'),
	   (2, 449, '2020-09-21 20:22:30'),
	   (379, 449, '2020-09-22 12:22:30'),
	   (727, 449, '2020-09-21 19:34:30'),
	   (71, 677, '2020-09-23 08:24:22'),
	   (199, 677, '2020-09-23 12:24:22'),
	   (661, 677, '2020-09-23 05:12:22'),
	   (727, 677, '2020-09-21 17:12:22'),
	   (953, 677, '2020-09-23 11:36:22'),
	   (71, 857, '2021-05-16 09:50:13'),
	   (199, 857, '2021-05-17 00:14:13'),
	   (661, 857, '2021-05-16 08:14:13'),
	   (727, 857, '2021-05-17 07:26:13'),
	   (953, 857, '2021-05-16 11:26:13'),
	   (2, 859, '2021-05-15 21:52:21'),
	   (71, 859, '2021-05-17 05:04:21'),
	   (421, 859, '2021-05-17 11:28:21'),
	   (71, 883, '2021-05-17 03:47:43'),
	   (379, 1021, '2020-09-22 20:56:17'),
	   (641, 1021, '2020-09-23 04:56:17'),
	   (2, 1031, '2020-09-21 16:26:03'),
	   (71, 1031, '2020-09-23 00:26:03'),
	   (421, 1031, '2020-09-23 10:02:03'),
	   (199, 1051, '2021-05-17 12:36:35'),
	   (2, 1061, '2020-09-22 08:31:51'),
	   (421, 1061, '2020-09-23 06:07:51'),
	   (641, 1061, '2020-09-21 18:55:51'),
	   (883, 1061, '2020-09-21 20:31:51'),
	   (2, 1151, '2021-05-17 13:04:12'),
	   (71, 1151, '2021-05-16 22:40:12'),
	   (421, 1151, '2021-05-16 01:04:12'),
	   (641, 1151, '2021-05-15 22:40:12'),
	   (2, 1187, '2020-09-23 13:19:52'),
	   (379, 1187, '2020-09-22 13:19:52');

CREATE TABLE Norm.AuthorsPublications (
	accountid INT NOT NULL,
	pubid     INT NOT NULL,
	CONSTRAINT PK_AuthorsPublications PRIMARY KEY(pubid, accountid),
	CONSTRAINT FK_AuthorsPublications_Accounts FOREIGN KEY(accountid)
		REFERENCES Norm.Accounts(accountid),
	CONSTRAINT FK_AuthorsPublications_Publications FOREIGN KEY(pubid)
		REFERENCES Norm.Publications(pubid)
);

INSERT INTO Norm.AuthorsPublications (accountid, pubid) 
VALUES (727, 23977),
	   (641, 23977),
	   (727, 4967),
	   (641, 27059),
	   (883, 14563),
	   (883, 46601),
	   (199, 46601);



------------------------
-- Graph Modeling
------------------------

-- In graph-based modeling, we work with two fundamental entity types: nodes & edges.

	-- Nodes represent the entities (or "endpoints") participating in relationships.

	-- Edges represent the relationships themselves. Each edge connects one node ("from node") to another node ("to node").



-- SQL Server's graph feature introduces syntax to define node & edge tables:

	-- AS NODE marks a table as a graph node.

	-- AS EDGE marks a table as a graph edge.

-- Instead of joining tables through foreign keys as we do in traditional relational modeling, graph queries use the MATCH clause. With MATCH, we represent relationships using ASCII-style arrows connecting the two node variables 

-- through an edge, like so:

	-- `from_node-(edge)->to_node`

-- For example, the relationship "Account likes Post" is expressed as:

	-- `Account-(Likes)->Post`

-- This structure reads naturally in English, which is a major advantage of graph-based design.



-- In graph modeling, table names typically follow natural-language patterns:

	-- Nodes use singular nouns (e.g., `Account`, `Post`, `Publication`)

	-- Edges use third-person singular verbs (e.g., `Follows`, `Likes`)

-- Where time or direction matters, the edges reflect it. For currently relevant relationships, we use present tense: `Likes`, `Follows`-- for historical relationships, we use past tense: `Posted`, `Authored` -- & sometimes, it

-- is helpful to include additional auxiliary verbs or prepositions: `IsReplyTo`, `IsFriendOf`. The guiding idea is to name edges the way we'd naturally describe the relationship in English.



-- In our social-network graph model (See "Graph Nodes & Edges.png"), we have 3 node tables & 6 edge tables. Nodes appear as rectangles in the diagram & edges appear as arrows. The full graph data model is shown in 

-- "Graph Data Model.png".



-- The graph model differs from the traditional relational model in that:

	-- 1. SQL Server automatically creates several system columns in graph tables.

		-- Node tables include a `$node_id` column, which is a system-generated identifier constructed from the table's object ID & a generated BIGINT graph ID value that uniquely idenfies each node across the database. When 

			-- queried, `$node_id` is returned as a computed JSON string.

		-- Edge tables include `$edge_id`, which is similar to `$node_id`, but unique to each edge row. They also include `$from_id` & `$to_id`, which store the node IDs of the connected nodes. Thus, when inserting a row into

			-- an edge table, we must supply the `$from_id` & `$to_id` values from the corresponding node rows.

	-- 2. Edge tables may include additional user-defined columns beyond the mandatory system-created `$edge_id`, `$from_id`, & `$to_id` columns. For example, the table `Graph.Follows` includes a column `startdate`, while the 
	
		-- table `Graph.IsReplyTo` has no additional columns.

	-- 3. Graph modeling replaces the foreign-key structures of a traditional relational model with edge tables:

		-- In the traditional model, `Posts.parentpostid` creates a self-referencing relationship; but in the graph model, this becomes a dedicated edge table `Graph.IsReplyTo`.

		-- In the traditional model, `Posts.accountid` has a foreign key relationship with `Accounts.accountid`, indicating who authored the post; but in the graph model, authorship is stored in the `Graph.Posted` edge table.

		-- This pattern is typical. Foreign-key relationships in the relational model usually become edge tables in the graph model.

	-- 4. Even though every node has a system-generated `$node_id`, it's still recommended to define our own key columns (e.g., `accountid`, `postid`, `pubid`). Custom keys make queries easier to write & maintain, & they provide

		-- stable identifiers -- even if a row is deleted & later reinserted, which would otherwise result in a new graph ID value.

-- The graph-based model results in nine tables total, compared to seven tables in the traditional relational model. This increase is normal; relationships that were represented by foreign keys are now represented as edge tables.



-----------------------------
-- Creating Node Tables
-----------------------------

-- To create a graph node table, append the AS NODE clause to the CREATE TABLE statement. Define the user-visible columns as usual, specifying names, data types, & nullability, but do not create the `$node_id` column. SQL Server

-- automatically adds it to every node table.

CREATE TABLE Graph.Account (
	accountid			INT				NOT NULL,
	accountname			NVARCHAR(50)	NOT NULL,
	joindate			DATE			NOT NULL
		CONSTRAINT DFT_Account_joindate DEFAULT(SYSDATETIME()),
	reputationpoints	INT				NOT NULL
		CONSTRAINT DFT_Account_reputationpoints DEFAULT(0),
	CONSTRAINT PK_Account PRIMARY KEY (accountid)
) AS NODE;

INSERT INTO Graph.Account (accountid, accountname, joindate, reputationpoints)
VALUES (641, N'Inka', '20200801', 5),
	   (71, N'Miko', '20210514', 8),
	   (379, N'Tami', '20211003', 5),
	   (421, N'Buzi', '20210517', 8),
	   (661, N'Alma', '20210119', 13),
	   (2, N'Orli', '20220202', 2),
	   (941, N'Stav', '20220105', 1),
	   (953, N'Omer', '20220315', 0),
	   (727, N'Mitzi', '20200714', 3),
	   (883, N'Yatzek', '20210217', 3),
	   (199, N'Lilach', '20220112', 1);

-- Use the following code to query the table:

SELECT * FROM Graph.Account;

-- When querying a node table, SQL Server returns the system-generated `$node_id` as a JSON-formatted graph identifier. It functions like an auto-incrementing BIGINT that doesn't reset on TRUNCATE, & SQL Server doesn't allow

-- inserting explicit graph ID values.



-- Create & populate the remaining node tables `Graph.Post` & `Graph.Publication`:

CREATE TABLE Graph.Post (
	postid    INT            NOT NULL,
	dt        DATETIME2(0)   NOT NULL
		CONSTRAINT DFT_Post_dt DEFAULT(SYSDATETIME()),
	posttext  NVARCHAR(1000) NOT NULL,
	CONSTRAINT PK_Post PRIMARY KEY(postid)
) AS NODE;

INSERT INTO Graph.Post (postid, dt, posttext) 
VALUES (13, '20200921 13:09:46', N'Got a new kitten. Any suggestions for a name?'),
	   (109, '20210515 17:00:00', N'Starting to hike the PCT today. Wish me luck!'),
	   (113, '20210517 10:21:33', N'Buzi here. This is my first post.'),
	   (149, '20210519 14:05:45', N'Buzi here. This is my second post.' + N' Aren''t my posts exciting?'),
	   (179, '20210520 09:12:17', N'Buzi here. Guess what; this is my third post!'),
	   (199, '20210802 15:56:02', N'Made it to Oregon!'),
	   (239, '20220219 09:31:23', N'I''m thinking of growing a mustache,' + N' but am worried about milk drinking...'),
	   (281, '20220318 08:14:24', N'Burt Shavits: "A good day is when no one shows up' + N' and you don''t have to go anywhere."'),
	   (449, '20200921 13:10:30', N'Maybe Pickle?'),
	   (677, '20200921 13:12:22', N'Ambrosius?'),
	   (857, '20210515 17:02:13', N'Break a leg. I mean, don''t!'),
	   (859, '20210515 17:04:21', N'The longest I''ve seen you hike was...' + N'wait, I''ve never seen you hike ;)'),
	   (883, '20210515 17:23:43', N'Ha ha ha!'),
	   (1021, '20200921 13:44:17', N'It does look a bit sour faced :)'),
	   (1031, '20200921 14:02:03', N'How about Gherkin?'),
	   (1051, '20210515 17:24:35', N'Jokes aside, is 95lbs reasonable for my backpack?'),
	   (1061, '20200921 14:07:51', N'I love Gherkin!'),
	   (1151, '20210515 18:40:12', N'Short answer, no! Long answer, nooooooo!!!'),
	   (1153, '20210515 18:47:17', N'Say what!?'),
	   (1187, '20200921 14:07:52', N'So you don''t like Pickle!? I''M UNFRIENDING YOU!!!'),
	   (1259, '20210515 19:05:54', N'Did I say that was without water?');

CREATE TABLE Graph.Publication (
	pubid   INT          NOT NULL,
	pubdate DATE         NOT NULL,
	title   NVARCHAR(100) NOT NULL,
	CONSTRAINT PK_Publication PRIMARY KEY(pubid)
) AS NODE;

INSERT INTO Graph.Publication(pubid, pubdate, title) 
VALUES (23977, '20200912' , N'When Mitzi met Inka'),
	   (4967, '20210304', N'When Mitzi left Inka'),
	   (27059, '20210401', N'It''s actually Inka who left Mitzi'),
	   (14563, '20210802', N'Been everywhere, seen it all; there''s no place like home!'),
	   (46601, '20220119', N'Love at first second');

-- We can query any of the node tables to inspect their data & verify that SQL Server has generated the `$node_id` column.

SELECT * FROM Graph.Post;
SELECT * FROM Graph.Publication;



---------------------------
-- Creating Edge Tables
---------------------------

-- Just like node tables, edge tables are created with the CREATE TABLE statement. The table name & any user-defined columns or constraints are listed within the parentheses, & the definition ends with the AS EDGE clause. SQL 

-- Server implicitly creates the columns `$edge_id`, `$from_id`, & `$to_id` for every edge table. Because of this, we do not explicitly define those columns ourself. If no additional user-defined columns or constraints are 

-- needed, the minimal syntax is:

	-- `CREATE TABLE <table_name> AS EDGE;`

-- If we do need user-defined columns or constraints, include them inside the parentheses:

	-- `CREATE TABLE <table_name> (<columns_&_constraints>) AS EDGE`;



-- Edge constraints restrict which node tables an edge may connect. They prevent orphaned edge rows by ensuring that both `$from_id` & `$to_id` reference valid nodes in one of the allowed node-table pairs. The syntax for an edge

-- constraint is:

	-- `[CONSTRAINT <constraint_name>]
	--		CONNECTION (<from_node_table_1> TO <to_node_table_1>
	--			        [..., <from_node_table_n> TO <to_node_table_n>])
	--		[ON DELETE <referential_action>]`

-- The ON DELETE referential action supports NO ACTION or CASCADE. NO ACTION means that SQL Server will block an attempt to delete a node if edges reference it. CASCADE means that deleting a node automatically removes its

-- connecting edges. For example, we can create an edge constraint on the `Graph.IsReplyTo` edge table:

CREATE TABLE Graph.IsReplyTo (
	CONSTRAINT EC_IsReplyTo CONNECTION (Graph.Post TO Graph.Post)
		ON DELETE NO ACTION
) AS EDGE;



-- SQL Server does not allow us to put regular foreign key constraints on an edge table's `$from_id` & `$to_id` columns. Instead, SQL Server gives us a special constraint type called a graph edge constriant. A graph edge table

-- may legitimately connect multiple pairs of node tables, so we can define one graph edge constraint that lists all permissible node-table pairs:

	-- `CREATE TABLE MyEdgeTable (
	--		CONSTRAINT MyConstraint CONNECTION 
	--			(MyFromNode1 TO MyToNode1, 
	--			 MyFromNode2 TO MyToNode2, ...)
	--			ON DELETE ON ACTION
	--  ) AS EDGE;`

-- This says that every row in the edge table must connect either `MyFromNode1->MyToNode1` or `MyFromNode2->MyToNode2`. So only one pair needs to match, not all.



-- To prevent duplicate "from node" & "to node" pairs (`$from_id`, `$to_id`), introduce a UNIQUE constraint based on those columns:

ALTER TABLE Graph.IsReplyTo
	ADD CONSTRAINT UNQ_IsReplyTo_fromid_toid UNIQUE($from_id, $to_id);



-- To insert edges, we must supply `$from_id` & `$to_id`, which are the `$node_id` values from the corresponding node tables. One method, albeit a bit verbose, is:

INSERT INTO Graph.IsReplyTo ($from_id, $to_id) 
VALUES ((SELECT $node_id FROM Graph.Post WHERE postid = 449), (SELECT $node_id FROM Graph.Post WHERE postid = 13)),
	   ((SELECT $node_id FROM Graph.Post WHERE postid = 677), (SELECT $node_id FROM Graph.Post WHERE postid = 13)),
	   ((SELECT $node_id FROM Graph.Post WHERE postid = 857), (SELECT $node_id FROM Graph.Post WHERE postid = 109)),
	   ((SELECT $node_id FROM Graph.Post WHERE postid = 859), (SELECT $node_id FROM Graph.Post WHERE postid = 109)),
	   ((SELECT $node_id FROM Graph.Post WHERE postid =  883), (SELECT $node_id FROM Graph.Post WHERE postid = 109)),
	   ((SELECT $node_id FROM Graph.Post WHERE postid = 1021), (SELECT $node_id FROM Graph.Post WHERE postid = 449)),
	   ((SELECT $node_id FROM Graph.Post WHERE postid = 1031), (SELECT $node_id FROM Graph.Post WHERE postid = 449)),
	   ((SELECT $node_id FROM Graph.Post WHERE postid = 1051), (SELECT $node_id FROM Graph.Post WHERE postid = 883)),
	   ((SELECT $node_id FROM Graph.Post WHERE postid = 1061), (SELECT $node_id FROM Graph.Post WHERE postid = 1031)),
	   ((SELECT $node_id FROM Graph.Post WHERE postid = 1151), (SELECT $node_id FROM Graph.Post WHERE postid = 1051)),
	   ((SELECT $node_id FROM Graph.Post WHERE postid = 1153), (SELECT $node_id FROM Graph.Post WHERE postid = 1051)),
	   ((SELECT $node_id FROM Graph.Post WHERE postid = 1187), (SELECT $node_id FROM Graph.Post WHERE postid = 1061)),
	   ((SELECT $node_id FROM Graph.Post WHERE postid = 1259), (SELECT $node_id FROM Graph.Post WHERE postid = 1151));

SELECT * FROM Graph.IsReplyTo;

-- Similar to new node rows, new edge rows are automatically assigned with graph ID values starting with 0 & increase with each insertion. We cannot provide our own explicit graph ID values, & if we delete or truncate rows or 

-- reinsert rows, the graph ID values do not reset -- rather they continue where the last insertion left off.



-- A cleaner method of inserting rows into an edge table is by using a table-value constructor:

TRUNCATE TABLE Graph.IsReplyTo;

INSERT INTO Graph.IsReplyTo($from_id, $to_id)
	SELECT FP.$node_id AS fromid, TP.$node_id AS toid
	FROM (VALUES(449, 13),
				(677, 13),
				(857, 109),
				(859, 109),
				(883, 109),
				(1021, 449),
				(1031, 449),
				(1051, 883),
				(1061, 1031),
				(1151, 1051),
				(1153, 1051),
				(1187, 1061),
				(1259, 1151)) AS D(frompostid, topostid)
	INNER JOIN Graph.Post AS FP
		ON D.frompostid = FP.postid
	INNER JOIN Graph.Post AS TP
		ON D.topostid = TP.postid;

SELECT * FROM Graph.IsReplyTo;

-- Graph IDs continue incrementing from the last used ID.



-- If we are migrating data from an existing relational model to a graph-based model, we use the following process:

	-- 1. Create node tables.

	-- 2. Populate each node table using `INSERT ... SELECT ...`, allowing SQL Server to generate `$node_id`.

	-- 3. Create edge tables.

	-- 4. Populate each edge table using `INSERT ... SELECT ...` statements, joining the relational table with its corresponding graph-based node table to retrieve the `$node_id` values for the "from" & "to" nodes.

-- Steps 1-3 are straightforward, but to demonstrate step 4, here's an example populating `Graph.IsReplyTo` (after first truncating what it had previously):

TRUNCATE TABLE Graph.IsReplyTo;

INSERT INTO Graph.IsReplyTo($from_id, $to_id)
	SELECT FP.$node_id AS fromid, TP.$node_id AS toid
	FROM Norm.Posts AS P
	INNER JOIN Graph.Post AS FP
		ON P.postid = FP.postid
	INNER JOIN Graph.Post AS TP
		ON P.parentpostid = TP.postid;

SELECT * FROM Graph.IsReplyTo;

-- Naturally, the edges connect the same `$from_id` & `$to_id` values as before, but get new graph ID values as part of the `$edge_id` values. 



-- The following examples for `Posted`, `IsFriendOf`, `Follows`, & `Likes` & `Authored` all correctly follow the same pattern:

	-- Create the edge table with a CONNECTION constraint.

	-- Add a unique constraint on `$from_id` & `$to_id`

	-- Insert edges using a table-value constructor joined to the relevant node tables.

	-- Include additional columns (e.g., `startdate`, `dt`) if necessary.

CREATE TABLE Graph.Posted (
	CONSTRAINT EC_Posted CONNECTION (Graph.Account TO Graph.Post)
		ON DELETE NO ACTION
) AS EDGE;

ALTER TABLE Graph.Posted
	ADD CONSTRAINT UNQ_Posted_fromid_toid UNIQUE($from_id, $to_id);

INSERT INTO Graph.Posted($from_id, $to_id)
	SELECT A.$node_id AS fromid, P.$node_id AS toid
	FROM (VALUES(727, 13),
				(71, 109),
				(421, 113),
				(421, 149),
				(421, 179),
				(71, 199),
				(883, 239),
				(953, 281),
				(641, 449),
				(883, 677),
				(883, 857),
				(379, 859),
				(199, 883),
				(2, 1021),
				(379, 1031),
				(71, 1051),
				(727, 1061),
				(379, 1151),
				(883, 1153),
				(641, 1187),
				(71, 1259)) AS D(accountid, postid)
	INNER JOIN Graph.Account AS A
		ON D.accountid = A.accountid
	INNER JOIN Graph.Post AS P
		ON D.postid = P.postid;



CREATE TABLE Graph.IsFriendOf (
	startdate  DATE NOT NULL
		CONSTRAINT DFT_Friendships_startdate DEFAULT(SYSDATETIME()),
	CONSTRAINT EC_IsFriendOf CONNECTION (Graph.Account TO Graph.Account)
		ON DELETE NO ACTION
) AS EDGE;

ALTER TABLE Graph.IsFriendOf
	ADD CONSTRAINT UNQ_IsFriendOf_fromid_toid UNIQUE($from_id, $to_id);

INSERT INTO Graph.IsFriendOf($from_id, $to_id, startdate)
	SELECT A1.$node_id AS fromid, A2.$node_id AS toid, D.startdate
	FROM (VALUES(2, 379, '20220202'),
				(2, 641, '20220202'),
				(2, 727, '20220202'),
				(71, 199, '20220112'),
				(71, 379, '20211003'),
				(71, 661, '20210514'),
				(71, 883, '20210514'),
				(71, 953, '20220315'),
				(199, 661, '20220112'),
				(199, 883, '20220112'),
				(199, 941, '20220112'),
				(199, 953, '20220315'),
				(379, 421, '20211003'),
				(379, 641, '20211003'),
				(421, 661, '20210517'),
				(421, 727, '20210517'),
				(641, 727, '20200801'),
				(661, 883, '20210217'),
				(661, 941, '20220105'),
				(727, 883, '20210217'),
				(883, 953, '20220315'),
				(379, 2, '20220202'),
				(641, 2, '20220202'),
				(727, 2, '20220202'),
				(199, 71, '20220112'),
				(379, 71, '20211003'),
				(661, 71, '20210514'),
				(883, 71, '20210514'),
				(953, 71, '20220315'),
				(661, 199, '20220112'),
				(883, 199, '20220112'),
				(941, 199, '20220112'),
				(953, 199, '20220315'),
				(421, 379, '20211003'),
				(641, 379, '20211003'),
				(661, 421, '20210517'),
				(727, 421, '20210517'),
				(727, 641, '20200801'),
				(883, 661, '20210217'),
				(941, 661, '20220105'),
				(883, 727, '20210217'),
				(953, 883, '20220315')) AS D(accountid1, accountid2, startdate)
	INNER JOIN Graph.Account AS A1
		ON D.accountid1 = A1.accountid
	INNER JOIN Graph.Account AS A2
		ON D.accountid2 = A2.accountid;



CREATE TABLE Graph.Follows (
	startdate  DATE NOT NULL
		CONSTRAINT DFT_Follows_startdate DEFAULT(SYSDATETIME()),
	CONSTRAINT EC_Follows CONNECTION (Graph.Account TO Graph.Account)
		ON DELETE NO ACTION
) AS EDGE;

ALTER TABLE Graph.Follows
	ADD CONSTRAINT UNQ_Follows_fromid_toid UNIQUE($from_id, $to_id);

INSERT INTO Graph.Follows($from_id, $to_id, startdate)
	SELECT A1.$node_id AS fromid, A2.$node_id AS toid, D.startdate
	FROM (VALUES(641, 727, '20200802'),
				(883, 199, '20220113'),
				(71, 953, '20220316'),
				(661, 421, '20210518'),
				(199, 941, '20220114'),
				(71, 883, '20210516'),
				(199, 953, '20220317'),
				(661, 941, '20220106'),
				(953, 71, '20220316'),
				(379, 2, '20220202'),
				(421, 661, '20210518'),
				(661, 71, '20210516'),
				(2, 727, '20220202'),
				(2, 379, '20220203'),
				(379, 641, '20211004'),
				(941, 199, '20220112'),
				(727, 421, '20210518'),
				(379, 71, '20211005'),
				(941, 661, '20220105'),
				(641, 2, '20220204'),
				(953, 199, '20220316'),
				(727, 883, '20210218'),
				(421, 379, '20211004'),
				(71, 379, '20211004'),
				(641, 379, '20211003'),
				(199, 883, '20220114'),
				(727, 2, '20220203'),
				(199, 71, '20220113'),
				(953, 883, '20220317'),
				(71, 661, '20210514')) AS D(accountid1, accountid2, startdate)
	INNER JOIN Graph.Account AS A1
		ON D.accountid1 = A1.accountid
	INNER JOIN Graph.Account AS A2
		ON D.accountid2 = A2.accountid;



CREATE TABLE Graph.Likes (
	dt DATETIME2(0) NOT NULL
		CONSTRAINT DFT_Likes_dt DEFAULT(SYSDATETIME()),
	CONSTRAINT EC_Likes CONNECTION (Graph.Account TO Graph.Post)
		ON DELETE NO ACTION
) AS EDGE;

ALTER TABLE Graph.Likes
	ADD CONSTRAINT UNQ_Likes_fromid_toid UNIQUE($from_id, $to_id);

INSERT INTO Graph.Likes($from_id, $to_id, dt)
	SELECT A.$node_id AS fromid, P.$node_id AS toid, D.dt
	FROM (VALUES(2, 13, '2020-09-21 15:33:46'),
				(199, 109, '2021-05-16 03:24:00'),
				(379, 109, '2021-05-15 21:48:00'),
				(379, 113, '2021-05-19 04:45:33'),
				(661, 113, '2021-05-17 21:33:33'),
				(727, 113, '2021-05-18 09:33:33'),
				(379, 179, '2021-05-21 10:00:17'),
				(661, 179, '2021-05-20 22:00:17'),
				(727, 179, '2021-05-21 00:24:17'),
				(199, 199, '2021-08-02 22:20:02'),
				(71, 239, '2022-02-20 07:55:23'),
				(199, 239, '2022-02-21 04:43:23'),
				(661, 239, '2022-02-19 12:43:23'),
				(727, 239, '2022-02-20 21:31:23'),
				(2, 449, '2020-09-21 20:22:30'),
				(379, 449, '2020-09-22 12:22:30'),
				(727, 449, '2020-09-21 19:34:30'),
				(71, 677, '2020-09-23 08:24:22'),
				(199, 677, '2020-09-23 12:24:22'),
				(661, 677, '2020-09-23 05:12:22'),
				(727, 677, '2020-09-21 17:12:22'),
				(953, 677, '2020-09-23 11:36:22'),
				(71, 857, '2021-05-16 09:50:13'),
				(199, 857, '2021-05-17 00:14:13'),
				(661, 857, '2021-05-16 08:14:13'),
				(727, 857, '2021-05-17 07:26:13'),
				(953, 857, '2021-05-16 11:26:13'),
				(2, 859, '2021-05-15 21:52:21'),
				(71, 859, '2021-05-17 05:04:21'),
				(421, 859, '2021-05-17 11:28:21'),
				(71, 883, '2021-05-17 03:47:43'),
				(379, 1021, '2020-09-22 20:56:17'),
				(641, 1021, '2020-09-23 04:56:17'),
				(2, 1031, '2020-09-21 16:26:03'),
				(71, 1031, '2020-09-23 00:26:03'),
				(421, 1031, '2020-09-23 10:02:03'),
				(199, 1051, '2021-05-17 12:36:35'),
				(2, 1061, '2020-09-22 08:31:51'),
				(421, 1061, '2020-09-23 06:07:51'),
				(641, 1061, '2020-09-21 18:55:51'),
				(883, 1061, '2020-09-21 20:31:51'),
				(2, 1151, '2021-05-17 13:04:12'),
				(71, 1151, '2021-05-16 22:40:12'),
				(421, 1151, '2021-05-16 01:04:12'),
				(641, 1151, '2021-05-15 22:40:12'),
				(2, 1187, '2020-09-23 13:19:52'),
				(379, 1187, '2020-09-22 13:19:52')) AS D(accountid, postid, dt)
	INNER JOIN Graph.Account AS A
		ON D.accountid = A.accountid
	INNER JOIN Graph.Post AS P
		ON D.postid = P.postid;



CREATE TABLE Graph.Authored (
	CONSTRAINT EC_Authored CONNECTION (Graph.Account TO Graph.Publication)
		ON DELETE NO ACTION
) AS EDGE;

ALTER TABLE Graph.Authored
	ADD CONSTRAINT UNQ_Authored_fromid_toid UNIQUE($from_id, $to_id);

INSERT INTO Graph.Authored($from_id, $to_id)
	SELECT A.$node_id AS fromid, P.$node_id AS toid
	FROM (VALUES(727, 23977),
				(641, 23977),
				(727, 4967),
				(641, 27059),
				(883, 14563),
				(883, 46601),
				(199, 46601)) AS D(accountid, pubid)
	INNER JOIN Graph.Account AS A
		ON D.accountid = A.accountid
	INNER JOIN Graph.Publication AS P
		ON D.pubid = P.pubid;
GO



-------------------------
-- Querying MetaData
-------------------------

-- SQL Server provides catalog views & system functions that allows us to query metadata from our graph objects (node & edge tables).



-- The `sys.tables` view contains a pair of columns, `is_node` & `is_edge`, which are used to identify whether a graph table is a node table or an edge table. A value of 1 means true & 0 means false.

	-- `is_node`: 1 if the table is a node table

	-- `is_edge`: 1 if the table is an edge table

-- To return all graph tables in the current database:

SELECT SCHEMA_NAME(schema_id) + N'.' + name AS tablename, is_node, is_edge,
	CASE
		WHEN is_node = 1 THEN 'NODE'
		WHEN is_edge = 1 THEN 'EDGE'
		ELSE 'Not SQLGraph table'
	END AS tabletype
FROM sys.tables
WHERE is_node = 1 OR is_edge = 1;



-- The `sys.columns` view has two columns `graph_type` & `graph_type_desc` that provide a numeric & textual descriptive graph type, respectively:

	-- `graph_type`: numeric indicator of graph metadata type

	-- `graph_type_desc`: human-readable description

SELECT name, TYPE_NAME(user_type_id) AS typename, max_length,
	graph_type, graph_type_desc
FROM sys.columns
WHERE object_id = OBJECT_ID('Graph.Account');

-- Let's also inspect the metadata of the `Graph.Posted` edge table:

SELECT name, TYPE_NAME(user_type_id) AS typename, max_length,
	graph_type, graph_type_desc
FROM sys.columns
WHERE object_id = OBJECT_ID('Graph.Posted');

-- As we can see, every edge table contains eight graph-related columns:

	-- `graph_id` stores an internal system-generated BIGINT graph ID, which is unique to each row in the edge table.

	-- `$edge_id` is a computed JSON string representation of the edge ID, & is unique to the edge table.

	-- `$from_id` is a computed column holding the `$node_id` value of the "from node" in the edge. The `from_object_id` & `from_id` internal columns store the raw object ID & graph ID values of the "from node", respectively.

	-- `$to_id` is a computed column holding the `$node_id` value of the "to node" in the edge. The `to_obj_id` & `to_id` internal columns store the raw object ID & graph ID values of the "to node", respectively.

-- Each of the queryable columns `$edge_id`, `$from_id`, & `$to_id` store a structured JSON string computed from the object type (node or edge), schema, table & internal graph ID.



-- SQL Server provides functions that allow us to extract raw graph & object IDs, as well as rebuild node & edge IDs using the four columns described above:

-- | Function               | Purpose                                                   |
-- | ---------------------- | --------------------------------------------------------- |
-- | OBJECT_ID_FROM_NODE_ID | Extract the `object_id` from `node_id`.                   |
-- | ---------------------- | --------------------------------------------------------- |
-- | GRAPH_ID_FROM_NODE_ID  | Extract the `graph_id` from `node_id`.                    |
-- | ---------------------- | --------------------------------------------------------- |
-- | NODE_ID_FROM_PARTS     | Construct a `node_id` from an `object_id` & a `graph_id`. |
-- | ---------------------- | --------------------------------------------------------- |
-- | OBJECT_ID_FROM_EDGE_ID | Extract `object_id` from `edge_id`.                       |
-- | ---------------------- | --------------------------------------------------------- |
-- | GRAPH_ID_FROM_EDGE_ID  | Extract identity from `edge_id`.                          |
-- | ---------------------- | --------------------------------------------------------- |
-- | EDGE_ID_FROM_PARTS     | Construct `edge_id` from `object_id` & identity.          |
-- | ---------------------- | --------------------------------------------------------- |

-- As an example, we'll extract the object & graph ID values from the `$node_id` values of the nodes stored in the `Account` table:

SELECT $node_id,
	OBJECT_ID_FROM_NODE_ID($node_id) AS obj_id,
	GRAPH_ID_FROM_NODE_ID($node_id) AS graph_id
FROM Graph.Account;



-- As mentioned earlier, it's a good practice to define our own primary key columns (e.g., `accountid`, `postid`, & `pubid`) for consistent queries. However, we can identify nodes by internal graph IDs with the

-- GRAPH_ID_FROM_NODE_ID function, if needed:

SELECT $node_id, accountid, accountname
FROM Graph.Account
WHERE GRAPH_ID_FROM_NODE_ID($node_id) = 3;

-- We can also use the NODE_ID_FROM_PARTS function to build a node ID from the given raw object ID & graph ID values:

SELECT NODE_ID_FROM_PARTS(OBJECT_ID(N'Graph.Account'), 3);



-- Just like how we manipulate node objects with:

	-- `OBJECT_ID_FROM_NODE_ID`
	
	-- `GRAPH_ID_FROM_NODE_ID`
	
	-- `NODE_ID_FROM_PARTS`
	
-- The following functions can operate in the same manner as their node-focused counterparts:

	-- `OBJECT_ID_FROM_EDGE_ID`
	
	-- `GRAPH_ID_FROM_EDGE_ID`
	
	-- `EDGE_ID_FROM_PARTS`