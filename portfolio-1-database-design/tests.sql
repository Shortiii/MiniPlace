-- =====================================================================
-- Miniplace: constraint tests (Portfolio 1)
-- Each statement below SHOULD FAIL. Screenshot the error messages.
-- Run them one at a time in psql so each error is visible.
-- =====================================================================

-- 1. Duplicate email violates UNIQUE
INSERT INTO customers (full_name, email) VALUES ('Fake Ada', 'ada@example.com');

-- 2. Negative stock violates CHECK (stock_qty >= 0)
UPDATE products SET stock_qty = -5 WHERE product_id = 1;

-- 3. Zero quantity violates CHECK (quantity > 0)
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (1, 3, 0, 78000.00);

-- 4. Invalid status violates CHECK ... IN (...)
UPDATE orders SET status = 'LOST_IN_SPACE' WHERE order_id = 1;

-- 5. Foreign key violation: order for a customer that does not exist
INSERT INTO orders (customer_id, address_id) VALUES (999, 1);

-- 6. Duplicate product in the same order violates the composite primary key
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (1, 1, 1, 185000.00);

-- 7. Second delivery for the same order violates UNIQUE (order_id)
INSERT INTO deliveries (order_id, courier_name) VALUES (1, 'AnotherCourier');
