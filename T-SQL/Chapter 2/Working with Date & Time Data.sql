----------------------------------------

-- Working with Date & Time Data

----------------------------------------

-- Working with dates & times in SQL can be tricky. This section explains the recommended data types & highlights key date- & time-related functions.



----------------------------------
-- Date & Time Data Types
----------------------------------

-- T-SQL provides six date & time data types. The legacy types -- DATETIME & SMALLDATETIME -- store both date & time as inseparable components, differing mainly in storage size, range, & precision. The DATE & TIME types allow you to work with these components

-- separately when needed. DATETIME2 offers a wider date range & higher precision than the legacy types, while DATETIMEOFFSET extends DATETIME2 by including a UTC offset.



-- The table below lists details about date & time data types, including their storage requirements, supported date range, precision, & recommended entry format.

-- | Data Type      | Storage (bytes) | Date Range               | Precision          | Recommended Entry Format & Example        |
--  ---------------- ----------------- -------------------------- -------------------- -------------------------------------------
-- | DATETIME       | 8               | January 1, 1753, through | 3 1/3 milliseconds | 'YYYYMMDD hh:mm:ss.nnn'                   |
-- |                |                 | December 31, 9999        |                    | '20220212 12:30:15.123'                   |
--  ---------------- ----------------- -------------------------- -------------------- -------------------------------------------
-- | SMALLDATETIME  | 4               | January 1, 1900, through | 1 minute           | 'YYYYMMDD hh:mm'                          |
-- |                |                 | June 6, 2079             |                    | '20220212 12:30'                          |
--  ---------------- ----------------- -------------------------- -------------------- -------------------------------------------
-- | DATE           | 3               | January 1, 0001, through | 1 day              | 'YYYY-MM-DD'                              |
-- |                |                 | December 31, 9999        |                    | '2022-02-12'                              |
--  ---------------- ----------------- -------------------------- -------------------- ------------------------------------------- 
-- | TIME           | 3 to 5          | N/A                      | 100 nanoseconds    | 'hh:mm:ss.nnnnnnn'                        |
-- |                |                 |                          |                    | '12:30:15.1234567'                        |
--  ---------------- ----------------- -------------------------- -------------------- -------------------------------------------
-- | DATETIME2      | 6 to 8          | January 1, 0001, through | 100 nanoseconds    | 'YYYY-MM-DD hh:mm:ss.nnnnnnn'             |
-- |                |                 | December 31, 9999        |                    | '2022-02-12 12:30:15.1234567              |
--  ---------------- ----------------- -------------------------- -------------------- -------------------------------------------
-- | DATETIMEOFFSET | 8 to 10         | January 1, 0001, through | 100 nanoseconds    | 'YYYY-MM-DD hh:mm:ss.nnnnnnn [+|-] hh:mm' |
-- |                |                 | December 31, 9999        |                    | '2022-02-12 12:30:15.1234567 +02:00'      |
--  ---------------- ----------------- -------------------------- -------------------- -------------------------------------------



-- The storage requirements for TIME, DATETIME2, & DATETIMEOFFSET depend on the specified fractional-second precision, which can range from 0 to 7. This value determines how many digits are stored after the decimal point in the seconds portion. For example,

-- `TIME(0)` stores whole seconds only, `TIME(3)` stores milliseconds (three digits), & `TIME(7)` stores the maximum precision of 100-nanosecond units (seven digits). If no precision is specified, SQL Server uses a default of 7. When converting to a type with

-- lower precision, values are rounded to the nearest representable value.



----------------
-- Literals
----------------

-- When specifying a literal (constant) for a date or time type in T-SQL, a few points are worth nothing. T-SQL does not provide dedicated date or time literals. Instead, we supply a literal of another type that can be implicitly or explicitly converted. The

-- best practice is to use character string literals for date & time values, as shown in the following example:

USE TSQLV6;

SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE orderdate = '20220212';



-- SQL Server interprets `'20220212'` as a VARCHAR string, not as a date & time literal. Because the expression mixes data types, one operand must be implicitly converted. This conversion follows data type precedence, where SQL Server automatically converts 

-- the operand with lower precedence to the one with higher precedence. In this case, the VARCHAR literal is converted to the column's DATE type, since character strings rank lower than date & time types. In effect, SQL Server performs the conversion behind

-- the scenes, making the query logically equivalent to one that explicitly casts the string to DATE:

SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE orderdate = CAST('20220212' AS DATE);



-- Some character-string date & time formats are language dependent, meaning SQL Server may interpret them differently depending on the session's language setting. Each login has a default language defined by the database administrator, which becomes the

-- effective session language unless explicitly changed. While we can override it with SET LANGUAGE, this is generally discouraged because code may rely on the default setting. The session's language also controls related settings, including DATEFORMAT, which 

