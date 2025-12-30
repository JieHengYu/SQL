---------------------------------------

-- Predicates & Operators

---------------------------------------

-- In T-SQL, predicates can appear in elements like WHERE & HAVING claues, JOIN conditions, & CHECK constraints. A predicate is a logical expression that evaluates to TRUE, FALSE, or UNKNOWN. Predicates can be combined with logical 

-- operators such as AND (conjunction) & OR (disjunction), & may also use comparison operators.



-- Examples of predicates supported by T-SQL include IN, BETWEEN, & LIKE. We use the IN predicate to check whether a value, or scalar expression, is equal to at least one of the elements in a set. For example, the following query 

-- returns orders in which the order ID is equal to 10248, 10249, or 10250:

USE TSQLV6;

SELECT orderid, empid, orderdate
FROM Sales.Orders
WHERE orderid IN (10248, 10249, 10250);

-- We use the BETWEEN predicate to check whether a value falls within a specified range, inclusive of the two delimiters of the range. For example, the following query returns all orders in the inclusive range 10300 through 10310:

SELECT orderid, empid, orderdate
FROM Sales.Orders
WHERE orderid BETWEEN 10300 AND 10310;

-- With the LIKE predicate, we can check whether a character string value meets a specified pattern. For example, the following query returns employees whose last names start with the letter D:

SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname LIKE N'D%';

-- Notice the use of the letter N to prefix the string 'D%'; it stands for "National" & is used to denote that a character string is of a Unicode data type (NCHAR & NVARCHAR), as opposed to a regular character data type (CHAR & 

-- VARCHAR). Because the data type of the `lastname` attribute is `NVARCHAR(40)`, the letter N is used to prefix the string. 



-- T-SQL supports the following comparison operators: =, >, <, >=, <=, <>, !=, !>, & !<. The last three are nonstandard, so it's best to avoid them & use their stnadard alternatives (e.g., <> instead of !=). For example, the 

-- following query returns all orders placed on or after January 1, 2022:

SELECT orderid, empid, orderdate
FROM Sales.Orders
WHERE orderdate >= '20220101';



-- If we need to combine logical expressions, we can use the logical operators OR & AND. If we want to negate an expression, we can use the NOT operator. For example, the following query returns orders placed on or after January 1, 2022,

-- that were handled by an employee whose ID is other than 1, 3, & 5.

SELECT orderid, empid, orderdate
FROM Sales.Orders
WHERE orderdate >= '20220101'
	AND empid NOT IN (1, 3, 5);



-- T-SQL supports the four obvious arithmetic operators: +, -, *, & /. It also supports the % operator (modulo), which returns the remainder of integer division. For example, the following query calculates the net value as a result of

-- arithmetic manipulation of the `quantity`, `unitprice`, & `discount` attributes:

SELECT orderid, productid, qty, unitprice, discount,
	   qty * unitprice * (1 - discount) AS val
FROM Sales.OrderDetails;



-- In T-SQL, the data type of a scalar expression is determined by the operand with the higher data-type precedence. If both operands share the same type, the result is of that type. For example, dividing two integers returns an integer,

-- so 5/2 yields 2 instead of 2.5. This is an accuracy issue, so when performing arithmetic with integer columns (e.g., `col1/col2`), we must cast them to a numeric type: `CAST(col1 AS NUMERIC(12, 2)) / CASE(col2 AS NUMERIC(12, 2))`.

-- Here, `NUMERIC(12, 2)` has a precision of 12 digits, 2 of which are after the decimal point.

SELECT 5/2;

-- If the two operands are of different types, the one with the lower precendence is promoted to the one that is higher. For example, in the expresion 5/2.0, the first operand is INT & the second is NUMERIC. Because NUMERIC is considered

-- higher than INT, the INT operand 5 is implicitly converted to the NUMERIC 5.0 before the arithmetic operation, & we get the result 2.5.

SELECT 5/2.0;



-- When multiple operators appear in the same expression, SQL Server evaluates them based on operator precedence rules. The following list describes the precedence among operators, from highest to lowest:

-- 1. () (Parentheses)
-- 2. * (Multiplication), / (Division), % (Modulo)
-- 3. + (Positive, Addition, Concatenation), - (Negative, Subtraction),
-- 4. =, >, <, >=, <=, <>, !=, !>, !< (Comparison operators)
-- 5. NOT
-- 6. AND
-- 7. BETWEEN, IN, LIKE, OR
-- 8. = (Assignment)

-- For example, in the following query, AND has precedence over OR:

SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE custid = 1
	AND empid IN (1, 3, 5)
	OR custid = 85
	AND empid IN (2, 4, 6);

-- The query returns orders that were either "placed by customer 1 & handled by employees 1, 3, or 5" or "placed by customer 85 & handled by employees 2, 4, or 6". However, for the sake of other people who need to review or maintain 

-- your code & for readability purposes, it's a good practice to use parentheses even when they are not required. The same is true with indentation. For example, the following query is the logical equivalent of the previous query, only 

-- its meaning is much clearer:

SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE (custid = 1 AND empid IN (1, 3, 5))
	OR (custid = 85 AND empid IN (2, 4, 6));



-- Using parentheses to force precedence with logical operators is similar to using parentheses with arithmetic operators. For example, without parentheses in the following expression, multiplication precedes addition:

SELECT 10 + 2 * 3;

-- Therefore, this expression returns 16. We can use parentheses to force the addition to be calculated first:

SELECT (10 + 2) * 3;

-- This time, the expression returns 36.