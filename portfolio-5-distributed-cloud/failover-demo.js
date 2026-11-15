// Writes and reads through the replica-set connection string, so the driver
// automatically follows whichever node is PRIMARY.
// Usage:
//   mongosh "mongodb://localhost:27117,localhost:27118,localhost:27119/?replicaSet=rs0" --quiet --file failover-demo.js
const shop = db.getSiblingDB("naijamart_rs");

// w: "majority" = the write is only acknowledged after most nodes (2 of 3) have it
const r = shop.orders.insertOne(
  { order_no: Date.now(), note: "written at " + new Date().toISOString(), amount: 10000 },
  { writeConcern: { w: "majority", wtimeout: 10000 } }
);
print("Write acknowledged by majority: " + r.acknowledged);
print("Total documents in naijamart_rs.orders: " + shop.orders.countDocuments());
print("Current primary: " + db.hello().primary);