-- defines how SQL Server interprets date literals. DATEFORMAT is expressed as a combination of `d`, `m`, & `y`. For example, U.S. English uses `mdy`, while British English uses `dmy`. Although we can override this with `SET DATEFORMAT`, changing the 

-- language-dependent settings is usually not recommended.



-- Consider the literal`'02/12/2022'`. SQL Server can interpret it as either February 12, 2022 or December 2, 2022 when converted to DATETIME, SMALLDATETIME, DATE, DATETIME2 or DATETIMEOFFSET. The result depends on the session's LANGUAGE/DATEFORMAT setting.

-- The following code demonstrates these differences:

SET LANGUAGE British;
SELECT CAST('02/12/2022' AS DATE);

SET LANGUAGE us_english;
SELECT CAST('02/12/2022' AS DATE);

-- Notice that the literal is interpreted differently, depending on the different language environments.



-- Because code may be used by international users with different login language settings, it is important to recognise that some literal formats are language dependent. To avoid ambiguity, it is strongly recommended to use language-neutral literals, which

-- SQL Server interprets consistently regardless of language-related settings. The table below provides language-neutral formats for each of the date & time types:

-- | Data Type      | Recommended Entry Format                 | Example                              |
--  ---------------- ------------------------------------------ --------------------------------------
-- | DATETIME       | 'YYYYMMDD hh:mm:ss.nnn'                  | '20220212 12:30:15.123'              |
-- |                | 'YYYY-MM-DDThh:mm:ss.nnn'                | '2022-02-12T12:30:15.123'            |
-- |                | 'YYYYMMDD'                               | '20220212'                           |
--  ---------------- ------------------------------------------ --------------------------------------
-- | SMALLDATETIME  | 'YYYYMMDD hh:mm'                         | '20220212 12:30'                     |
-- |                | 'YYYY-MM-DDThh:mm'                       | '2022-02-12T12:30'                   |
-- |                | 'YYYYMMDD'                               | '20220212'                           |
--  ---------------- ------------------------------------------ --------------------------------------
-- | DATE           | 'YYYYMMDD'                               | '20220212'                           |
-- |                | 'YYYY-MM-DD'                             | '2022-02-12'                         |
--  ---------------- ------------------------------------------ --------------------------------------
-- | DATETIME2      | 'YYYYMMDD hh:mm:ss.nnnnnnn'              | '20220212 12:30:15.1234567'          |
-- |                | 'YYYY-MM-DD hh:mm:ss.nnnnnnn'            | '2022-02-12 12:30:15.1234567'        |
-- |                | 'YYYY-MM-DDThh:mm:ss.nnnnnnn'            | '2022-02-12T12:30:15.1234567'        |
-- |                | 'YYYYMMDD'                               | '20220212'                           |
-- |                | 'YYYY-MM-DD'                             | '2022-02-12'                         |
--  ---------------- ------------------------------------------ --------------------------------------
-- | DATETIMEOFFSET | 'YYYYMMDD hh:mm:ss.nnnnnnn [+|-]hh:mm'   | '20220212 12:30:15.1234567 +02:00'   |
-- |                | 'YYYY-MM-DD hh:mm:ss.nnnnnnn [+|-]hh:mm' | '2022-02-12 12:30:15.1234567 +02:00' |
-- |                | 'YYYYMMDD'                               | '20220212'                           |
-- |                | 'YYYY-MM-DD'                             | '2022-02-12'                         |
--  ---------------- ------------------------------------------ --------------------------------------
-- | TIME           | 'hh:mm:ss.nnnnnnn'                       | '12:30:15.1234567'                   |
--  ---------------- ------------------------------------------ --------------------------------------

-- A few points to note in this table:

	-- For types that include both date & time, if the literal omits the time, SQL Server assumes midnight.

	-- If no UTC offset is specified, SQL Server assumes `00:00`.

	-- The formats `'YYYY-MM-DD'` & `'YYYY-MM-DD hh:mm...'` are language dependent when converted to DATETIME & SMALLDATETIME, but language-neutral when converted to DATE, DATETIME2, & DATETIMEOFFSET.

-- For example, in the following code, the language setting does not affect how a literal in the `'YYYYMMDD'` format is interpreted when converted to DATE:

SET LANGUAGE British;
SELECT CAST('20220212' AS DATE);

SET LANGUAGE us_english;
SELECT CAST('20220212' AS DATE);

-- Using language neutral formats is highly recommended, because they are interpreted the same way regardless of the LANGUAGE/DATEFORMAT settings.



-- If you choose to use a language-dependent format for literals, you have two options. One is to use the CONVERT function, explicitly converting the character-string literal to the desired data type & specifying a style number (the third argument) that matches

-- the literal's format. For example, to interpret `'02/12/2022'` as MM/DD/YYYY, use style `'101'`:

SELECT CONVERT(DATE, '02/12/2022', 101);

