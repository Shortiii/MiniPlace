# Portfolio 2: Query Processing and Optimisation

**Case study:** NaijaMart / MiniPlace online store (same schema as Portfolio 1).

## Files

| File | Purpose |
|---|---|
| `seed.sql` | Generates test data: 5,000 customers, 2,000 products, 30,000 orders, 75,000 order items, payments, deliveries |
| `queries.sql` | 5 queries, each run with `EXPLAIN (ANALYZE, BUFFERS)` |
| `indexes.sql` | 4 indexes chosen from the baseline plans |
| `screenshots/` | Plans before and after indexing |

## How to run (psql)

```
\c naijamart
\i 'C:/path/to/portfolio-1-database-design/schema.sql'
\i 'C:/path/to/portfolio-2-query-optimisation/seed.sql'
\i 'C:/path/to/portfolio-2-query-optimisation/queries.sql'     -- BASELINE: screenshot this
\i 'C:/path/to/portfolio-2-query-optimisation/indexes.sql'
\i 'C:/path/to/portfolio-2-query-optimisation/queries.sql'     -- OPTIMISED: screenshot this
```

## What I tested and why (explain this in your own words)

| # | Query | Why it is slow at first | Index added |
|---|---|---|---|
| Q1 | A customer's orders (join on email) | `orders.customer_id` is a foreign key, and PostgreSQL does not index foreign keys, so it scans all 30,000 orders | `orders(customer_id)` |
| Q2 | Delivered orders in the last 30 days | Filters on status and a date range, so it scans the whole table | `orders(status, order_date)` |
| Q3 | Products in a category and price range | Sequential scan of all products | `products(category_id, price)` |
| Q4 | Units sold of one product | The primary key `(order_id, product_id)` cannot be used to search by `product_id` alone | `order_items(product_id)` |
| Q5 | Total spent by one customer | Scans orders to find the customer's rows | Reuses `orders(customer_id)` |

**Column order in a composite index matters.** In `(status, order_date)`, the equality column (`status`) goes first and the range column (`order_date`) second. The index can then jump to one status and read the date range in order.

## Results (fill in YOUR numbers from your own run)

Your times will differ from anyone else's, since they depend on your machine. Copy the `Execution Time` line from each plan.

| Query | Scan type BEFORE | Time BEFORE (ms) | Scan type AFTER | Time AFTER (ms) |
|---|---|---|---|---|
| Q1 | | | | |
| Q2 | | | | |
| Q3 | | | | |
| Q4 | | | | |
| Q5 | | | | |

## How to read an EXPLAIN plan

- **Seq Scan:** reads every row in the table. Fine for small tables, slow for big ones.
- **Index Scan / Bitmap Index Scan:** uses an index to jump to the matching rows.
- **actual time / Execution Time:** the real time taken, in milliseconds.
- **Buffers: shared hit / read:** pages read from memory (hit) or disk (read). Fewer is better.

## Trade-offs (include this in your analysis)

- Indexes make reads faster but make writes (INSERT/UPDATE/DELETE) slightly slower, because every index must be updated too.
- Indexes use disk space.
- On very small tables, PostgreSQL may ignore an index and use a sequential scan anyway, because that is cheaper. This is not a bug.

## Reflection notes (write in your own words)

- Which index gave the biggest improvement, and why?
- What did the plan look like before and after for that query?
- When would I NOT add an index?
