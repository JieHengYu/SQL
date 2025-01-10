CREATE TABLE callers (
	policy_holder_id smallint,
	case_id text,
	call_category text,
	call_date timestamp,
	call_duration_secs smallint
);

COPY callers
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/UnitedHealth - Patient Support Analysis (Part 1)/callers.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM callers;

SELECT policy_holder_id,
	   count(DISTINCT case_id)
FROM callers
GROUP BY policy_holder_id
HAVING count(DISTINCT case_id) >= 3;

SELECT count(*) AS policy_holder_count
FROM (
    SELECT policy_holder_id,
    	   count(DISTINCT case_id)
    FROM callers
    GROUP BY policy_holder_id
    HAVING count(DISTINCT case_id) >= 3
);
