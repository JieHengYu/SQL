SELECT * FROM monthly_cards_issued;

SELECT launch.card_name,
	   mci.issued_amount,
	   mci.issue_month,
	   mci.issue_year
FROM (
	SELECT card_name,
		   min(issue_month)
	FROM monthly_cards_issued
	GROUP BY card_name
) AS launch
LEFT JOIN monthly_cards_issued AS mci
	ON launch.card_name = mci.card_name
		AND launch.min = mci.issue_month;
