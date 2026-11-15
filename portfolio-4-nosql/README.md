# Portfolio 4: NoSQL and Advanced Data Models

**Case study:** MiniPlace online store. **Database:** MongoDB (document model).

## Files

| File | Purpose |
|---|---|
| `nosql.js` | Creates the collections, inserts documents, runs queries, an aggregation, and an index comparison |
| `screenshots/` | mongosh output as evidence |

## How to run

1. Make sure the MongoDB service is running. The Windows installer starts it by default on port 27017.
2. Open a terminal in this folder and run:
   ```
   mongosh "mongodb://localhost:27017" --file nosql.js
   ```
   Or open `mongosh` and paste the file in sections, which gives clearer screenshots.
3. Screenshot the output. To see the stored documents in a friendlier view, open **MongoDB Compass** and connect to `mongodb://localhost:27017`.

## Why a document database for this part of the store?

| Need | SQL (Portfolios 1-3) | Document model (this portfolio) |
|---|---|---|
| Products with different attributes (phone RAM, shoe sizes, food expiry) | Many NULL columns, or extra attribute tables | Each document has the fields it needs, so `specs` and `attributes` can differ per product |
| Show a whole order on one screen | JOIN orders, items, payments, deliveries | One document read, because items and payment are embedded |
| Change the product shape later | `ALTER TABLE` | Just start storing the new field |

## Design decisions

1. **Embed order items, payment and delivery inside the order.** They are always read with the order and have no meaning without it. This gives fast reads and one atomic write per order.
2. **Snapshot name and price inside each item.** The product price may change later, but the order must keep what the customer paid. This is the same reason `unit_price` exists in the SQL schema.
3. **Products are a separate collection.** Products live on their own and are referenced by `sku`, so changing one product does not mean editing thousands of orders.
4. **Trade-off:** duplicated data (customer name and email repeated in each order) means updates must be handled deliberately. That is acceptable here because an order should record who the customer was at the time.

## What the script demonstrates

- Insert: `insertMany` for products and orders
- Queries on nested fields (`specs.ram_gb`) and arrays (`attributes.sizes`)
- Updates: `$inc` and `$set`
- Aggregation pipeline: `$unwind`, `$group`, `$sort`, equivalent to JOIN and GROUP BY in SQL
- Indexing: `explain("executionStats")` before and after an index on `customer.email`, comparing `COLLSCAN` (scans everything) with `IXSCAN` (uses the index)

## Results

| Query | docsExamined before index | docsExamined after index | Time before (ms) | Time after (ms) |
|---|---|---|---|---|
| Orders by customer email | 20003 | 4 | 10 | 0 (the first run right after creating the index took 99; repeat runs took 0) |

Before the index, MongoDB scanned all 20,003 orders (`COLLSCAN`) to return 4. After the index, it examined only 4 documents (`IXSCAN`). The first timing right after creating the index was slow (99 ms), which I believe was a one-off cold start, and repeat runs took under 1 ms. Screenshots are in the `screenshots/` folder.

## Reflection notes

**Which parts of the store fit documents better than tables, and which do not?**

Documents fit products and whole orders best. Phones have RAM and storage while shirts have sizes, and each product document could simply hold its own fields. An order with its items, payment and delivery sat in one document, so I could read it without any joins. Tables fit better for stock and money, because rules like "stock can never go below zero" are enforced by constraints and transactions, as I saw in Portfolios 1 and 3.

**What did I lose by embedding data (hint: duplication, consistency)?**

The customer's name and email are copied into every order. If a customer changes their email, old orders keep the old one, so I would have to decide whether to update them. MongoDB also does not check relationships the way foreign keys do, so nothing stops an order from using a product sku that does not exist unless my application checks it.

**How is the aggregation pipeline similar to and different from SQL?**

It does the same kind of job: `$match` is like WHERE, `$group` is like GROUP BY, and `$sort` is like ORDER BY. I used `$unwind` to split each order's items array into separate rows, which is similar to joining orders with an order_items table. The difference is that a pipeline is a series of stages written as JSON objects instead of one SQL statement, and because the data is nested I had to unwind the array first.