# Portfolio 1: Database Design and Modelling

**Case study:** MiniPlace (simulated online retail platform). See the root README.

## Contents

| File | What it is |
|---|---|
| `er-diagram.md` | ER diagram (Mermaid) with relationship explanations |
| `schema.sql` | Relational schema: tables, keys, constraints, a view, and small sample data |
| `tests.sql` | Seven deliberately invalid statements that the database must reject |
| `normalisation.md` | Walk-through from unnormalised data to 3NF, plus design decisions |
| `screenshots/` | Evidence that the schema runs |

## How I implemented and tested it

1. Installed PostgreSQL 18 locally on Windows and connected with `psql`.
2. Created the database: `CREATE DATABASE naijamart;` and connected to it with `\c naijamart`.
3. Ran the schema from the repo root: `\i portfolio-1-database-design/schema.sql`. All 8 tables and the `order_totals` view were created.
4. Verified the tables with `\dt` and the table structures with `\d orders` and `\d order_items`.
5. Checked that the view works: `SELECT * FROM order_totals;`.
6. Tested constraints by deliberately breaking them (`\i portfolio-1-database-design/tests.sql`) and confirming PostgreSQL rejects each bad statement.

## Evidence (screenshots)

- [x] `\dt` showing all 8 tables
- [x] `\d orders` and `\d order_items` showing keys and constraints
- [x] `SELECT * FROM order_totals;` returning the sample order
- [x] The constraint-violation errors from `tests.sql`
- [x] The ER diagram rendered on GitHub

## Constraint tests: what each one proves

| Test | Rule it breaks | Error PostgreSQL gave |
|---|---|---|
| Duplicate email | `UNIQUE (email)` | duplicate key value violates unique constraint |
| Negative stock | `CHECK (stock_qty >= 0)` | violates check constraint |
| Quantity of 0 | `CHECK (quantity > 0)` | violates check constraint |
| Invalid order status | `CHECK (status IN (...))` | violates check constraint |
| Order for a missing customer | Foreign key | violates foreign key constraint |
| Same product twice in one order | Composite primary key | duplicate key value violates unique constraint |
| Second delivery for one order | `UNIQUE (order_id)` | duplicate key value violates unique constraint |

## Reflection notes

**Design choice I am most confident about:**

Storing `unit_price` on each order item instead of reading the price from `products`. Product prices change over time, but an old order must keep the price the customer actually paid. It looks like duplicated data, but it is a different fact, so it is still correct in 3NF.

**Something that was difficult:**

Setting up the tools on Windows. After installing PostgreSQL, `psql` was not recognised until I added its folder to my PATH, and I had to reset the `postgres` password because my first one was rejected. I also had to learn to run SQL files from the right folder with `\i`.

**Something I would do differently:**

I would add an index on the foreign key columns from the start. PostgreSQL does not index foreign keys automatically, which I see in Portfolio 2 when queries on `orders.customer_id` begin as slow sequential scans.