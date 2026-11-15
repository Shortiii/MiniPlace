-- =====================================================================
-- Portfolio 2: bulk test data for MiniPlace/NaijaMart (PostgreSQL)
-- Run AFTER schema.sql:  \i 'seed.sql'
-- WARNING: this empties every table first (including the small sample rows).
-- Generates: 5,000 customers, 6 categories, 2,000 products,
--            30,000 orders, ~75,000 order items, payments, deliveries.
-- =====================================================================

TRUNCATE deliveries, payments, order_items, orders, products,
         categories, addresses, customers RESTART IDENTITY CASCADE;

-- Customers
INSERT INTO customers (full_name, email, phone, created_at)
SELECT 'Customer ' || g,
       'customer' || g || '@example.com',
       '080' || lpad(g::text, 8, '0'),
       NOW() - make_interval(days => (random() * 700)::int)
FROM generate_series(1, 5000) g;

-- One address per customer (address_id will equal customer_id)
INSERT INTO addresses (customer_id, street, city, state, is_default)
SELECT g,
       g || ' Market Road',
       (ARRAY['Ikeja','Wuse','Garki','Ikoyi','Yaba','Surulere'])[1 + (g % 6)],
       (ARRAY['Lagos','Abuja','Abuja','Lagos','Lagos','Lagos'])[1 + (g % 6)],
       TRUE
FROM generate_series(1, 5000) g;

-- Categories
INSERT INTO categories (name) VALUES
  ('Electronics'), ('Fashion'), ('Groceries'),
  ('Home'), ('Beauty'), ('Sports');

-- Products
INSERT INTO products (category_id, name, description, price, stock_qty)
SELECT 1 + (g % 6),
       'Product ' || g,
       'Description for product ' || g,
       round((500 + random() * 200000)::numeric, 2),
       10 + (random() * 500)::int
FROM generate_series(1, 2000) g;

-- Orders (spread over the last 365 days)
INSERT INTO orders (customer_id, address_id, order_date, status)
SELECT c, c,
       NOW() - make_interval(days => (random() * 365)::int,
                             mins => (random() * 1440)::int),
       (ARRAY['PENDING','PAID','SHIPPED','DELIVERED','DELIVERED','CANCELLED'])[1 + (random() * 5)::int]
FROM (SELECT 1 + (random() * 4999)::int AS c
      FROM generate_series(1, 30000)) t;

-- Order items: 1 to 4 distinct products per order
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT o.order_id,
       p.product_id,
       1 + ((o.order_id + k) % 3),
       p.price
FROM orders o
JOIN generate_series(1, 4) k ON k <= 1 + (o.order_id % 4)
JOIN products p ON p.product_id = 1 + ((o.order_id * 7 + k * 131) % 2000);

-- Payments for every order that is not pending/cancelled
INSERT INTO payments (order_id, amount, method, status, paid_at)
SELECT t.order_id, t.total_amount,
       (ARRAY['CARD','TRANSFER','USSD','CASH_ON_DELIVERY'])[1 + (t.order_id % 4)],
       'SUCCESS',
       t.order_date + interval '5 minutes'
FROM order_totals t
WHERE t.status IN ('PAID','SHIPPED','DELIVERED');

-- Deliveries for shipped/delivered orders
INSERT INTO deliveries (order_id, courier_name, status, dispatched_at, delivered_at)
SELECT order_id,
       (ARRAY['SwiftRiders','GIGLogistics','KwikDelivery'])[1 + (order_id % 3)],
       CASE WHEN status = 'DELIVERED' THEN 'DELIVERED' ELSE 'DISPATCHED' END,
       order_date + interval '1 day',
       CASE WHEN status = 'DELIVERED' THEN order_date + interval '3 days' END
FROM orders
WHERE status IN ('SHIPPED','DELIVERED');

-- Refresh planner statistics so EXPLAIN is realistic
ANALYZE;

-- Row counts to screenshot
SELECT 'customers' AS tbl, count(*) FROM customers
UNION ALL SELECT 'products',    count(*) FROM products
UNION ALL SELECT 'orders',      count(*) FROM orders
UNION ALL SELECT 'order_items', count(*) FROM order_items
UNION ALL SELECT 'payments',    count(*) FROM payments
UNION ALL SELECT 'deliveries',  count(*) FROM deliveries;