-- This returns February 12, 2022, regardless of the session's language setting. To interpret the same literal as DD/MM/YYYY, use style `'103'`:

SELECT CONVERT(DATE, '02/12/2022', 103);

-- This returns December 2, 2022.



-- Another option is to use the PARSE function, which allows us to convert a value to a specific data type while specifying the culture. For example, the following is the equivalent of using CONVERT with style `'101'` (US English):

SELECT PARSE('02/12/2022' AS DATE USING 'en-US');

-- Similarly, the following is equivalent to style `'103'` (British English):

SELECT PARSE('02/12/2022' AS DATE USING 'en-GB');



--------------------------------------------
-- Working with Date & Time Separately
--------------------------------------------

-- If we need to work with only dates or only times, it is recommended to use the DATE & TIME data types, respectively. This guideline can be harder to follow when using legacy types like DATETIME & SMALLDATETIME, which include both date & time components, 

-- often necessary for compatability with older systems.



-- To demonstrate working with date & time separately, we'll use the table `Sales.Orders2`, which we'll create by copying `Sales.Orders` & casting the source `orderdate` column from DATE type to DATETIME. 

DROP TABLE IF EXISTS Sales.Orders2;

SELECT orderid, custid, empid, CAST(orderdate AS DATETIME) as orderdate
INTO Sales.Orders2
FROM Sales.Orders;

-- As mentioned, the `orderdate` column in the `Sales.Orders2` table is of the type DATETIME. Since only the date component is relevant, all values have midnight as the time. This allows us to filter orders for a specific date using a simple equality operator,

-- without needing a range filter:

SELECT orderid, custid, empid, orderdate
FROM Sales.Orders2
WHERE orderdate = '20220212';



-- When SQL Server converts a character-string literal containing only a date to DATETIME, it assumes midnight by default. We can enforce this behaviour using a CHECK constraint to ensure that the time part is always midnight:

ALTER TABLE Sales.Orders2
	ADD CONSTRAINT CHK_Orders2_orderdate
	CHECK(CONVERT(Char(12), orderdate, 114) = '00:00:00:000');

-- Here, the CONVERT function extracts the time portion of `orderdate` as a string in style `'114'` (hh:mm:ss.nnn). The CHECK constraint ensures that the time is midnight. 



-- If the time component is stored with nonmidnight values, we can use a range filter like this:

SELECT orderid, custid, empid, orderdate
FROM Sales.Orders2
WHERE orderdate >= '20220212'
	AND orderdate < '20220213';



-- If we need to work only with times using legacy types, we can store all values with the base date January 1, 1900. When a character-string literal contains only a time, SQL Server automatically assumes this base date for DATETIME or SMALLDATETIME. For

-- example:

SELECT CAST('12:30:15.123' AS DATETIME);



-- Suppose we have a table with a DATETIME column `tm`, where all values use the base date. This can be enforced with a CHECK constraint. To return all rows for which the time value is 12:30:15.123, we use the filter `WHERE tm = '12:30:15.123'`. Because we 

-- did not specify a date component, SQL Server assumes the base date by default when it implicitly converts character strings to a DATETIME data type.



-- If input values include both date & time components, the irrelevant part must be zeroed before storing, i.e., set time to midnight if storing only the date or set date to the base date if storing only the time. This ensures consistent behaviour when

-- filtering or comparing values, even when working with legacy types that always include both components.



-- When complete, run the following code for cleanup:

DROP TABLE IF EXISTS Sales.Orders2;



---------------------------------
-- Filtering Date Ranges
---------------------------------

-- When we need to filter a range of dates, such as a whole year or a whole month, it seems natural to use functions such as YEAR & MONTH.

SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE YEAR(orderdate) = 2021;



-- However, keep in mind that when we apply functions to other manipulations to a filtered column -- such as passing it to YEAR in the example above -- SQL Server often cannot use an index efficiently. To allow SQL Server to use an index efficiently, avoid

-- manipulating the column in the filter. For example, we can rewrite the previous query's filter predicate like this:

SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE orderdate >= '20210101'
	AND orderdate < '20220101';	

-- Similarly, instead of using functions to filter orders placed in a particular month, like this:

SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE YEAR(orderdate) = 2022 
	AND MONTH(orderdate) = 2;

-- We should instead use a range filter like so:

SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE orderdate >= '20220201'
	AND orderdate < '20220301';



----------------------------------
-- Date & Time Functions
----------------------------------

-- In this section, we'll describe functions that operate on date & time data types, including GETDATE, CURRENT_TIMESTAMP, GETUTCDATE, SYSDATETIME, SYSUTCDATETIME, SYSDATETIMEOFFSET, CAST, CONVERT, PARSE, SWITCHOFFSET, TODATETIMEOFFSET, AT TIME ZONE, DATEADD,

