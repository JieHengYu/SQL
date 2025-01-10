CREATE TABLE monthly_cards_issued (
	card_name text,
	issued_amount integer,
	issue_month smallint,
	issue_year smallint
);

INSERT INTO monthly_cards_issued
VALUES ('Chase Freedom Flex', 55000, 1, 2021),
	   ('Chase Freedom Flex', 60000, 2, 2021),
	   ('Chase Freedom Flex', 65000, 3, 2021),
	   ('Chase Freedom Flex', 70000, 4, 2021),
	   ('Chase Sapphire Reserve', 170000, 1, 2021),
	   ('Chase Sapphire Reserve', 175000, 2, 2021),
	   ('Chase Sapphire Reserve', 180000, 3, 2021);

SELECT * FROM monthly_cards_issued;

SELECT card_name,
	   max(issued_amount) - min(issued_amount)
	   	   AS difference
FROM monthly_cards_issued
GROUP BY card_name;
