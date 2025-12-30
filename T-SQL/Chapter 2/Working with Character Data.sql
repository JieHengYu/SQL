----------------------------------------

-- Working with Character Data

----------------------------------------

-- In this section, we'll discuss query manipulation of character data, including data types, collation, operators, functions & pattern matching



-----------------------
-- Data Types
-----------------------

-- SQL Server has two main character data type pairs:

	-- Regular types: CHAR, VARCHAR

	-- N-types: NCHAR, NVARCHAR (the 'N' stands for National)

-- Here are their key differences:

-- 1. Encoding & Unicode Support

	-- Before SQL Server 2019, regular types only supported characters from the code page of the collation. Since 2019, with UTF-8 collations, they support the full Unicode range.

	-- N-types use UTF-16 with supplementary character-enabled collations (SC), otherwise UCS-2. They also support the full Unicode with the right collation.

-- 2. Size Specification

	-- For regular types (`VARCHAR(10)`), the number refers to bytes. Some characters may need more than one byte.

	-- For N-types (`NVARCHAR(10)`), the number refers to byte pairs (20 bytes total). Some characters may need more than one byte pair.

-- 3. Storage Efficiency

	-- ASCII characters (0-127) are more space efficient with UTF-8 regular types (1 byte per character) than with UTF-16 N-types (2 bytes per character).

	-- For some language (e.g., East Asian scripts), N-types can be more efficient.

-- 4. Literals

	-- Regular Type Literal: `'Text'`

	-- N-Type Literal: `N'Text'`

-- 5. Fixed vs. Variable Length

	-- Fixed-length (CHAR, NCHAR) always reserve the full defined size, regardless of actual data -> efficient for writes but wasteful in storage & slower for reads.

	-- Variable-length (VARCHAR, NVARCHAR) only use the space needed plus 2 bytes overhead -> more storage efficient & faster for reads, but updates may require row expansion.

-- 6. MAX Specifier

	-- `VARCHAR(MAX)` & `NVARCHAR(MAX)` allow values up to 2GB.

	-- Data up to 8,000 bytes is stored inline; larger values are stored externally as LOBs.



-- In short, regular types (CHAR, VARCHAR) vs. N-types (NCHAR, NVARCHAR) mainly differ in encoding (UTF-8 vs. UTF-16), storage efficiency, & how size is measured. Fixed-length types waste space but are write-friendly, while 

-- variable-length types save space but can be slower to update. MAX allows very large values stored as LOBs.



----------------------
-- Collation
----------------------

-- Collation is a property of character data that controls language support, sort order, case sensitivity, accent sensitivity, & related rules. To get the set of supported collations & their descriptions, we can query the table 

-- function fn_helpcollations:

USE TSQLV6;

SELECT name, description
FROM sys.fn_helpcollations();

-- For example, the collation `Latin1_General_CI_AS`:

	-- Latin1_General: uses code page 1252 (supports English, German, & most Western European characters).

	-- Dictionary sorting: uses default ordering (A/a < B/b). If BIN is specified instead, sorting is binary (A < B < a < b).

	-- CI: is case insensitive (a = A).

	-- AS: the data is accent sensitive (à <> ä).



-- In an on-premises SQL Server implementation & Azure SQL Managed Instance, collation can be defined at four different levels: instance, database, column & expression. The lowest level is the effective one that is used. In Azure SQL

-- Database, collation can be defined at the database, column, & expression levels.



-- When we install SQL Server, we must pick a default collation for the whole instance (the "instance collation").

	-- This instance-level collation automatically applies to all the system databases (`master`, `model`, `msdb`, `tempdb`).

	-- Any new user database we create will also inherit this collation by default, unless we explicitly override it with a COLLATE clause when creating the database.



-- The database collation determines both the collation of metadata (such as object & column names) & the default collation for user table columns. This is important because metadata collation directly affects naming rules. For

-- example, in a case-insensitive collation, we cannot create two tables name `T1` & `t1` within the same schema, whereas a case-sensitive collation would allow it.



