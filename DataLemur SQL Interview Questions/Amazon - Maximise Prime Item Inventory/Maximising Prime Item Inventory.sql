CREATE TABLE inventory (
	item_id smallint,
	item_type text,
	item_category text,
	square_footage numeric(5, 2)
);

COPY inventory
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/Amazon - Maximise Prime Item Inventory/inventory.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM inventory;

SELECT item_type,
	   sum(square_footage) AS sq_ft,
	   count(*) AS items_per_batch,
	   div(500000, sum(square_footage)) AS batches,
	   div(500000, sum(square_footage)) * count(*)
	   	   AS total_items,
	   sum(square_footage) * div(500000, 
	   	   sum(square_footage)) AS sq_ft_used
FROM inventory
GROUP BY item_type
HAVING item_type = 'prime_eligible';

SELECT item_type,
	   sum(square_footage) AS sq_ft,
	   count(*) AS items_per_batch,
	   floor((500000 - (SELECT sum(square_footage) * 
	   	   div(500000, sum(square_footage)) 
		   FROM inventory GROUP BY item_type 
		   HAVING item_type = 'prime_eligible')) / 
		   sum(square_footage)) AS batches,
	   floor((500000 - (SELECT sum(square_footage) * 
	   	   div(500000, sum(square_footage)) 
		   FROM inventory GROUP BY item_type 
		   HAVING item_type = 'prime_eligible')) / 
		   sum(square_footage)) * count(*) AS total_items,
	   floor((500000 - (SELECT sum(square_footage) * 
	   	   div(500000, sum(square_footage)) 
		   FROM inventory GROUP BY item_type 
		   HAVING item_type = 'prime_eligible')) / 
		   sum(square_footage)) * sum(square_footage)
		   AS sq_ft_used
FROM inventory
GROUP BY item_type
HAVING item_type = 'not_prime';

(SELECT item_type,
	   sum(square_footage) AS sq_ft,
	   count(*) AS items_per_batch,
	   div(500000, sum(square_footage)) AS batches,
	   div(500000, sum(square_footage)) * count(*)
	   	   AS total_items,
	   sum(square_footage) * div(500000, 
	   	   sum(square_footage)) AS sq_ft_used
FROM inventory
GROUP BY item_type
HAVING item_type = 'prime_eligible')
UNION
(SELECT item_type,
	   sum(square_footage) AS sq_ft,
	   count(*) AS items_per_batch,
	   floor((500000 - (SELECT sum(square_footage) * 
	   	   div(500000, sum(square_footage)) 
		   FROM inventory GROUP BY item_type 
		   HAVING item_type = 'prime_eligible')) / 
		   sum(square_footage)) AS batches,
	   floor((500000 - (SELECT sum(square_footage) * 
	   	   div(500000, sum(square_footage)) 
		   FROM inventory GROUP BY item_type 
		   HAVING item_type = 'prime_eligible')) / 
		   sum(square_footage)) * count(*) AS total_items,
	   floor((500000 - (SELECT sum(square_footage) * 
	   	   div(500000, sum(square_footage)) 
		   FROM inventory GROUP BY item_type 
		   HAVING item_type = 'prime_eligible')) / 
		   sum(square_footage)) * sum(square_footage)
		   AS sq_ft_used
FROM inventory
GROUP BY item_type
HAVING item_type = 'not_prime')
ORDER BY item_type DESC;
