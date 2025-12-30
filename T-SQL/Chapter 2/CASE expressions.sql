---------------------------

-- CASE Expressions

---------------------------

-- A CASE expression is a standard scalar expression that returns a value based on conditional logic. Because CASE is a scalar expression, it is allowed wherever scalar expressions are allowed, such as in SELECT, WHERE, HAVING, & 

-- ORDER BY clauses & in CHECK constraints.



-- There are two forms of CASE expressions: simple & searched. In the simple form, we compare one value or expression against several possible values. For example, the following query against the `Production.Products` table uses a 

-- CASE expression to compute the product count parity (whether the count is odd or even) per category:

USE TSQLV6;

SELECT supplierid, COUNT(*) AS numproducts,
	CASE COUNT(*) % 2
		WHEN 0 THEN 'Even'
		WHEN 1 THEN 'Odd'
		ELSE 'Unknown'
	END AS countparity
FROM Production.Products
GROUP BY supplierid;

-- The simple CASE expression begins with a single test value or expression (in this query, `COUNT(*) % 2`). This value is compared against the list of possible values in the WHEN clauses (0 & 1 in this case). The result from the THEN

-- clause of the first match is returned. If no match is found, SQL returns the ELSE expression; if no ELSE is provided, it defaults to NULL. In our query, the test expression can only evaluate to 0 or 1, so the ELSE clause will never

-- be used. It's included simply to show the full syntax.



-- The searched CASE expression is more flexible because the WHEN clauses can use full predicates, not just equality checks. It returns the value from the THEN clause of the first WHEN condition that evaluates to TRUE. If none of the

-- conditions are true, it returns the ELSE value, or NULL if no ELSE is specified. For example, the following query produces a value category description based on whether the value is less than 1,000.00, between 1,000.00 & 3,000.00, 

-- or greater than 3,000.00:

SELECT orderid, custid, val,
	CASE
		WHEN val < 1000.00 THEN 'Less than 1000'
		WHEN val BETWEEN 1000.00 AND 3000.00 THEN 'Between 1000 & 3000'
		WHEN val > 3000.00 THEN 'More than 3000'
		ELSE 'Unknown'
	END AS valuecategory
FROM Sales.OrderValues;

-- You can see that every simple CASE expression can be converted to the searched CASE form, but the reverse is not true.



-- T-SQL includes several functions that serve as shorthand for the CASE expression: ISNULL, COALSECE, IIF, & CHOOSE. These functions don't provide new capabilities but offer more concise ways to express common logic. Of the four, only

-- COALESCE is part of the SQL standard.



-- The ISNULL function accepts two arguments as input & returns the first that is not NULL or NULL if both are NULL. For example, `ISNULL(col1, '')` returns the `col1` value if it isn't NULL & an empty string if it is NULL. 



-- The COALESCE function accepts two or more arguments & returns the first non-NULL value, or NULL if all are NULL. For example, `COALESCE(col1, col2, col3, '')` checks each column in order: if `col1` is not NULL, it returns that value;

-- otherwise it moves to `col2`, then `col3`, & finally the empty string. In short, COALESCE returns the first non-NULL value from the list



-- The function `IIF(<logical_expression>, <expr1>, <expr2>)` returns `expr1` if `logical_expression` is True, & it returns `expr2` otherwise. For example, the expression `IIF(col1 <> 0, col2/col1, NULL)` returns `col2/col1` if 

-- `col1` is not zero; otherwise, it returns a NULL. 



-- The `CHOOSE(<index>, <expr1>, <expr2>, ..., <exprN>)` function returns the expression at the specified position in the list. For example, `CHOOSE(3, col1, col2, col3)` returns the value of `col3`. In practice, the index is often

-- dynamic -- for instance, based on user input. In short, CHOOSE selects the N-th value from the list, where N is the index.