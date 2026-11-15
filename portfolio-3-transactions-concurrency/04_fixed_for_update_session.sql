-- =====================================================================
-- Portfolio 3 (d): THE FIX - pessimistic locking with SELECT ... FOR UPDATE
--
-- Run 02_setup_last_item.sql first, then run this file in TWO windows:
--   Window A:  \i '04_fixed_for_update_session.sql'
--   Window B:  \i '04_fixed_for_update_session.sql'   (quickly!)
--
-- FOR UPDATE locks the row when it is read. Window B's SELECT must WAIT until
-- A commits. When B finally reads, it sees stock = 0 and refuses to sell.
-- =====================================================================
BEGIN;

-- Step 1: read AND lock the row
SELECT stock_qty AS stock_seen FROM products WHERE name = 'Last Phone' FOR UPDATE \gset
\echo 'I saw stock =' :stock_seen

-- Step 2: same pause as before (B is blocked above, so it never reaches here early)
SELECT pg_sleep(10);

-- Step 3: sell only if stock is available
\if :stock_seen
  UPDATE products SET stock_qty = stock_qty - 1 WHERE name = 'Last Phone';

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
