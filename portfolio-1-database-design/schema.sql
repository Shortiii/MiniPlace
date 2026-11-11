-- =====================================================================
-- Miniplace: relational schema (PostgreSQL)
-- MIT 8103 Advanced Database Systems, Portfolio 1
-- Run with:  psql -U postgres -d miniplace -f schema.sql
-- =====================================================================

DROP TABLE IF EXISTS deliveries  CASCADE;
DROP TABLE IF EXISTS payments    CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders      CASCADE;
DROP TABLE IF EXISTS products    CASCADE;
DROP TABLE IF EXISTS categories  CASCADE;
DROP TABLE IF EXISTS addresses   CASCADE;
DROP TABLE IF EXISTS customers   CASCADE;

-- ---------------------------------------------------------------------
-- customers: people who buy from Miniplace
-- ---------------------------------------------------------------------
CREATE TABLE customers (
    customer_id  SERIAL        PRIMARY KEY,
    full_name    VARCHAR(100)  NOT NULL,
    email        VARCHAR(150)  NOT NULL UNIQUE,
    phone        VARCHAR(20),
    created_at   TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------
-- addresses: a customer can have many delivery addresses (1 : N)
-- ---------------------------------------------------------------------
CREATE TABLE addresses (
    address_id   SERIAL        PRIMARY KEY,
    customer_id  INT           NOT NULL
                 REFERENCES customers(customer_id) ON DELETE CASCADE,
    street       VARCHAR(200)  NOT NULL,
    city         VARCHAR(80)   NOT NULL,
    state        VARCHAR(80)   NOT NULL,
    is_default   BOOLEAN       NOT NULL DEFAULT FALSE
);

-- ---------------------------------------------------------------------
-- categories: electronics, fashion, groceries, ...
-- ---------------------------------------------------------------------
CREATE TABLE categories (
    category_id  SERIAL        PRIMARY KEY,
    name         VARCHAR(80)   NOT NULL UNIQUE
);

-- ---------------------------------------------------------------------
-- products: items for sale. stock_qty may never go negative.
-- ---------------------------------------------------------------------
CREATE TABLE products (
    product_id   SERIAL         PRIMARY KEY,
    category_id  INT            NOT NULL REFERENCES categories(category_id),
    name         VARCHAR(150)   NOT NULL,
    description  TEXT,
    price        NUMERIC(12,2)  NOT NULL CHECK (price >= 0),
    stock_qty    INT            NOT NULL DEFAULT 0 CHECK (stock_qty >= 0),
    created_at   TIMESTAMP      NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------
-- orders: one row per checkout
-- ---------------------------------------------------------------------
CREATE TABLE orders (
    order_id     SERIAL       PRIMARY KEY,
    customer_id  INT          NOT NULL REFERENCES customers(customer_id),
    address_id   INT          NOT NULL REFERENCES addresses(address_id),
    order_date   TIMESTAMP    NOT NULL DEFAULT NOW(),
    status       VARCHAR(20)  NOT NULL DEFAULT 'PENDING'
                 CHECK (status IN ('PENDING','PAID','SHIPPED','DELIVERED','CANCELLED'))
);

-- ---------------------------------------------------------------------
-- order_items: resolves the many-to-many between orders and products.
-- Composite primary key (order_id, product_id).
-- unit_price is the price AT THE TIME OF PURCHASE (products.price can
-- change later, but past orders must not change).
-- ---------------------------------------------------------------------
CREATE TABLE order_items (
    order_id     INT            NOT NULL
                 REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id   INT            NOT NULL REFERENCES products(product_id),
    quantity     INT            NOT NULL CHECK (quantity > 0),
    unit_price   NUMERIC(12,2)  NOT NULL CHECK (unit_price >= 0),
    PRIMARY KEY (order_id, product_id)
);

-- ---------------------------------------------------------------------
-- payments: an order may have several attempts (e.g. one failed, one ok)
-- ---------------------------------------------------------------------
CREATE TABLE payments (
    payment_id   SERIAL         PRIMARY KEY,
    order_id     INT            NOT NULL
                 REFERENCES orders(order_id) ON DELETE CASCADE,
    amount       NUMERIC(12,2)  NOT NULL CHECK (amount > 0),
    method       VARCHAR(20)    NOT NULL
                 CHECK (method IN ('CARD','TRANSFER','USSD','CASH_ON_DELIVERY')),
    status       VARCHAR(20)    NOT NULL DEFAULT 'PENDING'
                 CHECK (status IN ('PENDING','SUCCESS','FAILED','REFUNDED')),
    paid_at      TIMESTAMP
);

-- ---------------------------------------------------------------------
-- deliveries: at most one delivery record per order (1 : 0..1)
-- ---------------------------------------------------------------------
CREATE TABLE deliveries (
    delivery_id    SERIAL       PRIMARY KEY,
    order_id       INT          NOT NULL UNIQUE
                   REFERENCES orders(order_id) ON DELETE CASCADE,
    courier_name   VARCHAR(100),
    status         VARCHAR(20)  NOT NULL DEFAULT 'PROCESSING'
                   CHECK (status IN ('PROCESSING','DISPATCHED','DELIVERED','FAILED')),
    dispatched_at  TIMESTAMP,
    delivered_at   TIMESTAMP,
    CHECK (delivered_at IS NULL OR dispatched_at IS NULL OR delivered_at >= dispatched_at)
);

-- ---------------------------------------------------------------------
-- View: order totals are DERIVED from order_items, not stored in orders.
-- Storing a total in orders would duplicate data and violate 3NF.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW order_totals AS
SELECT o.order_id,
       o.customer_id,
       o.order_date,
       o.status,
       SUM(oi.quantity * oi.unit_price) AS total_amount
FROM   orders o
JOIN   order_items oi ON oi.order_id = o.order_id
GROUP  BY o.order_id, o.customer_id, o.order_date, o.status;

-- ---------------------------------------------------------------------
-- Small sample data so you can screenshot working queries today.
-- (Bulk data for Portfolio 2 comes in a later script.)
-- ---------------------------------------------------------------------
INSERT INTO customers (full_name, email, phone) VALUES
  ('Ada Okafor',   'ada@example.com',  '08030000001'),
  ('Tunde Bello',  'tunde@example.com','08030000002');

INSERT INTO addresses (customer_id, street, city, state, is_default) VALUES
  (1, '12 Allen Avenue', 'Ikeja',  'Lagos', TRUE),
  (2, '5 Aminu Kano Cres', 'Wuse', 'Abuja', TRUE);

INSERT INTO categories (name) VALUES ('Electronics'), ('Fashion'), ('Groceries');

INSERT INTO products (category_id, name, description, price, stock_qty) VALUES
  (1, 'Infinix Hot 40',  '128GB smartphone',      185000.00, 25),
  (2, 'Ankara Shirt',    'Men''s cotton shirt',     8500.00, 60),
  (3, 'Rice 50kg',       'Local parboiled rice',   78000.00, 15);

INSERT INTO orders (customer_id, address_id, status) VALUES (1, 1, 'PAID');
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
  (1, 1, 1, 185000.00),
  (1, 2, 2,   8500.00);
INSERT INTO payments (order_id, amount, method, status, paid_at) VALUES
  (1, 202000.00, 'CARD', 'SUCCESS', NOW());
INSERT INTO deliveries (order_id, courier_name, status, dispatched_at) VALUES
  (1, 'SwiftRiders', 'DISPATCHED', NOW());
