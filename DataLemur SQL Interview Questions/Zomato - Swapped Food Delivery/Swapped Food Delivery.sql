CREATE TABLE orders (
	order_id smallserial,
	item text
);

INSERT INTO orders (item)
VALUES ('Chow Mein'),
	   ('Pizza'),
	   ('Pad Thai'),
	   ('Butter Chicken'),
	   ('Eggrolls'),
	   ('Burger'),
	   ('Tandoori Chicken'),
	   ('Sushi'),
	   ('Tacos'),
	   ('Ramen'),
	   ('Burrito'),
	   ('Lasagna'),
	   ('Salad'),
	   ('Steak'),
	   ('Spaghetti');

SELECT * FROM orders;

SELECT item,
	   (CASE WHEN order_id = (SELECT max(order_id)
	       FROM orders) AND order_id % 2 != 0 THEN
		   order_id
		   WHEN order_id % 2 != 0 THEN order_id + 1
		   WHEN order_id % 2 = 0 THEN order_id - 1
		   ELSE NULL END) AS order_id_fixed
FROM orders
ORDER BY order_id_fixed;