-- DATEDFIFF, DATEDIFF_BIG, DATEPART, YEAR, MONTH, DAY, DATENAME, DATETRUNC, ISDATE, various FROMPARTS functions, EOMONTH, & GENERATE_SERIES.



------------------------------
-- Current Date & Time
------------------------------

-- The functions in the table below return the current date & time values in the system where the SQL Server instance resides: 

-- | Function          | Return Type    | Description                                        |
--  ------------------- ---------------- ----------------------------------------------------
-- | GETDATE           | DATETIME       | Current date & time                                |
--  ------------------- ---------------- ----------------------------------------------------
-- | CURRENT_TIMESTAMP | DATETIME       | Same AS GETDATE but SQL-compliant                  |
--  ------------------- ---------------- ----------------------------------------------------
-- | GETUTCDATE        | DATETIME       | Current date & time in UTC                         |
--  ------------------- ---------------- ----------------------------------------------------
-- | SYSDATETIME       | DATETIME2      | Current date & time                                |
--  ------------------- ---------------- ----------------------------------------------------
-- | SYSUTCDATETIME    | DATETIME2      | Current date & time in UTC                         |
--  ------------------- ---------------- ----------------------------------------------------
-- | SYSDATETIMEOFFSET | DATETIMEOFFSET | Current date & time, including the offset from UTC |
--  ------------------- ---------------- ----------------------------------------------------

-- We need to specify empty parentheses with all of these functions, except the standard function CURRENT_TIMESTAMP, which requires no parentheses. Also, because CURRENT_TIMESTAMP & GETDATE return the same thing but only the former is standard, it is 

-- recommended that we use the former. In general, if there are several options with no functional or performance differences, use the standard option. The following code demonstrates using the current date & time functions:

SELECT
	GETDATE() AS [GETDATE],
	CURRENT_TIMESTAMP AS [CURRENT_TIMESTAMP],
	GETUTCDATE() AS [GETUTCDATE],
	SYSDATETIME() AS [SYSDATETIME],
	SYSUTCDATETIME() AS [SYSUTCDATETIME],
	SYSDATETIMEOFFSET() AS [SYSDATETIMEOFFSET];

-- Here, the square brackets define delimited identifiers for the target column names, since they are reserved keywords.



-- As you probably noticed, none of the functions return only the current system date or only the current system time. However, we can get these easily by converting CURRENT_TIMESTAMP or SYSDATETIME to DATE or TIME like this:

SELECT
	CAST(SYSDATETIME() AS DATE) AS [current_date],
	CAST(SYSDATETIME() AS TIME) AS [current_time];



------------------------------------------------------------------------------
-- The CAST, CONVERT, & PARSE Functions & Their TRY_ Counterparts
------------------------------------------------------------------------------

-- The CAST, CONVERT, & PARSE functions are used to convert an input value to a specified target type. If the conversion succeeds, the function returns the converted value; otherwise, the query fails. Each of these functions has a counterpart prefixed with

-- TRY_ -- TRY_CAST, TRY_CONVERT, & TRY_PARSE. These behave identically to their standard versions, except that if the input cannot be converted, they return NULL instead of failing the query.

	-- Syntax: `CAST(value AS datatype)`
	--         `TRY_CAST(value AS datatype)`
	--         `CONVERT(datatype, value[, style_number])`
	--         `TRY_CONVERT(datatype, value[, style_number])`
	--         `PARSE(value AS datatype [USING culture])`
	--         `TRY_PARSE(value AS datatype [USING culture])`

-- All three base functions convert the input `value` to the specified `datatype`. CONVERT optionally accepts a third argument, a style number, which specifies the format for conversions between character strings & date/time types. For example, style `'101'` 

-- indicates `'MM/DD/YYYY'`, & style `'103'` indicates `'DD/MM/YYYY'`. Similarly, PARSE allows specifying a culture, such as `'en-US'` for US English or `'en-GB'` for British English.



-- When converting from a character string to a data/time type, some string formats are language dependent. To avoid ambiguity, either use a language-neutral format or use CONVERT with an explicit style number. This ensures consistent behaviour regardless of 

-- the language setting of the session.



-- Also, note that CAST is standard & CONVERT & PARSE aren't, so unless we need to specify a style or culture, it is recommended that we use the CAST function for maximum portability.



-- Following are a few examples of using the CAST, CONVERT, & PARSE functions with date & time data types. The following code converts the character string literal `'20220212'` to a DATE data type:

SELECT CAST('20220212' AS DATE);

-- The following code converts the current system date & time value to a DATE data type, practically extracting only the current system date:

SELECT CAST(SYSDATETIME() AS DATE);

-- The following code converts the current system date & time value to a TIME data type, practically extracting only the current system time:

SELECT CAST(SYSDATETIME() AS TIME);



