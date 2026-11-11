# Portfolio 1: Database Design and Modelling

**Case study:** NaijaMart (simulated online retail platform). See the root README.

## Contents

| File | What it is |
|---|---|
| `er-diagram.md` | ER diagram (Mermaid) with relationship explanations |
| `schema.sql` | Relational schema: tables, keys, constraints, a view, and small sample data |
| `normalisation.md` | Walk-through from unnormalised data to 3NF, plus design decisions |
| `screenshots/` | Evidence that the schema runs (see checklist below) |

## How I implemented and tested it

1. Installed PostgreSQL locally on Windows.
2. Created the database: `CREATE DATABASE naijamart;`
3. Ran the schema: `psql -U postgres -d naijamart -f schema.sql`
4. Verified the tables with `\dt` and the structure with `\d products`.
5. Tested constraints by deliberately breaking them (see `tests.sql`) and confirming PostgreSQL rejects the bad data.

## Screenshot checklist (save into `screenshots/`)

- [ ] `\dt` showing all 8 tables
- [ ] `\d orders` and `\d order_items` showing keys and constraints
- [ ] `SELECT * FROM order_totals;` returning the sample order
- [ ] The constraint-violation errors from `tests.sql`
- [ ] The ER diagram rendered on GitHub

## Reflection notes (fill in with your own words as you go)

- Design choice I am most confident about:
- Something that was difficult:
- Something I would do differently:
