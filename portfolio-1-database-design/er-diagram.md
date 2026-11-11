# ER Diagram: MiniPlace

Rendered automatically by GitHub (Mermaid). Crow's-foot notation:
`||` = exactly one, `o{` = zero or many, `|{` = one or many, `o|` = zero or one.

```mermaid
erDiagram
    CUSTOMERS ||--o{ ADDRESSES  : "has"
    CUSTOMERS ||--o{ ORDERS     : "places"
    ADDRESSES ||--o{ ORDERS     : "ships to"
    CATEGORIES ||--o{ PRODUCTS  : "classifies"
    ORDERS ||--|{ ORDER_ITEMS   : "contains"
    PRODUCTS ||--o{ ORDER_ITEMS : "appears in"
    ORDERS ||--o{ PAYMENTS      : "paid by"
    ORDERS ||--o| DELIVERIES    : "fulfilled by"

    CUSTOMERS {
        int customer_id PK
        varchar full_name
        varchar email UK
        varchar phone
        timestamp created_at
    }
    ADDRESSES {
        int address_id PK
        int customer_id FK
        varchar street
        varchar city
        varchar state
        boolean is_default
    }
    CATEGORIES {
        int category_id PK
        varchar name UK
    }
    PRODUCTS {
        int product_id PK
        int category_id FK
        varchar name
        text description
        numeric price
        int stock_qty
        timestamp created_at
    }
    ORDERS {
        int order_id PK
        int customer_id FK
        int address_id FK
        timestamp order_date
        varchar status
    }
    ORDER_ITEMS {
        int order_id PK, FK
        int product_id PK, FK
        int quantity
        numeric unit_price
    }
    PAYMENTS {
        int payment_id PK
        int order_id FK
        numeric amount
        varchar method
        varchar status
        timestamp paid_at
    }
    DELIVERIES {
        int delivery_id PK
        int order_id FK, UK
        varchar courier_name
        varchar status
        timestamp dispatched_at
        timestamp delivered_at
    }
```

## Relationships explained

| Relationship | Cardinality | Why |
|---|---|---|
| Customer to Address | 1 : N | A customer can save home, office, etc. |
| Customer to Order | 1 : N | A customer can place many orders. |
| Address to Order | 1 : N | Each order ships to one saved address. |
| Category to Product | 1 : N | Each product belongs to one category. |
| Order to Product | M : N | Resolved by the `order_items` junction table. |
| Order to Payment | 1 : N | Failed payment attempts can be retried. |
| Order to Delivery | 1 : 0..1 | Delivery record is created once the order is dispatched (`UNIQUE order_id`). |
