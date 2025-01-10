CREATE TABLE job_listings (
	job_id smallint,
	company_id smallint,
	title text,
	description text
);

INSERT INTO job_listings
VALUES (248, 827, 'Business Analyst', 'Business analyst evaluates past & current business data with the primary goal of improving decision-making processes within organisations.'),
	   (149, 845, 'Business Analyst', 'Business analyst evaluates past & current business data with the primary goal of improving decision-making processes within organisations.'),
	   (945, 345, 'Data Analyst', 'Data analyst reviews data to identify key insights into a business''s customers & ways the data can be used to solve problems.'),
	   (164, 345, 'Data Analyst', 'Data analyst reviews data to identify key insights into a business''s customers & ways the data can be used to solve problems.'),
	   (172, 244, 'Data Engineer', 'Data engineer works in a variety of settings to build systems that collect, manage, & convert raw data into usable information for data scientists & business analysts to interpret.');

SELECT * FROM job_listings;

SELECT company_id,
	   title,
	   count(*) AS num_postings
FROM job_listings
GROUP BY company_id, title
HAVING count(*) > 1;
