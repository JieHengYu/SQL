---------------

-- Cursors

---------------

-- Previously, we explained that a query without an ORDER BY clause returns a set (or multiset), whereas a query with an ORDER BY clause returns what standard SQL refers to as a cursor, a nonrelational result in which the order

-- of rows is guaranteed. That discussion was conceptual.



-- SQL & T-SQL also support an explicit database object called a cursor, which we can use to process the rows returned by a query one row at a time & in a specified order. This approach contrasts with set-based queries, where we

-- manipulate an entire set or multiset at once & cannot rely on any inherent ordering unless explicitly specified.



-- As a general rule, our default choice should be to use set-based solutions. Cursors should be considered only when we have a compelling reason to do otherwise. This recommendation is based on several important considerations:

	-- Departure from the relational model:

		-- First & foremost, cursors work against the relational model, which is grounded in set theory. Row-by-row processing is inherently procedural rather than relational.

	-- Performance overhead:

		-- Cursor-based processing incurs overhead for each row. Compared to set-based manipulation, each row operation performed by a cursor has an associated cost. When a set-based query & a cursor-based solution perform

		-- similar logical work, the cursor-based solution is usually many times slower.

	-- Imperative vs. declarative code:

		-- Cursor solutions are imperative: we must explicitly define how the data is processed, declaring the cursor, opening it, fetching rows, looping, closing it, & deallocating it. Set-based solutions, by contrast, are

		-- declarative; we focus primarily on what result we want rather than how to obtain it. As a result, cursor-based code tends to be longer, less readable, & harder to maintain.



-- As with most rules, there are exceptions. One common scenario is when we must apply a task to each row individually -- for example, executing an administrative operation for each index or table in a database. In such cases,

-- using a cursor to iterate through object names & execute a command for each one can be appropriate.



-- Another scenario arises when a set-based solution performs poorly & all reasonable tuning efforts have been exhausted. Althouogh rare, there are exceptional cases in which a cursor-based solution performs better. A classic 

-- example is computing running aggregates in versions of SQL Server that do not support window function framing. Relational solutions based on joins or correlated subqueries for running totals can be extremely inefficient. In

-- such environments, an iterative approach -- such as one using a cursor -- may be the most efficient option. When compatibility restrictions do not exist, however, window functions provide the optimal & preferred solution.



-- Working with a cursor typically involves the following steps:

	-- 1. Declare the cursor based on a query.

	-- 2. Open the cursor.

	-- 3. Fetch attribute values from the first cursor row into variables.

	-- 4. Loop through the cursor rows while the last fetch was successful (that is, while `@@FETCH_STATUS = 0`).

		-- In each iteration, process the current row.

		-- Fetch the next row into variables.

	-- 5. Close the cursor.

	-- 6. Deallocate the cursor.



-- The following example uses a cursor to compute the running total quantity for each customer & month from the `Sales.CustOrders` view:

USE TSQLV6;

SET NOCOUNT ON; -- Suppress messages indicating how many rows were affected

DECLARE @Result AS TABLE ( -- Table variable to hold the final result
	custid		INT,
	ordermonth	DATE,
	qty			INT,
	runqty		INT,
	PRIMARY KEY (custid, ordermonth)
);

DECLARE @custid AS INT, -- Local variables for intermediate values
	@prvcustid AS INT,
	@ordermonth AS DATE,
	@qty AS INT,
	@runqty AS INT;

-- Step 1: Declare the cursor.

DECLARE C CURSOR FAST_FORWARD FOR
	SELECT custid, ordermonth, qty
	FROM Sales.CustOrders
	ORDER BY custid, ordermonth;

-- Step 2: Open the cursor.

OPEN C;

-- Step 3: Fetch the first row.

FETCH NEXT FROM C INTO @custid, @ordermonth, @qty;

	-- Initialise empty variables.

SELECT @prvcustid = @custid, @runqty = 0;

-- Step 4: Loop through the cursor rows.

	-- In each iteration:
		
		-- Reset the running total when the customer changes

		-- Compute the running total

		-- Insert the result into the table variable

		-- Fetch the next row

WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @custid <> @prvcustid
			SELECT @prvcustid = @custid, @runqty = 0;
		SET @runqty = @runqty + @qty;
		INSERT INTO @Result VALUES(@custid, @ordermonth, @qty, @runqty);
		FETCH NEXT FROM C INTO @custid, @ordermonth, @qty;
	END;

-- Step 5: Close the cursor.

CLOSE C;

-- Step 6 Deallocate the cursor & return results

DEALLOCATE C;

SET NOCOUNT OFF;

SELECT custid,
	CONVERT(NVARCHAR(7), ordermonth, 121) AS ordermonth,
	qty, runqty
FROM @Result
ORDER BY custid, ordermonth;



-- As mentioned earlier, modern versions of T-SQL support window functions that provide a far more elegant & efficient solution to this problem, eliminating the need for cursors entirely:

SELECT custid, ordermonth, qty,
	SUM(qty) OVER (PARTITION BY custid ORDER BY ordermonth ROWS UNBOUNDED PRECEDING) AS runqty
FROM Sales.CustOrders
ORDER BY custid, ordermonth;

-- This approach is both simpler & significantly more efficient, & it should be preferred whenever it is available.