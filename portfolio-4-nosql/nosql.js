// =====================================================================
// Portfolio 4: NoSQL document model for NaijaMart / MiniPlace (MongoDB)
// Run with:
//   mongosh "mongodb://localhost:27017" --file nosql.js
// Or paste sections into mongosh one at a time (better for screenshots).
// NOTE: this script DROPS and recreates the database naijamart_nosql.
// =====================================================================
const shop = db.getSiblingDB("naijamart_nosql");
shop.dropDatabase();

// ---------------------------------------------------------------------
// 1. PRODUCTS: different categories have different attributes.
//    In SQL this needs many NULL columns or extra tables; here each
//    document simply carries the fields that make sense for it.
// ---------------------------------------------------------------------
shop.products.insertMany([
  { sku: "PH-001", name: "Infinix Hot 40", category: "Electronics", price: 185000, stock_qty: 25,
    specs: { ram_gb: 8, storage_gb: 128, battery_mah: 5000, colors: ["black", "green"] } },
  { sku: "PH-002", name: "Tecno Spark 20", category: "Electronics", price: 140000, stock_qty: 40,
    specs: { ram_gb: 4, storage_gb: 128, battery_mah: 5000, colors: ["blue"] } },
  { sku: "LP-001", name: "HP 15 Laptop", category: "Electronics", price: 520000, stock_qty: 8,
    specs: { ram_gb: 16, storage_gb: 512, screen_inches: 15.6 } },
  { sku: "SH-001", name: "Leather Sandals", category: "Fashion", price: 12000, stock_qty: 60,
    attributes: { sizes: [40, 41, 42, 43, 44], color: "brown", material: "leather" } },
  { sku: "SH-002", name: "Ankara Shirt", category: "Fashion", price: 8500, stock_qty: 90,
    attributes: { sizes: ["S", "M", "L", "XL"], color: "multi", material: "cotton" } },
  { sku: "GR-001", name: "Rice 50kg", category: "Groceries", price: 78000, stock_qty: 15,
    attributes: { weight_kg: 50, perishable: false } },
  { sku: "GR-002", name: "Fresh Tomatoes Basket", category: "Groceries", price: 9000, stock_qty: 30,
    attributes: { weight_kg: 5, perishable: true, expires: new Date("2026-11-30") } }
]);
print("Products inserted: " + shop.products.countDocuments());

// ---------------------------------------------------------------------
// 2. ORDERS: one document holds the order, its items and its payment.
//    Items embed a SNAPSHOT of name and price at purchase time (same idea
//    as unit_price in the SQL schema). One read returns the whole order,
//    with no joins.
// ---------------------------------------------------------------------
shop.orders.insertMany([
  { order_no: 1001,
    customer: { customer_id: 1, name: "Ada Okafor", email: "ada@example.com" },
    ship_to: { street: "12 Allen Avenue", city: "Ikeja", state: "Lagos" },
    order_date: new Date("2026-11-01"),
    status: "DELIVERED",
    items: [
      { sku: "PH-001", name: "Infinix Hot 40", category: "Electronics", quantity: 1, unit_price: 185000 },
      { sku: "SH-002", name: "Ankara Shirt",   category: "Fashion",     quantity: 2, unit_price: 8500 }
    ],
    payment: { method: "CARD", status: "SUCCESS", amount: 202000 },
    delivery: { courier: "SwiftRiders", status: "DELIVERED" } },
  { order_no: 1002,
    customer: { customer_id: 2, name: "Tunde Bello", email: "tunde@example.com" },
    ship_to: { street: "5 Aminu Kano Cres", city: "Wuse", state: "Abuja" },
    order_date: new Date("2026-11-05"),
    status: "SHIPPED",
    items: [ { sku: "GR-001", name: "Rice 50kg", category: "Groceries", quantity: 2, unit_price: 78000 } ],
    payment: { method: "TRANSFER", status: "SUCCESS", amount: 156000 },
    delivery: { courier: "GIGLogistics", status: "DISPATCHED" } },
  { order_no: 1003,
    customer: { customer_id: 1, name: "Ada Okafor", email: "ada@example.com" },
    ship_to: { street: "12 Allen Avenue", city: "Ikeja", state: "Lagos" },
    order_date: new Date("2026-11-08"),
    status: "PAID",
    items: [ { sku: "LP-001", name: "HP 15 Laptop", category: "Electronics", quantity: 1, unit_price: 520000 } ],
    payment: { method: "CARD", status: "SUCCESS", amount: 520000 } }
]);
print("Orders inserted: " + shop.orders.countDocuments());

