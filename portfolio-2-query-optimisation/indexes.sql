-- =====================================================================
-- Portfolio 2: indexes chosen from the BEFORE plans
-- PostgreSQL automatically indexes PRIMARY KEY and UNIQUE columns, but
-- NOT foreign-key columns, so joins on them start as sequential scans.
-- =====================================================================

-- Q1 + Q5: find a customer's orders without scanning every order
CREATE INDEX idx_orders_customer_id ON orders (customer_id);

-- Q2: filter by status AND a date range (equality column first, range column second)
CREATE INDEX idx_orders_status_date ON orders (status, order_date);

-- Q3: filter by category, then narrow by price (also returns rows already sorted by price)
CREATE INDEX idx_products_category_price ON products (category_id, price);

-- Q4 + Q5: the composite PK (order_id, product_id) helps lookups by order_id only,
-- so lookups by product_id need their own index
CREATE INDEX idx_order_items_product_id ON order_items (product_id);

ANALYZE;

-- List the indexes to screenshot
SELECT tablename, indexname FROM pg_indexes
WHERE schemaname = 'public' ORDER BY tablename, indexname;
