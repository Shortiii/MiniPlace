# Portfolio 5: Distributed and Cloud Database Systems

**Case study:** MiniPlace online store. **Database:** MongoDB replica set (3 nodes on one Windows machine) plus a written sharding design.

## Files

| File | Purpose |
|---|---|
| `setup-replica-set.ps1` | Starts 3 mongod nodes (ports 27117, 27118, 27119) and initiates replica set `rs0` |
| `init-replica-set.js` | Replica set configuration (used by the script above) |
| `status.js` | Prints which node is PRIMARY and which are SECONDARY |
| `failover-demo.js` | Writes with `w: "majority"` through the replica-set connection |
| `stop-node.ps1` | Stops the node on a port (simulates a crash) |
| `start-node.ps1` | Brings a stopped node back |
| `screenshots/` | Evidence for each step |

## What I did and what I saw

| Step | Command | Result |
|---|---|---|
| 1. Start the cluster | `setup-replica-set.ps1` | Three nodes started and `rs.initiate` returned `ok: 1` |
| 2. Check the topology | `status.js` | 27117 was PRIMARY, 27118 and 27119 were SECONDARY |
| 3. Write with majority | `failover-demo.js` (three times) | Each write was acknowledged by a majority; the document count went 1, 2, 3 and the primary was 27117 |
| 4. Kill the primary | `stop-node.ps1 -Port 27117` | The primary process was stopped |
| 5. Check the topology | `status.js` on port 27118 | 27117 showed as DOWN and **27119 had been elected the new PRIMARY** within seconds |
| 6. Write during the outage | `failover-demo.js` | Still acknowledged by majority (document count 4), and the primary shown was 27119 |
| 7. Bring the old primary back | `start-node.ps1 -Node 1` | 27117 rejoined as a **SECONDARY**; 27119 stayed PRIMARY |
| 8. Remove the majority | Stopped 27118 and 27119, leaving only 27117, then ran `failover-demo.js` | The write **failed** with `MongoServerSelectionError` because no primary was available |
| 9. Restore | `start-node.ps1 -Node 2` and `-Node 3` | The cluster returned to one PRIMARY and two SECONDARY |

**Limitation:** all three nodes run on one computer, so this demonstrates the replication and election mechanism, not protection against a real hardware or network failure.

## How replication works

- One **primary** accepts all writes and records them in the **oplog**.
- **Secondaries** copy the oplog and apply the same changes.
- If the primary stops responding, the remaining nodes hold an **election**, and a node needs a **majority of votes** (2 of 3) to become primary. This is why replica sets use an odd number of nodes.
- **Write concern** controls how many nodes must confirm a write: `w: 1` (primary only, fast but can lose data if the primary dies before copying) versus `w: "majority"` (safer, slightly slower).
- **Read preference** controls where reads go: `primary` (always fresh) versus `secondary` (spreads load but may return slightly stale data).

## Consistency and availability (CAP) for MiniPlace

During a failure a distributed system cannot guarantee both consistency and availability.

- With `w: "majority"` and reads from the primary, MongoDB behaves as **CP**: when there is no majority (step 8), it refuses writes so that data never diverges, giving up availability.
- Reads from secondaries give **eventual consistency**: fast and available, but a customer might briefly see old stock numbers.

Which should MiniPlace choose?
- **Orders, payments and stock deduction:** consistency matters most. Use `majority` writes and primary reads (and in practice keep the SQL database as the source of truth for money).
- **Product browsing and search:** availability and speed matter more. Reading from secondaries is acceptable, even if a description is a few seconds stale.

## Sharding design (written design, not implemented)

Replication copies the **same** data to several nodes (availability). Sharding **splits** the data across nodes (scale). Large stores need both.

**Architecture:** applications connect to `mongos` routers, which use the **config servers** (cluster metadata) to send each query to the right **shard**. Each shard is itself a replica set.

**Choosing a shard key for `orders`:**

| Candidate key | Verdict | Reason |
|---|---|---|
| `order_date` | Bad | Values only increase, so every new order lands on the same shard (a hot spot) |
| `status` | Bad | Only a few distinct values, so data cannot be split evenly (low cardinality) |
| `customer_id` (hashed) | Good | Many distinct values, spread evenly, and one customer's orders stay together |
| `{ customer_id: 1, order_date: 1 }` (compound) | Good | Targeted queries per customer and still well distributed |

Recommended: `sh.shardCollection("miniplace.orders", { customer_id: "hashed" })`.

**Trade-off:** queries that do not include the shard key (for example "all orders last week") must be sent to every shard (scatter-gather), which is slower.

**For products:** the catalogue is small and read-heavy, so it is better to replicate it (and cache it) than to shard it.

## Cloud deployment note

Managed services such as MongoDB Atlas run this same replica-set architecture for you (a free M0 cluster is a 3-node replica set) and add backups, monitoring and automatic failover. The local 3-node cluster here shows the mechanism that Atlas automates.

## Reflection notes

**What happened when I stopped the primary, and how long did the election take?**

When I stopped the primary on port 27117, the two remaining nodes elected 27119 as the new primary. By the time I checked the status a few seconds later, the election had already finished, and 27117 showed as DOWN.

**Why did writes still work after one node was stopped, but fail when two were stopped?**

With one node down, 2 of 3 nodes were still alive, which is a majority, so a primary could be elected and majority writes could be acknowledged. With two nodes down, only 1 of 3 was left. That is not a majority, so no primary could be elected and the write failed instead of being accepted without a majority.

**What are the trade-offs between `w: 1` and `w: "majority"`?**

`w: 1` is faster because only the primary has to confirm, but if the primary fails before copying the write, the data can be lost. `w: "majority"` is slower, since it waits for most nodes, but it guarantees the write survives a failover.

**Which parts of MiniPlace need strong consistency, and which can tolerate eventual consistency?**

Orders, payments and stock levels need strong consistency, because wrong or lost data means money or overselling problems. Product browsing and descriptions can tolerate eventual consistency, because a slightly stale page does little harm.