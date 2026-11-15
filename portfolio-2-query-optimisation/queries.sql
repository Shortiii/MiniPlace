-- =====================================================================
-- Portfolio 2: queries with EXPLAIN (ANALYZE, BUFFERS)
-- Run this file TWICE:
--   1) BEFORE indexes.sql  -> screenshot / save the plans  (baseline)
--   2) AFTER  indexes.sql  -> screenshot / save the plans  (optimised)
-- Look at: scan type, "Execution Time", "Buffers: shared hit/read".
-- =====================================================================

\echo '--- Q1: all orders of one customer (lookup by email, then orders) ---'
EXPLAIN (ANALYZE, BUFFERS)
SELECT o.order_id, o.order_date, o.status
FROM   customers c
JOIN   orders o ON o.customer_id = c.customer_id
WHERE  c.email = 'customer1234@example.com'
ORDER  BY o.order_date DESC;

\echo '--- Q2: orders placed in a date range with a given status ---'
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, customer_id, order_date
FROM   orders
WHERE  status = 'DELIVERED'
  AND  order_date >= NOW() - interval '30 days';

\echo '--- Q3: products in a category within a price range ---'
EXPLAIN (ANALYZE, BUFFERS)
SELECT product_id, name, price
FROM   products
WHERE  category_id = 1
  AND  price BETWEEN 50000 AND 60000
ORDER  BY price;

\echo '--- Q4: how many units of one product have been sold ---'
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.name, SUM(oi.quantity) AS units_sold
FROM   order_items oi
JOIN   products p ON p.product_id = oi.product_id
WHERE  oi.product_id = 777
GROUP  BY p.name;

\echo '--- Q5: total money spent by one customer on completed orders ---'
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.full_name, SUM(oi.quantity * oi.unit_price) AS total_spent
FROM   customers c
JOIN   orders o       ON o.customer_id = c.customer_id
JOIN   order_items oi ON oi.order_id   = o.order_id
WHERE  c.customer_id = 1234
  AND  o.status IN ('PAID','SHIPPED','DELIVERED')
GROUP  BY c.full_name;
