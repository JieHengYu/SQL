SELECT * FROM items_per_order;

SELECT *
FROM items_per_order
WHERE order_occurrences = (SELECT mode() WITHIN GROUP (ORDER 
    BY order_occurrences DESC) FROM items_per_order)
ORDER BY item_count;