-- As noted earlier, if we must work with the legacy DATETIME or SMALLDATETIME types (for example, for compatibility with legacy systems) but want to represent only a date or only a time, we can set the irrelevant component to a fixed value. 

	-- To store only dates, set the time to midnight.

	-- To store only times, set the date to the base date January 1, 1900.

-- The following example converts the current date & time (CURRENT_TIMESTAMP) to a character string using style `'112'` (YYYYMMDD):

SELECT CONVERT(CHAR(8), CURRENT_TIMESTAMP, 112);

-- If today is February 12, 2022, this returns `'20220212'`. Converting the result back to DATETIME resets the time to midnight:

SELECT CONVERT(DATETIME, CONVERT(CHAR(8), CURRENT_TIMESTAMP, 112), 112);

-- To isolate the time portion instead, we can convert the current value to a string using style `'114'` (hh:mm:ss.nnn):

SELECT CONVERT(CHAR(12), CURRENT_TIMESTAMP, 114);

-- Converting this back to DATETIME returns the current time with the base date:

SELECT CONVERT(DATETIME, CONVERT(CHAR(12), CURRENT_TIMESTAMP, 114), 114);

-- We can also use the PARSE function to interpret string literals with culture-specific formats:

SELECT PARSE('02/12/2022' AS DATETIME USING 'en-US');
SELECT PARSE('02/12/2022' AS DATETIME USING 'en-GB');

-- The first example interprets the literal with US English settings, while the second one uses British English.



-- The PARSE function is significantly more expensive than the CONVERT function, so it's recommended to use the latter. 



----------------------------------
-- The SWITCHOFFSET Function
----------------------------------

-- The SWITCHOFFSET function adjusts a DATETIMEOFFSET value to a specified target offset from UTC. Note that you need to take into account whether daylight saving time is in effect or not for your input value with your target offset.

	-- Syntax: `SWITCHOFFSET(datetimeoffset_value, UTC_offset)`

-- For example, we can adjust the current system `datetimeoffset` value to offset `'-05:00'`.

SELECT SWITCHOFFSET(SYSDATETIMEOFFSET(), '-05:00');

-- So, if the current system `datetimeoffset` value is `'February 12, 2022 10:00:00.0000000 -08:00'`, this query above will change the UTC offset to  `'-05:00'`, regardless of whether daylight saving time is in effect. We can also adjust the `datetimeoffset` 

-- value to UTC:

SELECT SWITCHOFFSET(SYSDATETIMEOFFSET(), '+00:00');

-- Assuming the aforementioned `datetimeoffset` value, this returns `'February 12, 2022 18:00:00.0000000 +00:00'`.



--------------------------------------
-- The TODATETIMEOFFSET Function
--------------------------------------

-- The TODATETIMEOFFSET function creates a DATETIMEOFFSET value from a local date & time combined with a specified offset from UTC.

	-- Syntax: `TODATETIMEOFFSET(local_date_&_time_value, UTC_offset)`

-- Unlike SWITCHOFFSET, which adjusts the offset of an existing DATETIMEOFFSET value, TODATETIMEOFFSET starts with a local date & time without an offset & merges it with the given offset to produce a new DATETIMEOFFSET. This function is especially useful when 

-- migrating non-offset-aware data to offset-aware data. For example, suppose a table stores local date & time values in a column `dt` (DATETIME2 or DATETIME) & offset values in a column `theoffset`. To merge them into a single offset-aware column `dto`, we 

-- can update the table to add the new column:

	-- `UPDATE MyTable
	-- SET dto = TODATETIMEOFFSET(dt, theoffset);`



--------------------------------------
-- The AT TIME ZONE Function
--------------------------------------

-- The AT TIME ZONE function converts a date & time value to a `datetimeoffset` value that corresponds to the specified target time zone.

	-- Syntax: `dt_val AT TIME ZONE time_zone`

-- The input `dt_val` can be of the following data types: DATETIME, SMALLDATETIME, DATETIME2, & DATETIMEOFFSET. The input `time_zone` can be any of the supported time-zone names that appear in the `name` column of the  `sys.time_zone_info` view. Use the 

-- following query to see the available time zones, their current offset from UTC, & whether it's currently daylight saving time (DST):

SELECT name, current_utc_offset, is_currently_dst
FROM sys.time_zone_info;



-- When using any of the three non-DATETIMEOFFSET types (DATETIME, SMALLDATETIME, & DATETIME2), the AT TIME ZONE function assumes the input value `dt_val` is already expressed in the target time zone. In this sense, it works like TODATETIMEOFFSET, except the 

-- offset isn't fixed -- it changes depending on whether daylight savings time (DST) is in effect. For example, in the Pacific Standard Time zone, the offset from UTC is `'-08:00'` during standard time & `'-07:00'` during DST. The following query demonstrates 

-- this behaviour:

SELECT 
	CAST('20220212 12:00:00.0000000' AS DATETIME2) AT TIME ZONE 'Pacific Standard Time' as val1,
	CAST('20220812 12:00:00.0000000' AS DATETIME2) AT TIME ZONE 'Pacific Standard Time' as val2;

