# Portfolio 3: Transactions and Concurrency

**Case study:** MiniPlace online store. **Database:** PostgreSQL.

## Files

| File | What it shows |
|---|---|
| `01_commit_and_rollback.sql` | A successful order (COMMIT), a failed order (ROLLBACK), and a SAVEPOINT |
| `02_setup_last_item.sql` | Resets the scenario: one phone with `stock_qty = 1` |
| `03_lost_update_session.sql` | THE PROBLEM: two buyers both get the last phone |
| `04_fixed_for_update_session.sql` | THE FIX: `SELECT ... FOR UPDATE` row locking |
| `screenshots/` | Evidence for each step |

## Part A: ACID in action (`01_commit_and_rollback.sql`)

Placing an order is several steps that must succeed or fail **together**: create the order, add the items, reduce stock, record the payment. Wrapping them in `BEGIN ... COMMIT` makes them one **atomic** unit.

| Step | What I did | Result I saw |
|---|---|---|
| Successful order | Bought 2 units of Demo Gadget inside one transaction and committed | Stock went from 5 to 3 and the order was saved |
| Failed order | Tried to buy 10 units when 3 remained | The `CHECK (stock_qty >= 0)` constraint rejected the stock update (it would have become -7), and `ROLLBACK` removed the order row and order item created earlier in the same transaction. The order count stayed at 30001 and stock stayed at 3 |
| Savepoint | Reduced stock by 1, then tried a change that fails, and rolled back only to the savepoint | The first change was kept and the failed one undone, so stock ended at 2 |

| ACID property | Where it appears |
|---|---|
| Atomicity | The failed order leaves no partial data |
| Consistency | The CHECK constraint stops negative stock |
| Isolation | Parts B and C below |
| Durability | Committed data survives, because PostgreSQL writes it to its write-ahead log before COMMIT returns |

## Part B: The concurrency problem (`03_lost_update_session.sql`)

I opened two psql windows (A and B) connected to the same database and reset the stock with `02_setup_last_item.sql` so that **Last Phone** had `stock_qty = 1`. I ran the script in A and, within 10 seconds, in B. Each script reads the stock, pauses for 10 seconds to simulate the application thinking, and then writes back a value computed from what it read.

**Result:** both sessions printed `I saw stock = 1` and `I sold the phone.` The final result showed stock 0 and **2 phones sold**, although only 1 existed.

This is a **lost update / overselling** anomaly. Both transactions read the same old value and wrote back a value computed from it, so the second write silently replaced the first, and nothing stopped both orders from being created.

## Part C: The fix (`04_fixed_for_update_session.sql`)

I reset the stock to 1 and ran the fixed script in window A and then in window B.

**Result:** window A read the stock, sold the phone and committed. Window B's first query had to wait. When it finally ran, it saw `stock = 0` and printed `Out of stock, not selling.` Only **1 phone** was sold.

**Why it works:** `SELECT ... FOR UPDATE` takes a row lock when the row is read. The second transaction cannot read-for-update the same row until the first one finishes, so the check and the update happen one after another instead of overlapping.

### Other ways to prevent it

| Approach | Idea | Trade-off |
|---|---|---|
| `FOR UPDATE` (used here) | Lock first (pessimistic) | Safe, but others wait |
| Atomic update: `UPDATE products SET stock_qty = stock_qty - 1 WHERE name = ... AND stock_qty > 0` | Let the database do check and write in one statement | Simple and fast, but only works for simple checks |
| `SERIALIZABLE` isolation | Database detects conflicts and aborts one transaction | The application must retry failed transactions |
| Optimistic locking (version column) | Detect a change at write time | Needs a retry on conflict |

## Reflection notes

**Why does the commit-and-rollback demo prove atomicity?**

The failed order created an order row and an order item before the stock update broke the CHECK constraint. After the rollback, the order count was the same as before and the stock was unchanged, so none of the earlier steps survived. All the steps in the transaction either happen together or not at all.

**Why did both windows read stock = 1 in Part B?**

A plain SELECT takes no lock, so both sessions read the row before either had committed a change. Each then wrote back `stock - 1` based on its own stale reading, so neither knew about the other.

**What did the lock change in Part C, and what is the cost of locking?**

The lock made window B wait until window A had committed, so B read the updated stock of 0 and refused to sell. The cost is that other buyers of the same product have to wait, which can slow a busy shop, and long transactions holding locks can block other work.

**Which prevention method would I choose for a busy real shop, and why?**

For simple stock deduction, I would use a single atomic `UPDATE ... SET stock_qty = stock_qty - 1 WHERE stock_qty > 0`, because it needs no explicit lock and keeps the wait very short. I would use `FOR UPDATE` when several steps depend on what is read first.