// ---------------------------------------------------------------------
// 3. QUERIES (CRUD)
// ---------------------------------------------------------------------
print("\n--- Q1: phones/laptops with at least 8 GB RAM (nested field) ---");
printjson(shop.products.find({ "specs.ram_gb": { $gte: 8 } }, { _id: 0, name: 1, "specs.ram_gb": 1 }).toArray());

print("\n--- Q2: fashion items available in size 42 (array field) ---");
printjson(shop.products.find({ category: "Fashion", "attributes.sizes": 42 }, { _id: 0, name: 1 }).toArray());

print("\n--- Q3: all orders by Ada (customer embedded in the order) ---");
printjson(shop.orders.find({ "customer.email": "ada@example.com" }, { _id: 0, order_no: 1, status: 1, "payment.amount": 1 }).toArray());

print("\n--- Q4: UPDATE reduce stock with $inc (atomic on a single document) ---");
printjson(shop.products.updateOne({ sku: "PH-001" }, { $inc: { stock_qty: -1 } }));
printjson(shop.products.findOne({ sku: "PH-001" }, { _id: 0, name: 1, stock_qty: 1 }));

print("\n--- Q5: ADD a field to one document only (flexible schema) ---");
shop.products.updateOne({ sku: "SH-001" }, { $set: { "attributes.on_sale": true } });
printjson(shop.products.findOne({ sku: "SH-001" }, { _id: 0, name: 1, attributes: 1 }));

// ---------------------------------------------------------------------
// 4. AGGREGATION: revenue per category (like GROUP BY + JOIN in SQL)
// ---------------------------------------------------------------------
print("\n--- AGG: revenue and units per category ---");
printjson(shop.orders.aggregate([
  { $unwind: "$items" },
  { $group: { _id: "$items.category",
              revenue: { $sum: { $multiply: ["$items.quantity", "$items.unit_price"] } },
              units: { $sum: "$items.quantity" } } },
  { $sort: { revenue: -1 } }
]).toArray());

// ---------------------------------------------------------------------
// 5. INDEXING: bulk-load 20,000 orders, then compare with and without index
// ---------------------------------------------------------------------
const bulk = [];
for (let i = 1; i <= 20000; i++) {
  const cid = 1 + (i % 5000);
  bulk.push({
    order_no: 2000 + i,
    customer: { customer_id: cid, name: "Customer " + cid, email: "customer" + cid + "@example.com" },
    order_date: new Date(Date.now() - (i % 365) * 86400000),
    status: ["PAID", "SHIPPED", "DELIVERED"][i % 3],
    items: [ { sku: "PH-002", name: "Tecno Spark 20", category: "Electronics", quantity: 1, unit_price: 140000 } ],
    payment: { method: "CARD", status: "SUCCESS", amount: 140000 }
  });
}
shop.orders.insertMany(bulk);
print("\nOrders now: " + shop.orders.countDocuments());

function summarise(label, cursorExplain) {
  const e = cursorExplain;
  print(label + ": docsExamined=" + e.executionStats.totalDocsExamined +
        ", returned=" + e.executionStats.nReturned +
        ", ms=" + e.executionStats.executionTimeMillis +
        ", plan=" + JSON.stringify(e.queryPlanner.winningPlan).substring(0, 160));
}

print("\n--- INDEX TEST: find orders by customer email ---");
const q = { "customer.email": "customer77@example.com" };
summarise("BEFORE index", shop.orders.find(q).explain("executionStats"));

shop.orders.createIndex({ "customer.email": 1 });
shop.products.createIndex({ sku: 1 }, { unique: true });
shop.orders.createIndex({ order_no: 1 }, { unique: true });

summarise("AFTER  index", shop.orders.find(q).explain("executionStats"));
print("\nIndexes on orders:");
printjson(shop.orders.getIndexes().map(function (ix) { return ix.name; }));