-- Here, the first value falls outside DST, so the offset is `'-08:00'`. The second value occurs during DST, so the offset `'-07:00'`. In this case, the results are unambiguous.



-- There are two tricky cases, when switching to & from DST. For example, in many places (like Pacific Standard Time), when switching to DST, the clock is advanced by an hour (e.g., from 1:59 AM to 3:00 AM). That means the entire hour between 2:00 AM & 2:59 AM

-- does not exist. If we feed SQL Server a time that falls into that "missing" hour (say `'2022-03-13 02:30:00'`), SQL Server automatically shifts it forward one hour (to `'03:30:00'`) & applies the new DST offset `'-07:00'`.

-- When switching from DST, the clock moves back one hour (e.g., from 2:00 AM to 1:00 AM again). That means the hour between 1:00 AM & 2:00 AM happens twice -- once under DST (`'-07:00'`) & once under standard time (`'-08:00'`). If we give SQL Server a time in

-- that repeated hour (say `'2022-11-06 01:30:00'`), it doesn't adjust the time -- it just assumes the post-DST offset (`'-08:00'`).



-- When the input `dt_val` is a DATETIMEOFFSET value, the AT TIME ZONE function behaves much like SWITCHOFFSET. The difference, again, is that the target offset isn't fixed -- it adjusts automatically based on daylight saving time (DST). For example, below is

-- a demonstration of the function with DATETIMEOFFSET inputs:

SELECT 
	CAST('20220212 12:00:00.0000000 -05:00' AS DATETIMEOFFSET) AT TIME ZONE 'Pacific Standard Time' as val1,
	CAST('20220812 12:00:00.0000000 -04:00' AS DATETIMEOFFSET) AT TIME ZONE 'Pacific Standard Time' as val2;

-- Here, the input values represent noon in Eastern Standard Time:

	-- The first value (`'-05:00'`) is outside DST.

	-- The second value (`'-04:00'`) is during DST.

-- Both are converted to Pacific Standard Time, where the offset is `'-08:00'` outside DST & `'-07:00'` during DST. In both cases, the local time shifts back three hours, resulting in 9:00AM.



-- Another useful scenario for the AT TIME ZONE function is converting the current system time to a specific target time zone, regardless of the system's own time-zone setting. This can be done by applying AT TIME ZONE to the result of SYSDATETIMEOFFSET &

-- specifying the desired time zone name. For example, the following query returns the current time in Pacific Standard Time, no matter which time zone your system is running in:

SELECT SYSDATETIMEOFFSET() AT TIME ZONE 'Pacific Standard Time';



------------------------------
-- The DATEADD Function
------------------------------

-- The DATEADD function adds a specified number of units of a specified date part to an input date & time value.

	-- Syntax: `DATEADD(part, n, dt_val)`

-- Valid values for the `part` input include `year`, `quarter`, `month`, `dayofyear`, `day`, `week`, `weekday`, `hour`, `minute`, `second`, `millisecond`, `microsecond`, & `nanosecond`.



-- The returned type is the same as the input's type. If this function is given a string literal as input, the output is DATETIME. For example, the following code adds one year to February 12, 2022:

SELECT DATEADD(year, 1, '20220212');



-- If you're wondering about the difference between the parts `day`, `weekday`, & `dayofyear`, they all have the same meaning for the functions DATEADD & DATEDIFF. With the DATEADD function, any of the three parts will result in adding `n` days

-- to `dt_val`. However, in other functions, such as DATEPART & DATENAME (discussed below), these parts have different meanings.



--------------------------------------------------
-- The DATEDIFF & DATEDIFF_BIG Functions
--------------------------------------------------

-- The DATEDIFF & DATEDIFF_BIG functions return the difference between two date & time values in terms of a specified date part. The former returns an INT (a 4-byte integer), & the latter returns a BIGINT value (an 8-byte integer).

	-- Syntax: `DATEDIFF(part, dt_val1, dt_val2)`, `DATEDIFF_BIG(part, dt_val1, dt_val2)`

-- For example, the following code returns the difference in days between two values:

SELECT DATEDIFF(day, '20210212', '20220212');



-- There are certain differences that result in an integer that is greater than the maximum INT value (2,147,483,647). For example, the difference in milliseconds between January 1, 0001 & February 12, 2022 is 63,780,220,800,000. We can't use the DATEDIFF

-- function to compute such a difference, but we can achieve this with the DATEDIFF_BIG function:

SELECT DATEDIFF_BIG(millisecond, '00010101', '20220212');



-- To compute the start of the day for a given date & time value, we can simply cast the value to the DATE type & then back to the target type. With more advanced use of the DATEADD & DATEDIFF functions, we can also calculate the start or end of other time

