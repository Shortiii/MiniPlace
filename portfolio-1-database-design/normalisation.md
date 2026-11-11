# Normalisation Explanation (MiniPlace)

## Step 0: Unnormalised starting point

Imagine MiniPlace first tracked orders in one flat sheet:

| order_id | customer_name | customer_email | customer_phones | delivery_address | products | quantities | category | prices | payment_method | payment_status | courier |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Ada Okafor | ada@example.com | 0803..., 0805... | 12 Allen Ave, Ikeja | Infinix Hot 40, Ankara Shirt | 1, 2 | Electronics, Fashion | 185000, 8500 | CARD | SUCCESS | SwiftRiders |

Problems: repeating groups in a cell, the customer's details repeat on every order, and changing one price means hunting through many rows.

## First Normal Form (1NF): atomic values, no repeating groups

Rule: every cell holds one value, and every row is uniquely identifiable.

- Split multi-value cells (several products, quantities, prices) into **one row per product per order**.
- Primary key becomes the composite **(order_id, product_id)**.

Result: `order_items` rows instead of comma-separated lists.

## Second Normal Form (2NF): no partial dependencies

Rule: be in 1NF, and every non-key attribute depends on the **whole** key, not part of it.

With key (order_id, product_id):
- `product_name`, `category`, `price` depend only on **product_id**.
- `customer_name`, `customer_email`, `delivery_address`, `order_date` depend only on **order_id**.

These are partial dependencies, so we split them out:
- `products` (product_id, name, category, price, ...)
- `orders` (order_id, customer details, address, date)
- `order_items` keeps only (order_id, product_id, quantity, unit_price), which depend on the full key.

## Third Normal Form (3NF): no transitive dependencies

Rule: be in 2NF, and non-key attributes depend **only on the key**, not on other non-key attributes.

Transitive dependencies found:
- `orders.customer_id` to `customer_name`, `email`, `phone`. Moved to **customers**.
- `orders.address_id` to `street`, `city`, `state`. Moved to **addresses**.
- `products.category_id` to `category_name`. Moved to **categories**.
- Payment attributes (method, status, amount) depend on the payment, not the order. Moved to **payments**.
- Courier and delivery timestamps depend on the delivery, not the order. Moved to **deliveries**.

Final result: 8 tables (`customers`, `addresses`, `categories`, `products`, `orders`, `order_items`, `payments`, `deliveries`), each fact stored in exactly one place.

## Deliberate design decisions (be ready to explain these)

1. **`order_items.unit_price` looks like duplication of `products.price`, but it is not.** The product price can change next month; a historical order must keep the price the customer actually paid. It is a different fact (price at purchase time), so it is correct in 3NF.
2. **No `total_amount` column in `orders`.** It is derivable from `order_items`, and storing it would create an update anomaly. The `order_totals` view calculates it on demand.
3. **Payments are separate from orders** so one order can have a failed attempt followed by a successful one.
4. **Constraints enforce business rules in the database itself:** `CHECK (stock_qty >= 0)` prevents negative stock, `CHECK (quantity > 0)`, status lists via `CHECK ... IN (...)`, and `UNIQUE (email)`.
5. **Foreign key behaviour:** `ON DELETE CASCADE` on child records that make no sense without the parent (addresses, order items, payments, deliveries). Products and customers referenced by orders are *not* cascaded, so history cannot be wiped by accident.

## Anomalies the design prevents

| Anomaly | Flat sheet | MiniPlace schema |
|---|---|---|
| Update | Change a customer's email in many rows | Change it once in `customers` |
| Insert | Cannot add a product until someone orders it | Insert straight into `products` |
| Delete | Deleting the only order for a product loses the product | Product survives in `products` |
