------------------------------------

-- Using Running Aggregates

------------------------------------

-- Running aggregates are aggregates that accumulate values based on some order. In this section, we'll use the `Sales.OrderTotalsByYear` view to demonstrate a technique that calculates those. For now, we can think of a view as being the same as a table. The

-- view has total order quantities by year. Query the view to examine its contents:

USE TSQLV6;

SELECT orderyear, qty
FROM Sales.OrderTotalsByYear;



-- Suppose we need to compute for each year the running total quantity up to & including that year's. For the earliest year recorded in the view (2020), the running total is equal to that year's quantity. For the second year (2021), the running total is the

-- sum of the first year plus the second year, & so on.



-- We query one instance of the view (call it `O1`) to return for each year the current year & quantity. We use a correlated subquery against the second instance of the view (call it `O2`) to calculate the running total quantity. The subquery should filter all

-- rows in `O2` where the order year is smaller than or equal to the current year in `O1`, & sum the quantities from `O2`. Here's the solution query:

SELECT O1.orderyear, O1.qty,
	(SELECT SUM(O2.qty)
	 FROM Sales.OrderTotalsByYear AS O2
	 WHERE O2.orderyear <= O1.orderyear) AS runqty
FROM Sales.OrderTotalsByYear AS O1
ORDER BY O1.orderyear;



-- Note that T-SQL supports window aggregate functions, which we can use to compute running totals much more easily & efficiently