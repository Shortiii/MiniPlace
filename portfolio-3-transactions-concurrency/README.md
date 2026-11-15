# Portfolio 3: Transactions and Concurrency

**Case study:** NaijaMart / MiniPlace online store. **Database:** PostgreSQL.

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

- **Success:** stock went from 5 to 3 and the order was saved.
- **Failure:** buying 10 units when 3 remain breaks `CHECK (stock_qty >= 0)`. PostgreSQL aborts the transaction, and `ROLLBACK` removes the order row and order item that were created earlier in the same transaction. The order count and stock are unchanged.
- **Savepoint:** undoes only part of a transaction while keeping earlier work.

| ACID property | Where it appears |
|---|---|
| Atomicity | The failed order leaves no partial data |
| Consistency | The CHECK constraint stops negative stock |
| Isolation | Parts B and C below |
| Durability | Committed data survives (it is written to the WAL log before COMMIT returns) |

## Part B: The concurrency problem (`03_lost_update_session.sql`)

1. Open **two** SQL Shell (psql) windows, A and B, and connect both with `\c naijamart`.
2. In window A: `\i 'C:/path/to/02_setup_last_item.sql'` (stock = 1).
3. In A: `\i 'C:/path/to/03_lost_update_session.sql'`
4. Within 10 seconds, in B: `\i 'C:/path/to/03_lost_update_session.sql'`
5. Wait for both to finish. Screenshot both windows.

**Expected result:** both sessions say "I saw stock = 1" and "I sold the phone", and the final result shows 2 phones sold although only 1 existed. This is a **lost update / overselling** anomaly. Both transactions read the same old value and wrote back a value computed from it, so the second write silently replaced the first.

## Part C: The fix (`04_fixed_for_update_session.sql`)

1. Run `02_setup_last_item.sql` again to reset.
2. Run `04_fixed_for_update_session.sql` in window A, then quickly in window B.

**Expected result:** window B waits (its first SELECT hangs) until A commits. B then reads stock = 0 and prints "Out of stock, not selling". Only 1 phone is sold.

**Why it works:** `SELECT ... FOR UPDATE` takes a row lock when the row is read. The second transaction cannot read-for-update the same row until the first one finishes, so the check and the update happen one after another instead of overlapping.

### Other ways to prevent it (discuss in your documentation)

| Approach | Idea | Trade-off |
|---|---|---|
| `FOR UPDATE` (used here) | Lock first (pessimistic) | Safe, but others wait |
| Atomic update: `UPDATE products SET stock_qty = stock_qty - 1 WHERE name = ... AND stock_qty > 0` | Let the database do check and write in one statement | Simple and fast, but only works for simple checks |
| `SERIALIZABLE` isolation | Database detects conflicts and aborts one transaction | The application must retry failed transactions |
| Optimistic locking (version column) | Detect a change at write time | Needs a retry on conflict |

## Part D (optional): Isolation levels

PostgreSQL's default is READ COMMITTED. To see what that means, open windows A and B:

```
-- Window A
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT stock_qty FROM products WHERE name = 'Last Phone';   -- note the value

-- Window B (auto-commits immediately)
UPDATE products SET stock_qty = 50 WHERE name = 'Last Phone';

-- Window A
SELECT stock_qty FROM products WHERE name = 'Last Phone';   -- now shows 50: a NON-REPEATABLE READ
COMMIT;
```

Repeat with `BEGIN ISOLATION LEVEL REPEATABLE READ;` in A. The second SELECT in A still shows the old value, because A works from a snapshot taken at its first query.

## Reflection notes (write in your own words)

- Why does the commit-and-rollback demo prove atomicity?
- Why did both windows read stock = 1 in Part B?
- What did the lock change in Part C, and what is the cost of locking?
- Which prevention method would I choose for a busy real shop, and why?