-- It's worth noting, hoever, that the collation of variables & parameter identifiers is controlled by the instance collation, not the database collation -- regardless of which database we are connected to. For example, if the

-- instance collation is case-insensitive & the database collation is case-sensitive, we still cannot declare both `@P` & `@p` in the same scope. Doing so would result in an error stating that the variable name has already been 

-- declared.



-- We can explicitly specify a collation for a column as part of its definition by using the COLLATE clause. If we don't, the database collation is assumed by default. For example, suppose our database uses a case-insensitive

-- collation (`Latin1_General_CI_AS`):

-- CREATE TABLE Employees (
--     LastName VARCHAR(50) -- inherits database collation (case-insensitive)
-- );

-- Here, `'smith'` = `'SMITH'`. But, if we explicitly set the column collation:

-- CREATE TABLE Employees (
--     LastName VARCHAR(50) COLLATE Latin1_General_CS_AS -- (case-sensitive collation)
-- );

-- Now, `'smith'` != `'SMITH'`, because the column is case-sensitive, even though the rest of the database isn't.



-- We can also use the COLLATE clause to convert the collation of an expression. For example, in a case-insensitive environment, the following query uses a case-insensitive comparison:

SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname = N'davis';

-- The query returns the row for Sara Davis, even though the casing doesn't match, because the effective casing is insensitive. If we want to make the filter case sensitive, even though the column's case collation is case insensitive,

-- we can convert the collation of the expression:

SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname COLLATE Latin1_General_CS_AS = N'davis';

-- This time, the query returns an empty set because no match is found when a case-sensitive comparison is used.



-----------------------------------
-- Operators & Functions
-----------------------------------

-- This section covers string concatenation & functions that operate on character strings. For string concatenation, T-SQL provides the plus-sign (+) operator & the CONCAT & CONCAT_WS functions. For other commonly used operations on 

-- character strings, T-SQL provides SUBSTRING, LEFT, RIGHT, LEN, DATALENGTH, CHARINDEX, PATINDEX, REPLACE, TRANSLATE, REPLICATE, STUFF, UPPER, LOWER, RTRIM, LTRIM, TRIM, FORMAT, COMPRESS, DECOMPRESS, STRING_SPLIT, & STRING_AGG. 

-- Note that most of these functions are implementation-specific, meaning that they may not be portable to another database system without modification.

--------------------------------------------------------------------------------------------
-- String Concatenation (Plus-Sing [+] Operator & CONCAT & CONCAT_WS Functions)
--------------------------------------------------------------------------------------------

-- T-SQL supports string concatenation using the plus sign (+) operator, as well as the CONCAT & CONCAT_WS functions. For example, the following query on the `HR.Employees` table creates a `fullname` column by combining `firstname`,

-- a space, & `lastname`:

SELECT empid, firstname + N' ' + lastname AS fullname
FROM HR.Employees;



-- By default, T-SQL follows the SQL standard, which specifies that concatenating a NULL with any value results in NULL. For example, consider the following query on the `Sales.Customers` table:

SELECT custid, country, region, city, -- (Sample Query 2-7)
	   country + N',' + region + N',' + city AS location
FROM Sales.Customers;

-- The `region` column in the `Sales.Customers` table has NULL values for some rows. For the rows with NULL values, SQL Server returns a NULL in the `location` result column.



-- To substitute a NULL with an empty string, we can use the COALESCE function. This function accepts a list of input values & returns the first input that is not NULL. Here's how we can revise the query above to substitute NULLs 

-- with empty strings:

SELECT custid, country, region, city,
	   country + COALESCE(N',' + region, N'') + N',' + city AS location
FROM Sales.Customers;

-- In rows where the `region` column is NULL, `N',' + region` will also be NULL & the COALESCE function will return an empty string.



-- T-SQL provides the CONCAT function, which can take multiple input values & automatically treats NULLs as empty strings. For example, `CONCAT('a', NULL, 'b')` returns `'ab'`. Here's how to use the CONCAT function to combine

-- customers' location elements, ensuring that any NULL values are replaced with empty strings:

SELECT custid, country, region, city,
	   CONCAT(country, N',' + region, N',' + city) AS location
FROM Sales.Customers;



-- T-SQL also supports the CONCAT_WS function, which combines multiple input elements using a specified separator & automatically treats NULLs as empty strings. Here's how to use the CONCAT_WS function to combine the customers' 

-- location elements:

SELECT custid, country, region, city,
	   CONCAT_WS(N',', country, region, city) AS location
FROM Sales.Customers;



------------------------------
-- The SUBSTRING Function
------------------------------

-- The SUBSTRING function operates on an input `string` & extracts a substring starting at the position `start` that is `length` characters long.

	-- Syntax: `SUBSTRING(string, start, length)`

--  For example, the following code takes the input string `'abcde'` & extracts three characters starting the character at the position 1:

SELECT SUBSTRING('abcde', 1, 3);

-- If the value of the third argument exceeds the length of characters of the input string, the function returns everything until the end without raising an error. 

SELECT SUBSTRING('abcdefg', 3, 10);

-- This can be convenient when we want to return everything from a certain point until the end of the string. We can simply specify the maximum length of the data type or a value representing the full length of the input string.



----------------------------------
-- The LEFT & RIGHT Functions
----------------------------------

-- The LEFT & RIGHT functions are abbreviations of the SUBSTRING function, returning the requested number of characters from the left & right end of the input string.

	-- Syntax: `LEFT(string, n)`, `RIGHT(string, n)`

-- The functions extract `n` number of characters from the left or right of the input `string`. For example, the following code returns the three rightmost characters from the input string `'abcde'`:

SELECT RIGHT('abcde', 3);



-------------------------------------------
-- The LEN & DATALENGTH Functions
-------------------------------------------

-- The LEN function returns the number of characters in the input string.

	-- Syntax: `LEN(string)`

-- Note that this function returns the number of characters in the input string & not necssarily the number of bytes used to represent it. For example, with regular character types, when using English characters in the ASCII 0-127 code

-- range, both numbers are the same because each character is represented with 1 byte. With N-kind character types, the same characters are represented with 2 bytes; therefore, the number of characters is half the number of bytes. To

-- get the number of bytes, use the DATALENGTH function instead of LEN. For example, the following code returns 5:

SELECT LEN(N'abcde');

-- The following code returns 10:

SELECT DATALENGTH(N'abcde');

-- Another difference between LEN & DATALENGTH is that the former excludes trailing spaces but the latter doesn't.

SELECT LEN(N'abcde   ');

SELECT DATALENGTH(N'abcde   ');



----------------------------------
-- The CHARINDEX Function
----------------------------------

-- The CHARINDEX function returns the position of the first occurence of a substring within a string.

	-- Syntax: `CHARINDEX(substring, string[, start_pos])`

-- This function searches for the first argument, `substring`, inside the second argument, `string`. For example, the following code returns the position of the first space in `'Itzik Ben-Gan'`, so it returns the output 6:

SELECT CHARINDEX(' ', 'Itzik Ben-Gan');

-- An optional third argument `start_pos` specifies the position to begin the search; if omitted, the search starts at the first character. If the substring is not found, the function returns 0.

SELECT CHARINDEX('-', 'Skibidi-toilet-rizz', 10);

SELECT CHARINDEX(' ', 'Skibidi-toilet-rizz', 10);



------------------------------
-- The PATINDEX Function
------------------------------

-- The PATINDEX function returns the position of the first occurrence of a pattern within a string.

	-- Syntax: `PATINDEX(pattern, string)`

-- The argument `pattern` uses similar patterns to those used by the LIKE predicate in T-SQL. The following query searches for the position of the first occurrence of a digit within a string:

SELECT PATINDEX('%[0-9]%', 'abcd123efgh');



------------------------------
-- The REPLACE Function
------------------------------

-- The REPLACE function replaces all occurrences of `substring1` in `string` with `substring2` .

	-- Syntax: `REPLACE(string, substring1, substring2)`

