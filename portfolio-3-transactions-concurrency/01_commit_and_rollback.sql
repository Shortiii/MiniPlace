-- =====================================================================
-- Portfolio 3 (a): atomic order placement with COMMIT and ROLLBACK
-- Requires: schema.sql loaded (sample data is fine; seed.sql also fine).
-- Run in psql. Screenshot the output of each step.
-- =====================================================================

-- Make a product with limited stock so the failure case is predictable
INSERT INTO categories (name) VALUES ('Demo') ON CONFLICT DO NOTHING;
INSERT INTO products (category_id, name, price, stock_qty)
VALUES ((SELECT category_id FROM categories WHERE name = 'Demo'),
        'Demo Gadget', 10000.00, 5)
RETURNING product_id, name, stock_qty;
-- Note the product_id returned above and use it below (this file assumes it is
-- the product named 'Demo Gadget'; we look it up by name to be safe).

\echo '=== STOCK BEFORE ==='
SELECT product_id, name, stock_qty FROM products WHERE name = 'Demo Gadget';

-- ---------------------------------------------------------------------
-- SUCCESSFUL TRANSACTION: buy 2 units. All steps succeed together.
-- ---------------------------------------------------------------------
BEGIN;

INSERT INTO orders (customer_id, address_id, status)
VALUES (1, 1, 'PENDING')
RETURNING order_id;                       -- note this id

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT currval(pg_get_serial_sequence('orders','order_id')),
       product_id, 2, price
FROM   products WHERE name = 'Demo Gadget';

UPDATE products SET stock_qty = stock_qty - 2 WHERE name = 'Demo Gadget';

INSERT INTO payments (order_id, amount, method, status, paid_at)
VALUES (currval(pg_get_serial_sequence('orders','order_id')),
        20000.00, 'CARD', 'SUCCESS', NOW());

UPDATE orders SET status = 'PAID'
WHERE order_id = currval(pg_get_serial_sequence('orders','order_id'));

COMMIT;

\echo '=== STOCK AFTER SUCCESSFUL ORDER (expect 3) ==='
SELECT name, stock_qty FROM products WHERE name = 'Demo Gadget';

-- ---------------------------------------------------------------------
-- FAILED TRANSACTION: try to buy 10 units when only 3 are left.
-- The CHECK (stock_qty >= 0) constraint rejects the stock update, so the
-- order row and order item created earlier in the SAME transaction must
-- disappear too. That is atomicity.
-- ---------------------------------------------------------------------
\echo '=== ORDER COUNT BEFORE FAILED ATTEMPT ==='
SELECT count(*) AS orders_before FROM orders;

BEGIN;

INSERT INTO orders (customer_id, address_id, status)
VALUES (1, 1, 'PENDING');

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT currval(pg_get_serial_sequence('orders','order_id')),
       product_id, 10, price
FROM   products WHERE name = 'Demo Gadget';

-- This fails: stock would become -7. PostgreSQL marks the transaction as aborted.
UPDATE products SET stock_qty = stock_qty - 10 WHERE name = 'Demo Gadget';

-- Any further command now errors with "current transaction is aborted".
ROLLBACK;

\echo '=== AFTER ROLLBACK: nothing from the failed attempt was saved ==='
SELECT count(*) AS orders_after FROM orders;           -- same as orders_before
SELECT name, stock_qty FROM products WHERE name = 'Demo Gadget';   -- still 3

-- ---------------------------------------------------------------------
-- SAVEPOINT example: undo only part of a transaction
-- ---------------------------------------------------------------------
BEGIN;
UPDATE products SET stock_qty = stock_qty - 1 WHERE name = 'Demo Gadget';   -- keep this
SAVEPOINT before_bad_step;
UPDATE products SET stock_qty = stock_qty - 100 WHERE name = 'Demo Gadget'; -- fails
ROLLBACK TO SAVEPOINT before_bad_step;                                      -- undo only the failed part
COMMIT;

\echo '=== AFTER SAVEPOINT DEMO (expect 2) ==='
SELECT name, stock_qty FROM products WHERE name = 'Demo Gadget';
