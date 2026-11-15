# MIT 8103 Advanced Database Systems: Final Documentation

**Name:** <your full name> **Matric No:** <your matric number>
**Case study:** NaijaMart / MiniPlace
**GitHub repository:** <paste your private repo link> (assessor access granted: yes / no)

> Target length: 2-3 pages. Replace everything in <angle brackets>. Delete these grey instructions before submitting. Keep it to what you actually did and understood.

---

## 1. Case study

NaijaMart (repo name MiniPlace) is a simulated online retail platform selling electronics, fashion and groceries. Its users are customers, store administrators and delivery staff. It stores customers, addresses, categories, products, orders, order items, payments and deliveries. Key operations are adding products, placing orders, updating stock, processing payments and tracking delivery. The same store is used in all five portfolios.

## 2. Summary of work

### Portfolio 1: Database design and modelling
- Designed an ER diagram with 8 entities (customers, addresses, categories, products, orders, order_items, payments, deliveries) and a many-to-many relationship between orders and products resolved by `order_items`.
- Implemented the schema in PostgreSQL with primary keys, foreign keys and constraints (`UNIQUE` email, `CHECK` stock >= 0, `CHECK` quantity > 0, status lists).
- Normalised to 3NF. Key decisions: `unit_price` stored on order items (price at purchase time), no stored order total (derived by a view), payments and deliveries as their own tables.
- Tested constraints by deliberately inserting invalid data.
- <One sentence in your own words: the design decision you are most confident about.>

### Portfolio 2: Query processing and optimisation
- Generated about 30,000 orders and 75,000 order items, then ran five queries with `EXPLAIN (ANALYZE, BUFFERS)`.
- Baseline plans used sequential scans on the larger tables. Added four indexes: `orders(customer_id)`, `orders(status, order_date)`, `products(category_id, price)` and `order_items(product_id)`.
- Results: <paste your before/after times, for example "Q1 dropped from __ ms to __ ms">.
- Trade-off: indexes speed up reads but slow writes and use space.

### Portfolio 3: Transactions and concurrency
- Demonstrated an atomic order (COMMIT) and a failed order that was rolled back (stock check violated), plus a savepoint.
- Reproduced a **lost update / overselling** problem: two sessions both read stock = 1 and both sold the last item.
- Fixed it with `SELECT ... FOR UPDATE` row locking: the second session waited, saw stock = 0 and refused.
- Alternatives I considered: atomic `UPDATE ... WHERE stock_qty > 0`, SERIALIZABLE isolation, optimistic locking.

### Portfolio 4: NoSQL and advanced data models
- Modelled products and orders as MongoDB documents. Products carry category-specific attributes; orders embed items, payment and delivery.
- Ran queries on nested fields and arrays, an update with `$inc`, an aggregation pipeline for revenue per category, and an index comparison (`COLLSCAN` vs `IXSCAN`).
- Trade-off: embedding gives fast single-read orders but duplicates some data.

### Portfolio 5: Distributed and cloud database systems
- Built a three-node MongoDB replica set locally, wrote data with majority write concern, stopped the primary and observed an automatic election.
- Writes continued with two of three nodes alive. <If you did step 8: with only one node alive, majority writes failed, showing consistency being chosen over availability.>
- Wrote a sharding design: hashed `customer_id` as the shard key for orders, and why `order_date` and `status` would be poor keys.
- Discussed consistency versus availability (CAP) for orders and payments versus product browsing.

## 3. Challenges and how I solved them

<Write 3-5 honest points from your own experience. Real examples might include: installing PostgreSQL/MongoDB on Windows, Git push authentication errors, nested folders after unzipping, getting the two-window concurrency demo timed correctly, PowerShell script permissions. Say what went wrong and how you fixed it.>

## 4. Reflection

<Write this entirely in your own words, about 150-250 words. Suggested questions: What did I learn about the difference between relational and document databases? Which portfolio taught me the most and why? What would I do differently with more time? How did the concurrency demo change how I think about stock updates in a real shop?>

## 5. AI-use declaration

- **Tool used:** Claude (Anthropic).
- **What I used it for:** <Edit to match what you really did. For example: choosing the case study, drafting the initial SQL schema, seed script and MongoDB scripts, writing README templates, and explaining concepts such as normalisation, indexing, isolation and replication.>
- **How I verified and made it my own:** <Edit to match reality. For example: I installed PostgreSQL and MongoDB and ran every script myself; I took the screenshots from my own runs; I fixed errors that came up; I wrote my reflection myself; I can explain each design decision.>
- **What I did not use AI for:** <for example, the reflection and the analysis of my own results.>

## 6. References

- PostgreSQL Documentation: https://www.postgresql.org/docs/
- MongoDB Manual: https://www.mongodb.com/docs/manual/
- Course materials for MIT 8103.
