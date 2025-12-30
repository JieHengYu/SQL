---------------------

-- NULLs

---------------------

-- SQL uses the NULL marker to represent missing values & relies on three-valued logic, where predicates can evaluate to TRUE, FALSE, or UNKNOWN. T-SQL follows this standard. However, working with NULL & UNKNOWN can be confusing, since

-- most people are used to traditional two-valued logic (TRUE & FALSE). The confusion is compounded by the fact that different SQL language elements handle NULL & UNKNOWN inconsistently.



-- Let's begin with three-valued predicate logic. A logical expression that involves only non-NULL values evaluates to either TRUE or FALSE. When a NULL is involved, the result is typically UNKNOWN. For example, take the predicate

-- `salary > 0`:

	-- If `salary = 1000`, the expression evaluates to TRUE.

	-- If `salary = -1000`, the expression evaluates to FALSE.

	-- If `salary = NULL`, it evaluates to UNKNOWN.



-- SQL handles TRUE & FALSE in an intuitive way. For example, in a query filter (WHERE or HAVING), rows where `salary > 0` is TRUE are returned, while rows where it is FALSE are excluded. In a CHECK constraint, INSERT or UPDATE

-- statements succeed only if the expression is TRUE for all rows; if it is FALSE for any row, the statement is rejected. However, SQL handles UNKNOWN differently depending on the language elements, & the behaviour is not always

-- intuitive.

	-- In query filters (WHERE, HAVING), the rule is "accept TRUE" -- only rows where the predicate evaluates to TRUE are kept, while both FALSE & UNKNOWN are discarded.

	-- In CHECK constraints, the rule is "reject FALSE" -- statements are rejected only when the predicate evaluates to FALSE. Both TRUE & UNKNOWN are accepted.

-- If SQL used two-valued logic, "accept TRUE" & "reject FALSE" would be equivalent. But under the three-valued logic, they differ: "accept TRUE" excludes UNKNOWN, while "reject FALSE" allows it. For example, with the predicate 

-- `salary > 0`:

	-- In a WHERE clause, a row with `salary = NULL` evaluates to UNKNOWN & is discarded.

	-- In a CHECK constraint, the same row is accepted, since UNKNOWN is not rejected.



-- One of the tricky aspects of the truth value UNKNOWN is that negating it still results in UNKNOWN. For example, given the predicate `NOT(salary > 0)`, when `salary` is NULL, `salary > 0` evaluates to UNKNOWN, & NOT UNKNOWN remains

-- UNKNOWN. What some people find surprising is that comparing two NULLs (`NULL = NULL`) evaluates to UNKNOWN. From SQL's perspective, a NULL represents a missing value, & we cannot determine whether one missing value is equal to another.

-- Therefore, SQL provides the predicates IS NULL & IS NOT NULL, which should be used instead of `= NULL` & `<> NULL`.



-- SQL supports a standard DISTINCT predicate that uses two-valued logic & treats NULLs like regular values. Its syntax is `comparand1 IS [NOT] DISTINCT FROM comparand2`.

	-- IS NOT DISTINCT FROM works like the = operator, but it also treats two NULLS as equal (returns TRUE). A NULL compared to a non-NULL returns FALSE.

	-- IS DISTINCT FROM works like the <> operator, but it also treats two NULLS as not distinct (returns FALSE). A NULL compared to a non-NULL returns TRUE.



-- To make three-valued logic more tangible, let's look at an example. The `Sales.Customers` table stores customer location details in three attributes: `country`, `region`, & `city`. Every row has values for `country` & `city`, but

-- `region` is sometimes missing (NULL). For example:

	-- `country = 'USA'`, `region = 'WA'`, `city = 'Seattle'`

	-- `country = 'UK'`, `region = NULL`, `city = 'London'` (region not applicable)

-- Now, consider the following query, which attempts to return all customers where the `region` is equal to `'WA'`:

USE TSQLV6;

SELECT custid, country, region, city
FROM Sales.Customers
WHERE region = N'WA';

-- Out of the 91 rows in the `Sales.Customers` table, the query returns only the three rows where the `region = N'WA'`. It excludes rows where `region` has a non-NULL value different from `'WA'` (predicate evaluates to FALSE) & rows

-- where `region` is NULL (predicate evaluates to UNKNOWN). In this case, when comparing the column `region` with the constant `N'WA'`, there's no reason to use the distinct predicate, since the end result is the same as with the equality

-- operator. So, the following query returns the same result as the last one:

SELECT custid, country, region, city
FROM Sales.Customers
WHERE region IS NOT DISTINCT FROM N'WA';

-- For the three customers from WA, the predicate evaluates to TRUE. For the remaining customers, the predicate evaluates to FALSE or UNKNOWN. The result is that we get only the three customers from WA, like with the previous query.



-- Now let's examine an example looking for difference. The following query attempts to return all customers where the `region <> N'WA'`:

SELECT custid, country, region, city
FROM Sales.Customers
WHERE region <> N'WA';

-- If you expected to get 88 rows back (91 rows in the table minus 3 returned by the previous query), you might find this result (with just 28 rows) surprising. But remember that a query filter "accepts TRUE", meaning that it rejects

-- both FALSE & UNKNOWN. So this query returned rows in which the `region` value was present & different than `'WA'`. It excluded rows where `region = N'WA'` (predicate evaluates to FALSE) & rows in which `region` is NULL (predicate 

-- evaluates to UNKNOWN). We will get the same output if we use the predicate `NOT(region = N'WA')`. 

SELECT custid, country, region, city
FROM Sales.Customers
WHERE NOT(region = N'WA');

-- For rows where the `region` attribute is NULL, the predicate expression `region = N'WA'` evaluates to UNKNOWN, & `NOT(region = N'WA')`, NOT UNKNOWN, evaluates to UNKNOWN also.



-- If we want to return all rows for which `region` is NULL, we should not use the predicate `region = NULL`, because the expression evaluates to UNKNOWN in all rows. The following query returns an empty set:

SELECT custid, country, region, city
FROM Sales.Customers
WHERE region = NULL;

-- Instead, we should use the IS NULL predicate:

SELECT custid, country, region, city
FROM Sales.Customers
WHERE region IS NULL;



-- If we want to return rows where the `region <> N'WA'` & those with NULL values, we need to include an explicit test for NULLs, like this:

SELECT custid, country, region, city
FROM Sales.Customers
WHERE region <> N'WA' OR region IS NULL;

-- This query is the logical equivalent of the previous query, but uses a DISTINCT predicate & is a bit less verbose:

SELECT custid, country, region, city
FROM Sales.Customers
WHERE region IS DISTINCT FROM N'WA';



-- SQL treats NULLs inconsistently in different language elements for comparison & sorting purposes. Some elements treat two NULLs as equal to each other while others treat them as different. For example, for grouping & sorting purposes, 

-- two NULLs are considered equal. That is, the GROUP BY clause arranges all NULLs into one group just like with non-NULL values, & the ORDER BY clause sorts all NULLs together. 



-- When enforcing a UNIQUE constraint, standard SQL enforces uniqueness only among the non-NULL values, resulting in NULLable columns that allow multiple NULLs in them. Conversely, in T-SQL, a UNIQUE constraint handles NULLs like non-NULL 

-- values, as if two NULLs are equal (allowing only one NULL).



-- The complexity in handling NULLs often results in logical errors. Therefore, we should think about them in every query we write. If the default treatment is not what we want, we must intervene explicitly; otherwise, ensure that

-- the default behaviour is in fact what we want.