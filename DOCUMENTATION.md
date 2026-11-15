# MIT 8103 Advanced Database Systems: Final Documentation

**Name:** Oluwatoyin Oyelade
**Student ID:** 301922865
**Case study:** MiniPlace
**GitHub repository:** https://github.com/Shortiii/MiniPlace (private; assessor access granted: [yes/no])

---

## 1. Case study

MiniPlace is a simulated online retail platform selling electronics, fashion and groceries. Its users are customers, store administrators and delivery staff. It stores customers, addresses, categories, products, orders, order items, payments and deliveries. Key operations are adding products, placing orders, updating stock, processing payments and tracking delivery. The same store is used in all five portfolios.

## 2. Summary of work

### Portfolio 1: Database design and modelling
- Designed an ER diagram with 8 entities (customers, addresses, categories, products, orders, order_items, payments, deliveries) and a many-to-many relationship between orders and products resolved by `order_items`.
- Implemented the schema in PostgreSQL with primary keys, foreign keys and constraints (`UNIQUE` email, `CHECK` stock >= 0, `CHECK` quantity > 0, status lists).
- Normalised to 3NF. Key decisions: `unit_price` stored on order items (the price at purchase time, so old orders keep what the customer paid), no stored order total (derived by the `order_totals` view), and payments and deliveries as their own tables.
- Tested the constraints by deliberately inserting seven invalid rows; PostgreSQL rejected every one with the expected error.

### Portfolio 2: Query processing and optimisation
- Generated 5,000 customers, 2,000 products, 30,000 orders and 75,000 order items, then ran five queries with `EXPLAIN (ANALYZE, BUFFERS)`.
- Baseline plans used sequential scans on the larger tables. I added four indexes: `orders(customer_id)`, `orders(status, order_date)`, `products(category_id, price)` and `order_items(product_id)`.
- Results (before to after): Q1 8.363 ms to 0.206 ms (about 40x), Q2 10.572 ms to 2.017 ms (about 5x), Q3 0.543 ms to 0.187 ms (about 3x), Q4 7.889 ms to 0.236 ms (about 33x), Q5 6.878 ms to 0.586 ms (about 12x).
- The biggest gains came from indexing foreign key columns, which PostgreSQL does not index automatically. Q2 improved least because it returns about 3% of the table. Trade-off: indexes speed up reads but slow writes and use disk space.

### Portfolio 3: Transactions and concurrency
- Demonstrated an atomic order (COMMIT) and a failed order that was rolled back when the stock check failed, leaving the order count and stock unchanged, plus a savepoint that undid only part of a transaction.
- Reproduced a **lost update / overselling** problem: two sessions both read stock = 1 and both sold the last phone, giving 2 sales for 1 item.
- Fixed it with `SELECT ... FOR UPDATE` row locking: the second session waited, then saw stock = 0 and refused to sell, so only 1 phone was sold.
- Alternatives I considered: an atomic `UPDATE ... WHERE stock_qty > 0`, SERIALIZABLE isolation, and optimistic locking.

### Portfolio 4: NoSQL and advanced data models
- Modelled products and orders as MongoDB documents. Products carry category-specific attributes (for example RAM for phones, sizes for shoes); orders embed their items, payment and delivery.
- Ran queries on nested fields and arrays, an update with `$inc`, an aggregation pipeline for revenue per category, and an index comparison: a query on 20,003 orders examined all 20,003 documents without an index (`COLLSCAN`) and only 4 with one (`IXSCAN`).
- Trade-off: embedding gives fast single-read orders but duplicates some data, such as the customer's name and email.

### Portfolio 5: Distributed and cloud database systems
- Built a three-node MongoDB replica set locally, wrote data with majority write concern, stopped the primary and observed an automatic election (27119 became the new primary within seconds).
- Writes continued with two of three nodes alive, and the stopped node rejoined as a secondary. With only one node alive, majority writes failed, showing consistency being chosen over availability.
- Wrote a sharding design: hashed `customer_id` as the shard key for orders, and why `order_date` and `status` would be poor keys.
- Discussed consistency versus availability (CAP) for orders and payments versus product browsing.

## 3. Challenges and how I solved them

- **Tool setup on Windows:** after installing PostgreSQL, `psql` was not recognised in my terminal, so I added the PostgreSQL `bin` folder to my PATH. My first password attempt was also rejected, which I fixed by resetting the `postgres` password.
- **Git and folder layout:** my unzipped files ended up in a nested folder, so I moved them into the repo root, and my first push failed with "Repository not found" until I fixed my GitHub sign-in.
- **ER diagram:** it did not render on GitHub at first, because of the way I listed two keys on one attribute. I simplified the syntax so it renders.
- **Concurrency demo timing:** the overselling demo only works if the second window starts within 10 seconds of the first, so I prepared the command in window B before starting window A.
- **MongoDB timing:** the first query after creating an index looked slower (99 ms), which I traced to a cold start; repeat runs took under 1 ms, so I used `docsExamined` as the reliable measure.

## 4. Reflection

The biggest thing I learned is that the right database depends on the job. Relational tables were the better choice for money and stock, because constraints and transactions stop bad data, while MongoDB documents were better for products with different attributes and for reading a whole order in one go.

The concurrency portfolio taught me the most. Seeing two customers buy the last phone made the idea of a lost update real, and fixing it with `FOR UPDATE` showed me that correctness sometimes means making one user wait. It changed how I think about stock updates in a real shop: the check and the write have to happen together, either through a lock or a single atomic update.

Portfolio 2 showed me that indexing foreign keys is not automatic and that reading an execution plan is a skill in itself. In Portfolio 5, stopping the primary and watching another node