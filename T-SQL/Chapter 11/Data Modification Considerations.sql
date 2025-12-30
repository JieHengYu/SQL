-------------------------------------------

-- Data Modification Considerations

------------------------------------------

-- Earlier, we explored several ways to insert data into node & edge graph tables, along with key considerations for doing so. In this section, we'll continue our discussion of data modification in graph tables, focusing on how

-- to delete, update, & merge data effectively.



----------------------------------
-- Deleting & Updating Data
----------------------------------

-- Deleting & updating rows in node tables, where we identify targets using our own user-defined keys, is straightforward. The process becomes a bit more involved with edge tables, where we need to locate edge rows based on the 

-- pair of user-defined keys corresponding to the "from node" & "to node" that the edge connects. Keep in mind that edge rows do not store the user-defined keys of the nodes they connect; instead, they store system-generated 

-- internal keys. To perform updates or deletions, we must first translate the user-defined keys we have into these internal keys. Before we demonstrate deleting & updating graph data, run the following query to see the current

-- following relationships where Alma is the follower.

USE TSQLV6;

SELECT Account1.accountid AS actid1, Account1.accountname AS actname1,
	Account2.accountid AS actid2, Account2.accountname AS actname2,
	Follows.startdate
FROM Graph.Account AS Account1, Graph.Follows, Graph.Account AS Account2
WHERE MATCH(Account1-(Follows)->Account2)
	AND Account1.accountid = 661;

-- This output shows that Alma currently follows three accounts.



-- Suppose Alma stops following Buzi, & we need to delete the corresponding follow relationship from the `Graph.Follows` table. We receive the user-defined keys of the involved nodes as inputs. For this ad-hoc example, we'll use

-- local variables `@actid = 661` (Alma) & `@actid = 421` (Buzi). In a typical scenario, a stored procedure would handle this task, taking `@actid1` & `$@actid2` as input parameters. The DELETE statement itself works the same

-- way, whether the inputs come from local variables or procedure parameters.



-- One approach is to use subqueries. We issue the DELETE statement against the `Graph.Follows` edge table, & in the WHERE clause, we compare the `$from_id` & `$to_id` columns to the results of scalar subqueries that translate

-- the user-defined keys into the internal system-generated node IDs. The following code performs the deletion & then re-queries the data to show Alma's follow relationships after the deletion:

BEGIN TRAN;

DECLARE @actid1 AS INT = 661, @actid2 AS INT = 421;

DELETE FROM Graph.Follows
WHERE $from_id = (SELECT $node_id FROM Graph.Account
				  WHERE accountid = @actid1)
	AND $to_id = (SELECT $node_id FROM Graph.Account
				  WHERE accountid = @actid2);

SELECT Account1.accountid AS actid1, Account1.accountname AS actname1,
	Account2.accountid AS actid2, Account2.accountname AS actname2,
	Follows.startdate
FROM Graph.Account AS Account1, Graph.Follows,
	Graph.Account AS Account2
WHERE MATCH(Account1-(Follows)->Account2)
	AND Account1.accountid = 661;

ROLLBACK TRAN;

-- The output confirms that Alma no longer follows Buzi.



-- Another, often more elegant, approach is to use a match pattern. In this method, the DELETE statement includes a FROM clause that lists the tables & aliases involved in the match pattern, in our example, `Graph.Account AS

-- Account1`, `Graph.Account AS Account2`, & `Graph.Follows`. In the WHERE clause, we specify the MATCH expression `Account1-(Follows)->Account2`, & then filter by the relevant user-defined keys (`Account1.accountid = @actid1` &

-- `Account2.accountid = @actid2`). Finally, a second DELETE clause at the top identifies `Follows` as the table we want to modify. Here's the complete solution, including a verifcation query, wrapped in a transaction so the 

-- change can be rolled back:

BEGIN TRAN;

DECLARE @actid1 AS INT = 661, @actid2 AS INT = 421;

DELETE FROM Follows
FROM Graph.Account AS Account1, Graph.Account AS Account2, Graph.Follows
WHERE MATCH(Account1-(Follows)->Account2)
	AND Account1.accountid = @actid1
	AND Account2.accountid = @actid2;

SELECT Account1.accountid AS actid1, Account1.accountname AS actname1,
	Account2.accountid AS actid2, Account2.accountname AS actname2,
	Follows.startdate
FROM Graph.Account AS Account1, Graph.Follows, Graph.Account AS Account2
WHERE MATCH(Account1-(Follows)->Account2)
	AND Account1.accountid = 661;

ROLLBACK TRAN;



-- T-SQL does not allow updating the `$from_id` or `$to_id` columns in an edge table. If we need to change the nodes an edge connects, we must delete the existing edge row & insert a new one. However, updating other edge

-- attributes works similarly to deletions: we first identifying the relevant row(s) using user-defined node keys. For example, suppose we need to change the start date of the follow relationship between Alma & Buzi to August 2,

-- 2021. The code below demonstrates the update using scalar subqueries, this time including an OUTPUT clause to return the old & new values:

BEGIN TRAN;

DECLARE @actid1 AS INT = 661, @actid2 AS INT = 421,
	@startdate AS DATE = '20210802';

UPDATE Graph.Follows
	SET startdate = @startdate
OUTPUT deleted.startdate AS olddate, inserted.startdate AS newdate
WHERE $from_id = (SELECT $node_id FROM Graph.Account
				  WHERE accountid = @actid1)
	AND $to_id = (SELECT $node_id FROM Graph.Account
				  WHERE accountid = @actid2);

ROLLBACK TRAN;

-- As with deletions, we can alternatively use a match pattern for a cleaner approach:

