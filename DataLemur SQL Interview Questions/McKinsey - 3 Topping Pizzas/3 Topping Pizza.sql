CREATE TABLE pizza_toppings (
	ingredient_cost numeric(3, 2),
	topping_name text
);

COPY pizza_toppings
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/McKinsey - 3 Topping Pizzas/pizza_toppings.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM pizza_toppings;

SELECT (p1.topping_name || ',' || p2.topping_name || ',' 
	   	   || p3.topping_name) AS pizza,
	   (p1.ingredient_cost + p2.ingredient_cost +
	   	   p3.ingredient_cost) AS total_cost
FROM pizza_toppings p1
CROSS JOIN pizza_toppings p2
CROSS JOIN pizza_toppings p3
WHERE p1.topping_name != p2.topping_name 
	AND p1.topping_name != p3.topping_name
	AND p2.topping_name != p3.topping_name
	AND p1.topping_name < p2.topping_name
	AND p2.topping_name < p3.topping_name
ORDER BY total_cost DESC;
