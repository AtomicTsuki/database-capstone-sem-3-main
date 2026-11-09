-- 05_indexing.sql : composite indexes, FULLTEXT, EXPLAIN comparisons, low-selectivity demo
USE shop;

-- 5a. orders (customer_id, order_date)
-- BEFORE: ignore the FK index -> full table scan + filesort
EXPLAIN
SELECT order_id, order_date, total_amount
FROM orders IGNORE INDEX (fk_orders_customer)
WHERE customer_id = 1234 AND order_date BETWEEN '2024-01-01' AND '2024-06-30'
ORDER BY order_date;

-- equality column first, range/sort column second
CREATE INDEX idx_orders_customer_date ON orders (customer_id, order_date);

-- AFTER: type=range, no filesort
EXPLAIN
SELECT order_id, order_date, total_amount
FROM orders
WHERE customer_id = 1234 AND order_date BETWEEN '2024-01-01' AND '2024-06-30'
ORDER BY order_date;

-- actual run time without / with the index (MySQL 8.0.18+)
EXPLAIN ANALYZE
SELECT order_id, order_date, total_amount
FROM orders IGNORE INDEX (idx_orders_customer_date)
WHERE customer_id = 1234 AND order_date BETWEEN '2024-01-01' AND '2024-06-30'
ORDER BY order_date;

EXPLAIN ANALYZE
SELECT order_id, order_date, total_amount
FROM orders
WHERE customer_id = 1234 AND order_date BETWEEN '2024-01-01' AND '2024-06-30'
ORDER BY order_date;

SHOW INDEX FROM orders;

-- 5b. products (category_id, price)
EXPLAIN
SELECT product_id, title, price
FROM products IGNORE INDEX (fk_products_category)
WHERE category_id = 3 AND price BETWEEN 20 AND 50
ORDER BY price;

CREATE INDEX idx_products_category_price ON products (category_id, price);

EXPLAIN
SELECT product_id, title, price
FROM products
WHERE category_id = 3 AND price BETWEEN 20 AND 50
ORDER BY price;

EXPLAIN ANALYZE
SELECT product_id, title, price
FROM products IGNORE INDEX (idx_products_category_price)
WHERE category_id = 3 AND price BETWEEN 20 AND 50
ORDER BY price;

EXPLAIN ANALYZE
SELECT product_id, title, price
FROM products
WHERE category_id = 3 AND price BETWEEN 20 AND 50
ORDER BY price;

-- 5c. FULLTEXT on title + description
-- BEFORE: leading-wildcard LIKE can never use a B-tree index -> full scan
EXPLAIN
SELECT product_id, title FROM products
WHERE title LIKE '%wireless%' OR description LIKE '%wireless%';

ALTER TABLE products ADD FULLTEXT INDEX ft_products_title_desc (title, description);

-- AFTER: type=fulltext
EXPLAIN
SELECT product_id, title
FROM products
WHERE MATCH(title, description) AGAINST ('wireless headphones' IN NATURAL LANGUAGE MODE);

-- ranked search with relevance score; BOOLEAN MODE: + required, - excluded, * prefix
SELECT product_id, title,
       MATCH(title, description) AGAINST ('wireless headphones' IN NATURAL LANGUAGE MODE) AS relevance
FROM products
WHERE MATCH(title, description) AGAINST ('+wireless -backpack ergonom*' IN BOOLEAN MODE)
ORDER BY relevance DESC
LIMIT 10;

-- 5d. Why an index on a low-selectivity column barely helps
SELECT COUNT(DISTINCT status) / COUNT(*) AS selectivity FROM orders;

SELECT status, COUNT(*) AS cnt, ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM orders GROUP BY status;

CREATE INDEX idx_orders_status ON orders (status);
ANALYZE TABLE orders;

EXPLAIN SELECT order_id, total_amount FROM orders WHERE status = 'delivered';

-- same query: full scan vs forced index (compare "actual time")
EXPLAIN ANALYZE SELECT order_id, total_amount FROM orders IGNORE INDEX (idx_orders_status)
WHERE status = 'delivered';

EXPLAIN ANALYZE SELECT order_id, total_amount FROM orders FORCE INDEX (idx_orders_status)
WHERE status = 'delivered';

-- rare value (~5% of the table): now the index is worth using
EXPLAIN SELECT order_id, total_amount FROM orders WHERE status = 'cancelled';

DROP INDEX idx_orders_status ON orders;
