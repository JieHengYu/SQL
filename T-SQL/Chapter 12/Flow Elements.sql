---------------------

-- Flow Elements

---------------------

-- We use flow elements to control the execution path of our code. T-SQL provides several basic flow-control constructs, including the IF...ELSE statement & the WHILE loop.



--------------------------------------
-- The IF...ELSE Flow Element
--------------------------------------

-- The IF...ELSE element allows us to control the flow of code based on the result of a predicate. We specify a statement or statement block that executes when the predicate evaluates to TRUE, & optionally a statement or

-- statement block that executes when the predicate evaluates to FALSE or UNKNOWN.



-- For example, the following code checks whether today is the last day of the year. It does this by comparing today's year with tomorrow's year. If the two values are different, today must be the last day of the year. If they

-- are the same, then it is not:

USE TSQLV6;

IF YEAR(SYSDATETIME()) <> YEAR(DATEADD(day, 1, SYSDATETIME()))
	PRINT 'Today is the last day of the year.';
ELSE
	PRINT 'Today is not the last day of the year.';

-- In this example, we use PRINT statements to illustrate which branch of the code is executed. In practice, however, the IF & ELSE branches can contain any valid T-SQL statements.



-- Keep in mind that T-SQL uses three-valued logic. As a result, the ELSE block executes when the predicate evaluates to either FALSE or UNKNOWN. In scenarios where both FALSE or UNKNOWN are possible outcomes -- for example,

-- when NULL values are involved -- & we need to handle them differently, we should explicitly test for NULL using the IS NULL predicate.



-- When the logic requires handling more than two cases, we can nest IF...ELSE elements. For instance, the following example handles three distinct cases:

	-- Today is the last day of the year.

	-- Today is the last day of the month, but not the last day of the year.

	-- Today is not the last day of the month.

IF YEAR(SYSDATETIME()) <> YEAR(DATEADD(day, 1, SYSDATETIME()))
	PRINT 'Today is the last day of the year.';
ELSE
	IF MONTH(SYSDATETIME()) <> MONTH(DATEADD(day, 1, SYSDATETIME()))
		PRINT 'Today is the last day of the month but not the last day of the year.';
	ELSE
		PRINT 'Today is not the last day of the month.';

-- If we need to execute more than one statement in either the IF or ELSE branch, we must use a statement block. Statement blocks are defined using the BEGIN & END keywords. The following example demonstrates how to execute one

-- set of statements when today is the first day of the month, & a different set when it is not:

IF DAY(SYSDATETIME()) = 1
	BEGIN
		PRINT 'Today is the first day of the month.';
		PRINT 'Starting first-of-month-day process.';
		PRINT 'Finished first-of-month-day database process.';
	END;
ELSE 
	BEGIN
		PRINT 'Today is not the first day of the month.';
		PRINT 'Starting non-first-of-month-day process.';
		PRINT 'Finished non-first-of-month-day process.';
	END;



-------------------------------
-- The WHILE Flow Element
-------------------------------

-- T-SQL provides the WHILE element, which we use to execute code repeatedly in a loop. A WHILE loop executes a statement or statement block as long as the predicate specified after the WHILE keyword evaluates to TRUE. When the

-- predicate evaluates to FALSE or UNKNOWN, the loop terminates.



-- T-SQL does not provide a built-in looping construct that executes a predetermined number of times (such as a FOR loop). However, this behaviour is easy to emulate by using a WHILE loop together with a variable that acts as a

-- loop counter. For example, the following code demonstrates how to write a loop that iterates exactly 10 times:

DECLARE @i AS INT = 1;
WHILE @i <= 10
	BEGIN
		PRINT @i;
		SET @i += 1;
	END;

-- In this example, we declare an integer variable named `@i` & initialise it to 1. This variable serves as the loop counter. The loop executes as long as `@i` is less than or equal to 10. During each iteration, the code prints

-- the current value of `@i` & then increments it by 1. The output confirms that the loop executes exactly 10 times.



-- At times, we may want to exit a loop before its predicate evaluates to FALSE. To do this, we can use the BREAK command, which immediately terminates the current loop & transfers control to the statement that follows the loop.

-- For example, the following code breaks out of the loop when the value of `@i` reaches 6:

DECLARE @i AS INT = 1;
WHILE @i <= 10
	BEGIN
		IF @i = 6 BREAK;
		PRINT @i;
		SET @i += 1;
	END;

-- The output shows that the loop runs five times & terminates at the start of the sixth iteration. While this specific example is not particularly practical -- since we could instead specify the predicate `@i <= 5` -- it serves

-- to illustrate the behaviour of the BREAK command.



-- In contrast, if we want to skip the remainder of the current iteration & immediately re-evaluate the loop's predicate, we can use the CONTINUE command. This causes execution to jump back to the beginning of the loop without 

-- executing any remaining statements in the current iteration. The following example demonstrates how to skip the sixth iteration of the loop:

DECLARE @i AS INT = 0;
WHILE @i < 10
	BEGIN
		SET @i += 1;
		IF @i = 6 CONTINUE;
		PRINT @i;
	END;

-- The output shows that the value of `@i` is printed for every iteration except the sixth, where the CONTINUE statement bypasses the PRINT statement. 



-- As another example of using a WHILE loop, the following code creates a table named `dbo.Numbers` & populates it with 1,000 rows containing the values 1 through 1,000 in the column `n`:

SET NOCOUNT ON;
DROP TABLE IF EXISTS dbo.Numbers;
CREATE TABLE dbo.Numbers(n INT NOT NULL PRIMARY KEY);
GO

DECLARE @i AS INT = 1;
WHILE @i <= 1000
	BEGIN
		INSERT INTO dbo.Numbers(n) VALUES(@i);
		SET @i += 1;
	END;

SELECT * FROM dbo.Numbers;

-- This example illustrates a common pattern in T-SQL: using a WHILE loop & a counter variable to generate a sequence of values & perform repeated operations, such as populating a table.

