# SalesInsights — Design & Query Notes

## 1. Schema shape

This task is about **writing business-logic queries**, not schema complexity, so the
schema is a deliberately plain retail shape:

| Table | Purpose |
|---|---|
| **Regions** | Lookup table for the 4 sales regions. |
| **Customers** | One row per customer, linked to a Region. |
| **Products** | Catalog of 30 products across 3 categories. |
| **Orders** | Order header (who, when). |
| **OrderItems** | Line items — many-to-many between Orders and Products, carrying Quantity and a **price snapshot** (`UnitPriceAtSale`). |

**Why a price snapshot instead of just joining to `Products.UnitPrice`:** if a product's
price changes after a sale, historical revenue queries should still reflect what the
customer actually paid at the time — not today's price. This is the same "never
overwrite history" principle as Task 2's supplier price history.

## 2. Referential integrity choices

| FK | Rule | Why |
|---|---|---|
| `Customers.RegionID → Regions` | `ON DELETE RESTRICT` | Don't silently orphan a customer's region reference. |
| `Orders.CustomerID → Customers` | `ON DELETE CASCADE` | Customer removed → their order history goes with them. |
| `OrderItems.OrderID → Orders` | `ON DELETE CASCADE` | Order deleted → its line items are meaningless without it. |
| `OrderItems.ProductID → Products` | `ON DELETE RESTRICT` | Protects sales history — a product that's been sold shouldn't be deletable out from under existing line items. |

## 3. Subquery inventory (task requirement: at least one correlated + one non-correlated)

| Query | Type | What it does |
|---|---|---|
| Q3 | **Non-correlated** | `(SELECT MAX(OrderDate) FROM Orders)` — computed once, used as a fixed reference point for "days since last order." |
| Q4 (inner) | **Correlated** | Each customer's own average order value, filtered by `o2.CustomerID = c.CustomerID` referencing the outer row. |
| Q4 (outer filter) | **Non-correlated** | The overall average order value across all customers, computed once and compared against. |
| Q5 | **Correlated** | `NOT EXISTS (... WHERE oi.ProductID = p.ProductID)` — checked per product. |
| Q6 | **Non-correlated** | Total revenue across all order items, computed once, used as the denominator for % share. |
| Q9 | **Correlated** | Each product's category average, filtered by `p2.Category = p.Category` referencing the outer row. |

## 4. GROUP BY / HAVING usage

Every `HAVING` clause in `03_queries.sql` filters on an **aggregated value**, never a raw
row — e.g. Q3 filters on `DaysSinceLastOrder >= 90` (an aggregate expression built from
`MAX(OrderDate)`), and Q8 filters on `LifetimeSpend > 0` (a `SUM(...)`). Note that Q4 was
restructured to filter with `WHERE` on a derived table rather than `HAVING` without a
`GROUP BY` — some MySQL configurations tolerate a scalar subquery in `HAVING` without a
preceding `GROUP BY`, but it isn't standard SQL, and wrapping it in a subquery + `WHERE`
is the portable, correct way to do the same filter.

## 5. Verification performed

The schema and seed data were validated for structural correctness and all 9 queries were
tested against an equivalent SQLite build (translating MySQL-specific functions like
`DATE_FORMAT`/`DATEDIFF` to their SQLite equivalents for the test only — the actual
`.sql` files use real MySQL syntax). Confirmed:
- Zero foreign key violations on load.
- All 9 queries return correct, sensible results.
- Q5 (never-ordered products) legitimately returns 0 rows — with 1,050 seeded line items
  spread across only 30 products, every product ends up ordered at least once. That's a
  real finding from the data, not a bug — worth mentioning in the walkthrough.