-- For example, the following query substitutes all occurrences of a dash (-) in the input string with a colon (:):

SELECT REPLACE('1-a 2-b', '-', ':');



-- We can use the REPLACE function to count the number of occurrences of a specified character within a string. To do this, we'll replace all occurrences of the specified character with an empty string (zero characters), & calculate

-- the length of the original string minus the length of the new string. The following query returns the number of times the character `'e'` appears in the last name of each employee.

SELECT empid, lastname,
	   LEN(lastname) - LEN(REPLACE(lastname, 'e', '')) AS numoccur
FROM HR.Employees;



-------------------------------
-- The TRANSLATE Function
-------------------------------

-- The TRANSLATE function replaces each character in the input `string` that matches each character from the `characters` parameter with their corresponding character in the `translations` parameter.

	-- Syntax: TRANSLATE(string, characters, translations)

-- The TRANSLATE function can be thought of as a more flexible alternative to REPLACE, as it allows multiple single-character substitutions in a single expression. For example, consider the input string `'123.456.789,00'`, which

-- represents a number in Spanish format. To convert it into US format, we can swap the dots & commmas, producing `'123,456,789.00'`.



-- When using REPLACE, it's easy to fall into a common swap trap, where nested replacements substitute all occurrences of one character with another because the replacements are applied sequentially. Here's an example of an

-- expression that demonstrates this issue:

SELECT REPLACE(REPLACE('123.456.789,00', '.', ','), ',', '.');

-- First, all dots are substituted with commas. After this substitution, there are only commas in the string. Then we replace all occurences of commas with dots, returning the output `'123.456.789.00'`. To avoid this issue, we can insert an 

-- intermediate replacement step that temporarily substitutes one of the swap characters with a third character not found in the input string, like so:

SELECT REPLACE(REPLACE(REPLACE('123.456.789,00', '.', '~'), ',', '.'), '~', ',');

-- This time, we get the correct output: `'123,456,789.00'`.



-- It's easy to see how this procedure quickly becomes cumbersome when multiple character swaps are required. A cleaner solution is to use the TRANSLATE function:

SELECT TRANSLATE('123.456.789,00', '.,', ',.');

-- Notice the syntax: instead of listing character pairs, we first specify all the characters to be replaced, followed by their corresponding replacements in the same order. This produces the correct result `'123,456,789.00'`.



--------------------------------
-- The REPLICATE Function
--------------------------------

-- The REPLICATE function replicates an input `string` a requested `n` number of times.

	-- Syntax: `REPLICATE(string, n)`

-- For example, the following code replicates the string `'abc'` three times:

SELECT REPLICATE('abc', 3);



-- The next example demonstrates the REPLICATE function together with RIGHT & string concatenation. The following query against the `Production.Suppliers` table produces a 10-digit string representation of the supplier ID, padded with 

-- leading zeros:

SELECT supplierid,
	   RIGHT(REPLICATE('0', 9) + CAST(supplierid AS VARCHAR(10)), 10) AS strsupplierid
FROM Production.Suppliers;

-- To produce the result column `strsupplierid`, the query first uses REPLICATE to generate a string of nine zeros (`'000000000'`). The CAST function then converts the supplier ID from an integer to a VARCHAR. This zero string is 

-- concatenated with the converted supplier ID, & finally, the RIGHT function extracts the 10 rightmost characters to form the result.



--------------------------
-- The STUFF Function
--------------------------

-- The STUFF function modifies a given input string by deleting a specified number of characters & inserting another string in their place. It starts at the position defined by the `pos` parameter, removes the number of characters

-- indicated by `delete_length`, & then inserts the `insert_string` at that same position.

	-- Syntax: `STUFF(string, pos, delete_length, insert_string)`

-- For example, the following code operates on `'xyz'`, removes one character starting at position 2, & inserts `'abc'` in its place:

SELECT STUFF('xyz', 2, 1, 'abc');

-- If we just want to insert a string without deleting anything, we can specify a length of 0 as the third argument. 

SELECT STUFF('xyz', 2, 0, 'abc');

