-- =====================================================================
-- Portfolio 3 (c): THE PROBLEM - overselling the last item (lost update)
--
-- Run this SAME file in TWO psql windows (call them A and B).
-- Start A, then start B within ~8 seconds (A pauses 10 s on purpose
-- to simulate "the app is thinking" between reading and writing).
--
--   Window A:  \i '03_lost_update_session.sql'
--   Window B:  \i '03_lost_update_session.sql'      (quickly!)
--
-- Both sessions READ stock = 1, both decide "OK, I can sell it", and both
-- WRITE stock = 0. Two customers get the one phone.
-- =====================================================================
BEGIN;

-- Step 1: read the stock (no lock)
SELECT stock_qty AS stock_seen FROM products WHERE name = 'Last Phone' \gset
\echo 'I saw stock =' :stock_seen

-- Step 2: pause so the other window can do the same read
SELECT pg_sleep(10);

-- Step 3: the "application" checks and writes back a value it computed itself
\if :stock_seen
  UPDATE products SET stock_qty = :stock_seen - 1 WHERE name = 'Last Phone';

  INSERT INTO orders (customer_id, address_id, status) VALUES (1, 1, 'PAID');
  INSERT INTO order_items (order_id, product_id, quantity, unit_price)
  SELECT currval(pg_get_serial_sequence('orders','order_id')), product_id, 1, price
  FROM products WHERE name = 'Last Phone';
  \echo 'I sold the phone.'
\else
  \echo 'Out of stock, not selling.'
\endif

COMMIT;

\echo '=== RESULT ==='
SELECT stock_qty FROM products WHERE name = 'Last Phone';
SELECT count(*) AS phones_sold
FROM order_items oi JOIN products p USING (product_id)
WHERE p.name = 'Last Phone';