BEGIN TRAN;

DECLARE @actid1 AS INT = 661, @actid2 AS INT = 421,
	@startdate AS DATE = '20210802';

UPDATE Follows
	SET startdate = @startdate
OUTPUT deleted.startdate AS olddate, inserted.startdate AS newdate
FROM Graph.Account AS Account1, Graph.Account AS Account2, Graph.Follows
WHERE MATCH(Account1-(Follows)->Account2)
	AND Account1.accountid = @actid1
	AND Account2.accountid = @actid2;

ROLLBACK TRAN;



--------------------
-- Merging Data
--------------------

-- Starting in SQL Server 2019, T-SQL allows the MATCH clause to be used within a MERGE statement to determine the matching status & trigger the appropriate action. before we walk through an example using this capability, run 

-- the following query to view the current follow relationships where Alma is the follower or Yatzek is the followee:

SELECT Account1.accountid AS actid1, Account1.accountname AS actname1,
	Account2.accountid AS actid, Account2.accountname AS actname2,
	Follows.startdate
FROM Graph.Account AS Account1, Graph.Follows, Graph.Account AS Account2
WHERE MATCH(Account1-(Follows)->Account2)
	AND (Account1.accountid = 661 OR Account2.accountid = 883);

-- Our task is to merge an input follow relationship, representing by the variables `@actid1`, `@actid2`, & `@startdate`, into the `Graph.Follows` table. In this first example, we'll assign the following values: `@actid1 = 661` 

-- (Alma), `@actid2 = 421` (Buzi), `@startdate = '20210802'`. If the specified follow relationship does not already exist, we need to insert a new edge row. If it does exist, we instead update the existing row's `startdate` with

-- the provided value.



-- The target table specified in the MERGE statement's INTO clause is, of course, `Graph.Follows`.



-- For the USING clause, which defines the source of the merge, we need to supply the nodes involved in the input relationship. Since this clause behaves similarly to a query's FROM clause, we can use joins with tables. We start

-- by constructing a single-row derived table from the input variables:

	-- `(SELECT @actid1, @actid2, @startdate) AS SRC(actid1, actid2, startdate)`. 

-- Then we join `SRC` to two instances of the `Graph.Account` node tables:

	-- `Account1` representing the "from node" (`@actid1`)

	-- `Account2` representing the "to node" (`@actid2`)

-- Next, in the ON clause of the MERGE statement, we use a MATCH predicate with the pattern `Account1-(Follows)->Account2`, where the joined node tables act as the source & the edge table acts as the target for matching. Finally,

-- we define two actions:

	-- WHEN MATCHED: perform an UPDATE

	-- WHEN NOT MATCHED: perform an INSERT

-- Here is the complete MERGE statement wrapped in a transaction, followed by a verficiation query & a rollback to undo the change:

BEGIN TRAN;

DECLARE @actid1 AS INT = 661, @actid2 AS INT = 421,
	@Startdate AS DATE = '20210802';

MERGE INTO Graph.Follows
USING (SELECT @actid1, @actid2, @startdate)
	AS SRC(actid1, actid2, startdate)
		INNER JOIN Graph.Account AS Account1
			ON SRC.actid1 = Account1.accountid
		INNER JOIN Graph.Account AS Account2
			ON SRC.actid2 = Account2.accountid
		ON MATCH(Account1-(Follows)->Account2)
	WHEN MATCHED THEN UPDATE
		SET startdate = SRC.startdate
	WHEN NOT MATCHED THEN INSERT($from_id, $to_id, startdate)
		VALUES(Account1.$node_id, Account2.$node_id, SRC.startdate);

	SELECT Account1.accountid AS actid1, Account1.accountname AS actname1,
		Account2.accountid AS actid2, Account2.accountname AS actiname2,
		Follows.startdate
	FROM Graph.Account AS Account1, Graph.Follows, Graph.Account AS Account2
	WHERE MATCH(Account1-(Follows)->Account2)
		AND (Account1.accountid = 661 OR Account2.accountid = 883);

ROLLBACK TRAN;

-- Running this code shows that the existing relationship between Alma and Buzi has had its start date updated.



-- Now, let's run another merge operation, this time involving a follow relationship that does not currently exist. Alma (account ID 661) will follow Yatzek (account ID 883) with a start date of August 2, 2021:

BEGIN TRAN;

DECLARE @actid1 AS INT = 661, @actid2 AS INT = 883,
	@startdate AS DATE = '20210802';

MERGE INTO Graph.Follows
USING (SELECT @actid1, @actid2, @startdate)
	AS SRC(actid1, actid2, startdate)
		INNER JOIN Graph.Account AS Account1
			ON SRC.actid1 = Account1.accountid
		INNER JOIN Graph.Account AS Account2
			ON SRC.actid2 = Account2.accountid
		ON MATCH(Account1-(Follows)->Account2)
	WHEN MATCHED THEN UPDATE
		SET startdate = SRC.startdate
	WHEN NOT MATCHED THEN INSERT($from_id, $to_id, startdate)
		VALUES(Account1.$node_id, Account2.$node_id, SRC.startdate);

	SELECT Account1.accountid AS actid1, Account1.accountname AS actname1,
		Account2.accountid AS actid2, Account2.accountname AS actname2,
		Follows.startdate
	FROM Graph.Account AS Account1, Graph.Follows, Graph.Account AS Account2
	WHERE MATCH(Account1-(Follows)->Account2)
		AND (Account1.accountid = 661 OR Account2.accountid = 883);

ROLLBACK TRAN;

-- In this case, because the relationship did not exist beforehand, a new row is inserted into the `Graph.Follows` table.