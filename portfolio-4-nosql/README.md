# Portfolio 4: NoSQL and Advanced Data Models

**Case study:** NaijaMart / MiniPlace online store. **Database:** MongoDB (document model).

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

## Design decisions (be ready to explain these)

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

## Results (fill in YOUR numbers from your own run)

| Query | docsExamined before index | docsExamined after index | Time before (ms) | Time after (ms) |
|---|---|---|---|---|
| Orders by customer email | | | | |

## Reflection notes (write in your own words)

- Which parts of the store fit documents better than tables, and which do not?
- What did I lose by embedding data (hint: duplication, consistency)?
- How is the aggregation pipeline similar to and different from SQL?