-- If we only want to delete a substring but not insert anything instead, specify a NULL as the fourth argument.

SELECT STUFF('xyz', 2, 1, NULL);



------------------------------------
-- The UPPER & LOWER Functions
------------------------------------

-- The UPPER & LOWER functions return the input string with all uppercase or lowercase characters, respectively.

	-- Syntax: `UPPER(string)`, `LOWER(string)`

-- For example, the following code returns `'ITZIK BEN-GAN'`:

SELECT UPPER('Itzik Ben-Gan');

-- The following code returns `'itzik ben-gan'`:

SELECT LOWER('Itzik Ben-Gan');



-----------------------------------------------
-- The RTRIM, LTRIM, & TRIM Functions
-----------------------------------------------

-- The various trim functions allow us to remove leading, trailing, or both leading & trailing characters from the input string. The LTRIM & RTRIM functions remove the leading or trailing spaces from the input string, respectively.

	-- Syntax: `RTRIM(string)`, `LTRIM(string)`

-- To remove both leading & trailing spaces, we can use the result of LTRIM as the input to RTRIM, or the other way around. For example, the following code removes both leading & trailing spaces from the input string:

SELECT RTRIM(LTRIM('   abc   '));

-- A simpler option is to use the TRIM function, which removes both leading & trailing spaces, like so:

SELECT TRIM('   abc   ');



-- But, there's more! The TRIM function has more sophisticaed capabilities. Let's start with the function's syntax:

	-- Syntax: `TRIM([characters FROM] string)`

-- If we provide just the input `string`, the TRIM function indeed removes only leading & trailing spaces. However, there is an optional `characters` input (square brackets in syntax definition means that the syntax element is optional), 

-- which allows us to be specific about the list of individual characters that we want to trim from the start & end of the input `string`. Attempting to trim nonspace characters from the edges of an input string can be quite tricky 

-- without this optional input, especially if those characters can appear in other places beyond the beginning & end. For example, suppose that we need to remove all leading & trailing slashes from an input string. We'll use the 

-- following as our sample input string:

	-- `'//\\ remove leading & trailing backward (\) & forward (/) slashes \\//'`

-- Here's the correct desired result string after trimming:

	-- `' remove leading & trailing backward (\) & forward (/) slashes '`

-- Notice that the output should keep the leading & trailing spaces.



-- If the TRIM function did not support specifying which characters to remove, we would need a much more complex expression, such as the following:

SELECT TRANSLATE(TRIM(TRANSLATE(TRIM(TRANSLATE(
	   '//\\ remove leading & trailing backward (\) & forward (/) slashes \\//',
	   ' /', '~ ')), ' \', '^ ')), ' ^~', '\/ ') AS outputstring;

-- In the first TRANSLATE & TRIM expression, TRANSLATE replaces all spaces with ~ & foward slashes with spaces. TRIM then removes leading & trailing spaces from the result, which has the effect of trimming leading & trailing forward

-- slahes. At this stage, spaces are represented by ~.

	-- `'\\~remove~leading~&~trailing~backward~(\)~&~forward~()~slashes~\\'`

-- In the second TRANSLATE & TRIM expression, TRANSLATE replaces spaces with ^, & backward slashs with spaces. TRIM again removes leading & trailing spaces, effectively trimming backward slashes this time. Now, intermediate spaces are 

-- temporarily held as ^.

	-- `'~remove~leading~&~trailing~backward~()~&~forward~(^)~slashes~'`

-- The final TRANSLATE function restores the original characters by mapping spaces with backward slashes, ^ with forward slashes, & ~ with spaces, generating the desired result:

	-- `' remove leading & trailing backward (\) & forward (/) slashes '`



-- The task becomes simpler when we specify the optional `characters` input in the TRIM function:

SELECT TRIM('/\' FROM
	   '//\\ remove leading & trailing backward (\) & forward (/) slashes \\//') AS outputstring;



-- The various trim functions were enhanced in SQL Server 2022 to provide more functionality. Here's the enhanced TRIM function's syntax:

	-- `TRIM([LEADING|TRAILING|BOTH] [characters FROM] string)`

-- Instead of always trimming both leading & trailing characters, which is the default, we can now be explicit about whether we want to trim leading characters, trailing characters, or both leading & trailing characters.



-- As for the LTRIM & RTRIM functions, here's their enhanced syntax:

	-- `RTRIM(string, [characters])`, `LTRIM(string, [characters])`

-- The enhancement is an optional `characters` input, which allows us to specify special characters that we want to remove instead of the default spaces, similar to the optional `characters` input that we can specify with the TRIM

-- function.



-- With these enhancements, there's really no need for three separate functions anymore. It's sufficient to use TRIM alone, adding the keyword LEADING (instead of using LTRIM) or TRAILING (instead of using RTRIM). Or in more detail,

-- instead of using:

	-- `RTRIM(string, [characters])`

-- We can use:

	-- `TRIM(TRAILING [characters FROM] string)`

-- And instead of using:

	-- `LTRIM(string, [characters])`

-- We can use:

	-- `TRIM(LEADING [characters FROM] string)`



-----------------------------
-- The FORMAT Function
-----------------------------

-- We use the FORMAT function to format an input value as a character string.

	-- Syntax: `FORMAT(input, format_string, culture)`

-- There are numerous possibilities for formatting inputs. As a simple example, recall the convoluted expression used earlier to format a number as a 10-digit string with leading zeros. By

-- using FORMAT, we can achieve the same task with either the custom format string `'0000000000'` or a standard one, `'d10'`. As an example, the following code returns `'0000001759'`:

SELECT FORMAT(1759, '0000000000');

SELECT FORMAT(1759, 'd10');



---------------------------------------------------
-- The COMPRESS & DECOMPRESS Functions
---------------------------------------------------

-- The COMPRESS & DECOMPRESS functions use the GZIP algorithm to compress & decompress the input, respectively.

	-- Syntax: `COMPRESS(string)`, `DECOMPRESS(string)`

-- The COMPRESS function takes a character or binary string as input & returns a compressed value of type `VARBINARY(MAX)`. For example, the following query compresses a constant string:

SELECT COMPRESS(N'This is my csv. Imagine it was longer.');

-- The result is a binary value holding the compressed form of the input string. 



-- The DECOMPRESS function takes a binary string as input & returns a decompressed value of type `VARBINARY(MAX)`. If the original data was a character string, we must explicitly cast the result of DECOMPRESS back to the desired type.

-- For example, the following query does not return the origianl string -- it returns a binary value:

SELECT DECOMPRESS(COMPRESS(N'This is my cv. Imagine it was much longer.')); 

-- To restore the original string, cast the result to the appropriate character type:

SELECT CAST(DECOMPRESS(COMPRESS(N'This is my cv. Imagine it was longer.')) AS NVARCHAR(MAX));



----------------------------------
-- The STRING_SPLIT Function
----------------------------------

-- The STRING_SPLIT table function splits an input string containing a separated list of values into the individual elements.

	-- Syntax: `SELECT value 
	--          FROM STRING_SPLIT(string, separator[, enable_ordinal]);`

-- Unlike the string functions discussed so far, which are all scalar functions, STRING_SPLIT is a table-valued function. It takes as input a string containing a list of values, a separator, & -- starting with SQL Server 2022,

-- an optional flag that specifies whether to include an ordinal position column in the output. The function returns a table with a string column named `value`, which contains the individual elements. If the ordinal flag is enabled,

-- it also includes an integer column named `ordinal` that indicates each element's position.



-- If we need the elements in a data type other than a character string, we must cast the `value` column to the target type. For example, the following code splits the input string `'10248, 10249, 10250'` using a comma as a

-- separator & returns the result as a table (aliased as `S`) containing the individual elements:

SELECT CAST(value AS INT) AS myvalue
FROM STRING_SPLIT('10248,10249,10250', ',') AS S;

-- In this example, the input list contains values representing order IDs. Because the IDs are supposed to be integers, the query converts the `value` column to the INT data type.



-- In case you're using SQL Server 2022 or later, here's an example with the ordinal flag enabled:

SELECT CAST(value AS INT) AS myvalue, ordinal
FROM STRING_SPLIT('10248,10249,10250', ',', 1) AS S;



---------------------------------
-- The STRING_AGG Function
---------------------------------

-- The STRING_AGG aggregation function concatenates values from the input expression across the rows of a group. Conceptually, it works as the inverse of the STRING_SPLIT function. 

	-- Syntax: `STRING_AGG(input, separator) [WITHIN GROUP(order_specification)]`

-- The function joins the values of the `input` expression, separated by the `separator` argument. To control the order of the concatenation, we must use the optional WITHIN GROUP clause with the desired ordering. For example, the

-- following query returns the order IDs for each customer, ordered by recency, with values separated by commas:

SELECT custid,
	   STRING_AGG(CAST(orderid AS VARCHAR(10)), ',')
		   WITHIN GROUP(ORDER BY orderdate DESC, orderid DESC) AS custorders
FROM Sales.Orders
GROUP BY custid;



-- If `input` is of type VARCHAR, the result is also VARCHAR; otherwise, the output is NVARCHAR (with implicit conversion if necessary). In the example above, `orderid` is an INT, so it is explicitly cast to VARCHAR to ensure the

-- output is VARCHAR.



-- Regarding size, if `input` is `VARCHAR(MAX)` or `NVARCHAR(MAX)`, the result is also MAX. For limited-size inputs (`VARCHAR(n) up to 8000 or `NVARCHAR(n)` up to 4000), the output uses the maximum supported size (`VARCHAR(8000)`

-- or `NVARCHAR(4000)`).



----------------------------
-- The LIKE Predicate
----------------------------

-- T-SQL provides the LIKE predicate, which is used to test whether a character string matches a specified pattern. The syntax for these patterns is similar to those used by the PATINDEX function described earlier. The following 

-- section introduces the supported wildcards & demonstrates how they are used.



------------------------------------
-- The % (Percent) Wildcard
------------------------------------

-- The percent sign represents a string of any size, including an empty string. For example, the following query returns employees whose last name starts with D:

SELECT empid, lastname
FROM HR.Employees
WHERE lastname LIKE N'D%';



----------------------------------------
-- The _(Underscore) Wildcard
----------------------------------------

-- An underscore represents a single character. For example, the following query returns employees whose second character in their last name is e:

SELECT empid, lastname
FROM HR.Employees
WHERE lastname LIKE N'_e%';



-----------------------------------------------
-- The [<List of Characters>] Wildcard
-----------------------------------------------

-- Square brackets with a list of characters (such as [ABC]) represents a single character that must be one of the characters specified in the list. For example, the following query returns employees whose first character in their

-- last name is A, B, or C:

SELECT empid, lastname
FROM HR.Employees
WHERE lastname LIKE N'[ABC]%';



-------------------------------------------------
-- The [^<Character List or Range>] Wildcard
-------------------------------------------------

-- Square brackets with a caret sign (^) followed by a character list or range (such as [^A-E]) represent a single character that is not in the specified character list or range. For example, the following query returns employees whose

-- first character in their lastname is not a letter in the range A through E:

SELECT empid, lastname
FROM HR.Employees
WHERE lastname LIKE N'[^A-E]%';



------------------------------
-- The ESCAPE Character
------------------------------

-- If we need to search for a character that also serves as a wildcard (%, _, [, or ]), we can use an escape character. Choose a character that you know does not appear in the data, place it before the wildcard character, & then 

-- specify it with the ESCAPE keyword immediately after the pattern. For example, the following expression checks whether the column `col1` contains an underscore:

	-- `col1 LIKE '%!_%' ESCAPE '!'`



-- For the wildcards %, _, & [, we can also use square brackets instead of an escape character. For example, instead of:

	-- `col1 LIKE '%!_%' ESCAPE '!'`

-- We can write:

	-- `col1 LIKE '%[_]%'`