-- periods -- such as days, months, quarters, or years. For example, the following query returns the beginning of the current day:

SELECT DATEADD(day, DATEDIFF(day, '19000101', SYSDATETIME()), '19000101');

-- Here's how it works:

	-- 1. DATEDIFF calculates the number of full days between an anchor date at midnight (`'19000101'`) & the current date & time.

SELECT DATEDIFF(day, '19000101', SYSDATETIME());

	-- 2. DATEADD adds that number of days back to the anchor date.

-- The result is today's date with the time set to midnight. Of course, it could be much easier to cast the input value to DATE & then back to DATETIME2. However, the more complex expression is flexible in that we can use it to compute the beginning of other 

-- parts.



-- By changing the date part & anchor, we can compute the start of other periods. For example, using `'month'` instead of `'day'` & an anchor on the first day of the month returns the first day of the current month: 

SELECT DATEDIFF(month, '19000101', SYSDATETIME());

SELECT DATEADD(month, DATEDIFF(month, '19000101', SYSDATETIME()), '19000101');

-- Likewise, using `'year'` as the date part & an anchor on the first day of the year returns the first day of the current year.

SELECT DATEDIFF(year, '19000101', SYSDATETIME());

SELECT DATEADD(year, DATEDIFF(year, '19000101', SYSDATETIME()), '19000101');



-- If we want the last day of the month or year, simply use an anchor that is the last day of a month or year. For example, the following expression returns the last day of the current year:

SELECT DATEADD(year, DATEDIFF(year, '18991231', SYSDATETIME()), '18991231');



-------------------------------
-- The DATEPART Function
-------------------------------

-- The DATEPART function returns an integer representing a requested part of a date & time value.

	-- Syntax: `DATEPART(part, dt_val)`

-- Valid values for the `part` argument include `year`, `quarter`, `month`, `dayofyear`, `day`, `week`, `weekday`, `hour`, `minute`, `second`, `millisecond`, `microsecond`, `nansecond`, `tzoffset` (time zone offset), & `iso_week` (ISO-based week number). For 

-- example, the following code returns the month part of the input value:

SELECT DATEPART(month, '20220212');

-- This code returns the integer 2. 



-- For this function, the parts `day`, `weekday`, & `dayofyear`, have different meanings. 

	-- `day` means the number of the day of the month.
	
	-- `weekday` means to the number of the day of the week.
	
	-- `dayofyear` means the number of the day of the year. 
	
-- The following example extracts all three parts from an input date:

SELECT DATEPART(day, '20220212') AS part_day,
	DATEPART(weekday, '20220212') AS part_weekday,
	DATEPART(dayofyear, '20220212') AS part_dayofyear;



-------------------------------------------
-- The YEAR, MONTH, & DAY Functions
-------------------------------------------

-- The YEAR, MONTH, & DAY functions are abbreviations for the DATEPART function returning the integer representation of the year, month, & day parts of an input date & time value.

	-- Syntax: `YEAR(dt_val)`, `MONTH(dt_val)`, `DAY(dt_val)`

-- For example, the following code extracts the day, month, & year parts of an input value:

SELECT DAY('20220212') AS theday,
	MONTH('20220212') AS themonth,
	YEAR('20220212') AS theyear;



------------------------------
-- The DATENAME Function
------------------------------

-- The DATENAME function returns a character string representing a part of a date & time value.

	-- Syntax: `DATENAME(part, dt_val)`

-- This function is similar to DATEPART & has the same options for the `part` input. However, when relevant, it returns the name of the requested part rather than its integer representation. For example, the following query returns the month name of the given 

-- input value:

SELECT DATENAME(month, '20220212');



-- Recall that DATEPART returns the integer 2 for this input. DATENAME returns the name of the month, which is language dependent. If our session's language is one of the English languages (such as US English & British English), we get back the value

-- `'February'`. If our session's language is Italian, we get the value `'febbraio'`. If a part is requested that has no name & only a numeric value (such as year), the DATENAME function returns its numeric value, but as a character string. For example, the 

-- following code returns `'2022'`:

SELECT DATENAME(year, '20220212');



--------------------------------
-- The DATETRUNC Function
--------------------------------

-- The DATETRUNC function was introduced in SQL Server 2022 & truncates, or floors, the input date & time value to the beginning of the specified part.

	-- Syntax: `DATETRUNC(part, dt_val)`

-- If `dt_val` is of a date & time type, the output truncated value will be of the same type & fractional time scale as the input. If `dt_val` is of a character string type, the output will be of the type `DATETIME2(7)`.



-- Valid values for the `part` argument include `year`, `month`, `dayofyear`, `day`, `week`, `iso_week`, `hour`, `minute`, `second`, `millisecond`, & `microsecond`.



-- The following query returns the beginning of month date corresponding to the input value, at midnight, as a `DATETIME2(7)`-typed value:

