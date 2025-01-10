SELECT * FROM callers;

SELECT count(*) AS calls,
	   count(*) FILTER (WHERE call_category IN ('n/a', 
	   	   NULL)) AS uncat_calls,
	   round(((count(*) FILTER (WHERE call_category IN 
	   	   ('n/a', NULL)))::numeric / count(*)) * 100, 1)
		   AS uncat_call_pct
FROM callers;
