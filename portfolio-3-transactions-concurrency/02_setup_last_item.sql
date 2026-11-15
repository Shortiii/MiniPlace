-- =====================================================================
-- Portfolio 3 (b): reset the "last item in stock" scenario
-- Run this before EACH concurrency experiment.
-- =====================================================================
INSERT INTO categories (name) VALUES ('Demo') ON CONFLICT DO NOTHING;

DELETE FROM order_items WHERE product_id IN (SELECT product_id FROM products WHERE name = 'Last Phone');
DELETE FROM products WHERE name = 'Last Phone';

INSERT INTO products (category_id, name, price, stock_qty)
VALUES ((SELECT category_id FROM categories WHERE name = 'Demo'),
        'Last Phone', 150000.00, 1);

SELECT product_id, name, stock_qty FROM products WHERE name = 'Last Phone';