SELECT DATETRUNC(month, '20220212');

-- For this function, the parts `day` & `dayofyear` have the same meaning, which is the beginning of the day (at midnight) that corresponds to the input date & time value.



----------------------------
-- The ISDATE Function
----------------------------

-- The ISDATE function accepts a character string as input & returns 1 if it is convertible to a date & time data type & 0 if it .

	-- Syntax: `ISDATE(string)`

-- For example, the following code returns 1:

SELECT ISDATE('20220212');

-- The following code returns 0:

SELECT ISDATE('20220230');



-------------------------------
-- The FROMPARTS Functions
-------------------------------

-- The FROMPARTS functions accept integer inputs representing parts of a date & time value & construct a value of the requested type from these parts.

	-- Syntax: `DATEFROMPARTS(year, month, day)`
	--         `DATETIME2FROMPARTS(year, month, day, hour, minute, seconds, fractions, precision)`
	--         `DATETIMEFROMPARTS(year, month, day, hour, minute, secnds, milliseconds)`
	--         `DATETIMEOFFSETFROMPARTS(year, month, day, hour, minute, seconds, fractions, hour_offset, minute_offset, precision)`
	--         `SMALLDATETIMEFROMPARTS(year, month, day, hour, minute)`
	--         `TIMEFROMPARTS(hour, minute, seconds, fractions, precision)`

-- The following code demonstrates the use of these functions:

SELECT
	DATEFROMPARTS(2022, 02, 12),
	DATETIME2FROMPARTS(2022, 02, 12, 13, 30, 5, 1, 7),
	DATETIMEFROMPARTS(2022, 02, 12, 13, 30, 5, 997),
	DATETIMEOFFSETFROMPARTS(2022, 02, 12, 13, 30, 5, 1, -8, 0, 7),
	SMALLDATETIMEFROMPARTS(2022, 02, 12, 13, 30),
	TIMEFROMPARTS(13, 30, 5, 1, 7);



----------------------------
-- The EOMONTH Function
----------------------------

-- The EOMONTH function accepts an input date & time value & returns the respective end-of-month date as a DATE value. The function also supports an optional second argument indicating how many months to add (or subtract, if negative).

	-- Syntax: `EOMONTH(input [, months_to_add])`

-- For example, the following code returns the end of the current month:

SELECT EOMONTH(SYSDATETIME());



-- The following query returns orders placed on the last day of the month:

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderdate = EOMONTH(orderdate);



-- An alternative way to compute the last day of the month for a given date is to use DATEADD & DATEDIFF:

	-- DATEADD(month, DATEDIFF(month, '18991231', date_val), '18991231');

-- Here's how it works:

	-- 1. DATEDIFF calculates the number of whole months between an anchor date (`'1899-12-31'`, the last day of a month) & the input date.

	-- 2. DATEADD then adds that number of months back to the anchor, returning the last day of the target month.

-- For example, this query returns only the order placed on the last day of their respective month:

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderdate = DATEADD(month, DATEDIFF(month, '18991231', orderdate), '18991231');



-------------------------------------
-- The GENERATE_SERIES Function
-------------------------------------

-- The GENERATE_SERIES function is a table-valued function introduced in SQL Server 2022 that returns a sequence of numbers within a specified range. We provide a `start_value` & a `stop_value`, & optionally a `step_value` if we want to increment or decrement

-- by a value other than the default (1 for increasing sequences, -1 for decreasing sequences). The resulting sequence is returned in a column named `value`. These numbers can also be easily converted into date or time sequences when needed.

	-- Syntax: `SELECT value 
	--          FROM GENERATE_SERIES(start_value, stop_value[, step_value]);`

-- The `start_value` & `stop_value` can be of any of the following types: TINYINT, SMALLINT, INT, BIGINT, DECIMAL, or NUMERIC. Both inputs must be of the same type, & the result column `value` will have that same type. For example, the following query generates

-- a sequence of integers from 1 to 10:

SELECT value
FROM GENERATE_SERIES(1, 10) AS N;

-- We can also use GENERATE_SERIES to create sequences of dates or times with simple date arithmetic. For instance, the following code generates all dates in the year 2022: 

DECLARE @startdate AS DATE = '20220101', @enddate AS DATE = '20221231';

SELECT DATEADD(day, value, @startdate) AS dt
FROM GENERATE_SERIES(0, DATEDIFF(day, @startdate, @enddate)) AS N;

-- Here's how this works:

	-- 1. Two local variables, `@startdate` & `@enddate`, are declared & assigned the first & last dates of 2022.

	-- 2. GENERATE_SERIES is called with `0` as the `start_value` & the total number of days between `@startdate` & `@enddate` as the `stopvalue`.

	-- 3. In the SELECT statement, DATEADD adds each number from the sequence to `@startdate`, producing a column `dt` containing every date in the year 2022.



