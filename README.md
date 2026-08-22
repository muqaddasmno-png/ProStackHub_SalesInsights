# SalesInsights — Sales Tracking System

**ProStackHub SQL & DBMS Internship — Task 3**

A retail sales database (Customers, Products, Orders, OrderItems, Regions) with 9
business-question queries covering revenue ranking, growth trends, customer behavior,
and category analysis — using both correlated and non-correlated subqueries.

## Repo structure

```
SalesInsights/
├── sql/
│   ├── 01_schema.sql        -- CREATE TABLE statements (MySQL 8.0+)
│   ├── 02_seed_data.sql     -- 4 regions, 60 customers, 30 products, 420 orders, 1050 line items
│   └── 03_queries.sql       -- 9 business-question queries
├── docs/
│   └── NOTES.md             -- Design choices + subquery/GROUP BY inventory
├── screenshots/              -- add your query result screenshots here
└── README.md
```

## How to run

```bash
mysql -u root -p < sql/01_schema.sql
mysql -u root -p < sql/02_seed_data.sql
mysql -u root -p < sql/03_queries.sql
```

Or run each file in order (schema → seed data → queries) in MySQL Workbench / your
client of choice.

## What this demonstrates

- **8+ real business questions** answered in SQL, not just `SELECT *`:
  top products by revenue per region, month-over-month growth, customers inactive
  90+ days, above-average spenders, never-ordered products, category revenue share,
  regional AOV, top lifetime-value customers, and category price outliers.
- **Both subquery types used**: correlated (Q4 inner, Q5, Q9) and non-correlated
  (Q3, Q4 outer, Q6) — see `docs/NOTES.md` §3 for the full inventory.
- **GROUP BY / HAVING used correctly** — every `HAVING` filters on an aggregate,
  never a raw row (see `docs/NOTES.md` §4).
- **Realistic seed scale**: 60 customers, 30 products, 420 orders, 1,050 line items
  across 4 regions and ~1.5 years of order history.


