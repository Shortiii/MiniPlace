# Portfolio 5: Distributed and Cloud Database Systems

**Case study:** NaijaMart / MiniPlace online store. **Database:** MongoDB replica set (3 nodes on one Windows machine) plus a written sharding design.

## Files

| File | Purpose |
|---|---|
| `setup-replica-set.ps1` | Starts 3 mongod nodes (ports 27117, 27118, 27119) and initiates replica set `rs0` |
| `init-replica-set.js` | Replica set configuration (used by the script above) |
| `status.js` | Prints which node is PRIMARY and which are SECONDARY |
| `failover-demo.js` | Writes with `w: "majority"` through the replica-set connection |
| `stop-node.ps1` | Kills the node on a port (simulates a crash) |
| `start-node.ps1` | Brings a stopped node back |
| `screenshots/` | Evidence for each step |

## Step-by-step experiment (screenshot every step)

Open PowerShell in this folder. If scripts are blocked, prefix with `powershell -ExecutionPolicy Bypass -File`.

1. **Start the cluster**
   ```
   .\setup-replica-set.ps1
   ```
   Expect `"ok": 1` from `rs.initiate`. If `mongosh` is not recognised, add MongoDB Shell to your PATH or open a new terminal after installing it.

2. **See the topology**
   ```
   mongosh --port 27117 --quiet --file status.js
   ```
   Expect one PRIMARY and two SECONDARY. Note which port is the PRIMARY.

3. **Write data with majority acknowledgement**
   ```
   mongosh "mongodb://localhost:27117,localhost:27118,localhost:27119/?replicaSet=rs0" --quiet --file failover-demo.js
   ```
   Run it two or three times so there are a few documents.

4. **Kill the PRIMARY** (use the port from step 2)
   ```
   .\stop-node.ps1 -Port 27117
   ```

5. **Watch the failover** (use a port that is still running, for example 27118)
   ```
   mongosh --port 27118 --quiet --file status.js
   ```
   Within about 10-15 seconds one SECONDARY is elected the new PRIMARY, and the stopped node shows as DOWN.

6. **Keep writing during the outage**
   Run the step 3 command again. It still succeeds, because 2 of 3 nodes is still a majority.

7. **Bring the old node back**
   ```
   .\start-node.ps1 -Node 1
   ```
   Check `status.js` again: the old primary rejoins as a SECONDARY and catches up on the writes it missed.

8. **Optional extra evidence (consistency):** kill a second node as well, so only 1 of 3 remains. Run step 3 again. The write **cannot** be acknowledged with `w: "majority"` (it times out), and no node becomes primary, because there is no majority. This shows the system choosing consistency over availability.

## How replication works (explain in your own words)

- One **primary** accepts all writes and records them in the **oplog**.
- **Secondaries** copy the oplog and apply the same changes.
- If the primary stops responding, the remaining nodes hold an **election**, and a node needs a **majority of votes** (2 of 3) to become primary. This is why replica sets use an odd number of nodes.
- **Write concern** controls how many nodes must confirm a write: `w: 1` (primary only, fast but can lose data if the primary dies before copying) versus `w: "majority"` (safer, slightly slower).
- **Read preference** controls where reads go: `primary` (always fresh) versus `secondary` (spreads load but may return slightly stale data).

## Consistency and availability (CAP) for NaijaMart

During a network partition a distributed system cannot guarantee both consistency and availability.

- With `w: "majority"` and reads from the primary, MongoDB behaves as **CP**: the side of the partition that cannot reach a majority stops accepting writes (it briefly gives up availability) so that data never diverges.
- Reads from secondaries give **eventual consistency**: fast and available, but a customer might briefly see old stock numbers.

Which should NaijaMart choose?
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

Recommended: `sh.shardCollection("naijamart.orders", { customer_id: "hashed" })`.

**Trade-off:** queries that do not include the shard key (for example "all orders last week") must be sent to every shard (scatter-gather), which is slower.

**For products:** the catalogue is small and read-heavy, so it is better to replicate it (and cache it) than to shard it.

## Cloud deployment note

Managed services such as MongoDB Atlas run this same replica-set architecture for you (a free M0 cluster is a 3-node replica set) and add backups, monitoring and automatic failover. The local 3-node cluster here shows the mechanism that Atlas automates.

## Reflection notes (write in your own words)

- What happened in step 5 and how long did the election take?
- Why did writes still work in step 6 but fail in step 8?
- What are the trade-offs between `w: 1` and `w: "majority"`?
- Which parts of NaijaMart need strong consistency, and which can tolerate eventual consistency?
