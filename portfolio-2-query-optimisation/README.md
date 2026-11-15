# Portfolio 2: Query Processing and Optimisation

**Case study:** MiniPlace online store (same schema as Portfolio 1).

## Files

| File | Purpose |
|---|---|
| `seed.sql` | Generates test data: 5,000 customers, 2,000 products, 30,000 orders, 75,000 order items, payments, deliveries |
| `queries.sql` | 5 queries, each run with `EXPLAIN (ANALYZE, BUFFERS)` |
| `indexes.sql` | 4 indexes chosen from the baseline plans |
| `screenshots/` | Plans before and after indexing |

## How I ran it (psql, from the repo root)

```
\c naijamart
\i portfolio-1-database-design/schema.sql
\i portfolio-2-query-optimisation/seed.sql
\i portfolio-2-query-optimisation/queries.sql     -- BASELINE (before indexes)
\i portfolio-2-query-optimisation/indexes.sql
\i portfolio-2-query-optimisation/queries.sql     -- OPTIMISED (after indexes)
```

## What I tested and why

| # | Query | Why it is slow at first | Index added |
|---|---|---|---|
| Q1 | A customer's orders (join on email) | `orders.customer_id` is a foreign key, and PostgreSQL does not index foreign keys, so it scans all 30,000 orders | `orders(customer_id)` |
| Q2 | Delivered orders in the last 30 days | Filters on status and a date range, so it scans the whole table | `orders(status, order_date)` |
| Q3 | Products in a category and price range | Sequential scan of all products | `products(category_id, price)` |
| Q4 | Units sold of one product | The primary key `(order_id, product_id)` cannot be used to search by `product_id` alone | `order_items(product_id)` |
| Q5 | Total spent by one customer | Scans orders to find the customer's rows | Reuses `orders(customer_id)` |

**Column order in a composite index matters.** In `(status, order_date)`, the equality column (`status`) goes first and the range column (`order_date`) second. The index can then jump to one status and read the date range in order.

## Results (from my own run)

| Query | Scan type BEFORE | Time BEFORE (ms) | Scan type AFTER | Time AFTER (ms) | Faster by |
|---|---|---|---|---|---|
| Q1 | Seq Scan on `orders` | 8.363 | Bitmap Index Scan on `idx_orders_customer_id` | 0.206 | about 40x |
| Q2 | Seq Scan on `orders` | 10.572 | Bitmap Index Scan on `idx_orders_status_date` | 2.017 | about 5x |
| Q3 | Seq Scan on `products` | 0.543 | Bitmap Index Scan on `idx_products_category_price` | 0.187 | about 3x |
| Q4 | Seq Scan on `order_items` | 7.889 | Bitmap Index Scan on `idx_order_items_product_id` | 0.236 | about 33x |
| Q5 | Seq Scan on `orders` | 6.878 | Bitmap Index Scan on `idx_orders_customer_id` | 0.586 | about 12x |

Screenshots of the plans before and after are in the `screenshots/` folder.

## Analysis

Without indexes, Q1, Q2, Q4 and Q5 each scanned a whole table (30,000 orders or 75,000 order items) and discarded almost every row. For example, Q4 read 481 buffers and removed 74,970 rows to find 30. After adding the indexes, Q4 read about 35 buffers and ran about 33 times faster. The biggest gains came from indexing the foreign key columns `orders.customer_id` and `order_items.product_id`.

The gain was smallest for Q2 (about 5x). It returns about 970 rows, around 3% of the table, spread across 226 pages, so the index still has to fetch many rows. Q3 changed little in absolute terms because `products` has only 2,000 rows, so even the sequential scan was fast.

## How to read an EXPLAIN plan

- **Seq Scan:** reads every row in the table. Fine for small tables, slow for big ones.
- **Index Scan / Bitmap Index Scan:** uses an index to jump to the matching rows.
- **actual time / Execution Time:** the real time taken, in milliseconds.
- **Buffers: shared hit / read:** pages read from memory (hit) or disk (read). Fewer is better.

## Trade-offs

- Indexes make reads faster but make writes (INSERT/UPDATE/DELETE) slightly slower, because every index must be updated too.
- Indexes use disk space.
- On very small tables, PostgreSQL may ignore an index and use a sequential scan anyway, because that is cheaper. This is not a bug.

## Reflection notes

**Which index gave the biggest improvement, and why?**

The index on `orders(customer_id)` gave the biggest improvement, about 40x for Q1. Without it, PostgreSQL had to read all 30,000 orders to find one customer's 7 orders. With it, PostgreSQL could jump straight to those rows.

**What did the plan look like before and after for that query?**

Before, Q1 used a Seq Scan on `orders`, read 239 buffers and took 8.363 ms. After, it used a Bitmap Index Scan on `idx_orders_customer_id`, read about 11 buffers and took 0.206 ms.

**When would I NOT add an index?**

On a very small table, where a sequential scan is already fast, or on a column that is rarely used in filters or joins. Every index also slows down inserts, updates and deletes and uses disk space, so an index that is not used is just a cost.