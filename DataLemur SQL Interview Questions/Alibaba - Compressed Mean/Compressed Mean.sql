CREATE TABLE items_per_order (
	item_count smallserial,
	order_occurrences smallint
);

INSERT INTO items_per_order (order_occurrences)
VALUES (500),
	   (1000),
	   (800),
	   (1000),
	   (500),
	   (550),
	   (400),
	   (200),
	   (10);

SELECT * FROM items_per_order;

SELECT round(sum(item_count * order_occurrences)::numeric 
		   / sum(order_occurrences), 1) AS mean
FROM items_per_order;
