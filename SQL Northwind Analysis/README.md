# Northwind SQL business analysis

## Case study

Used SQL to answer ten sales, customer, product, employee, delivery, discount, and inventory questions from a relational sample business database. The project demonstrates multi-table joins, CTEs, aggregations, date calculations, and window functions (`LAG`, `ROW_NUMBER`, `RANK`, `DENSE_RANK`). The runnable queries are in [`queries.sql`](queries.sql); each question has an output CSV in `results/`.

### Dataset

The database is Microsoft's fictitious Northwind Traders sample, converted to SQLite by the public [jpwhite3/northwind-SQLite3 repository](https://github.com/jpwhite3/northwind-SQLite3), which includes the MIT license. The included source SQL creates the original-size sample snapshot: 830 orders, 2,155 order-detail rows, and 93 customers across July 1996-May 1998. See [Microsoft's sample database page](https://learn.microsoft.com/en-us/dotnet/framework/data/adonet/sql/linq/downloading-sample-databases) for background. The database and source script are in `data/`; retrieval details and counts are in `data/data_provenance.json`. Northwind is fictional training data, so these are query results, not real company findings.

### Selected findings

- Total net sales in the sample: **$1,265,793.04**.
- Beverages led category sales at **$267,868.18 (21.16%)**.
- The USA and Germany led ship-to-country sales at **$245,584.61 (19.40%)** and **$230,284.63 (18.19%)**.
- Federal Shipping had the highest on-time rate in this snapshot at **96.4%** (240 of 249 shipped orders).
- The inventory query identified **18 non-discontinued products at or below their reorder point**.

These observations describe the sample data only. The SQL uses a net-sales formula of `UnitPrice * Quantity * (1 - Discount)`; it does not infer costs or profit.

## Questions covered

1. Monthly sales and month-over-month change.
2. Category revenue share and rank.
3. Top three products in each category.
4. Top customers by country.
5. Employee annual sales rank.
6. Shipper on-time rate and order-to-ship time.
7. Repeat-customer reorder cadence.
8. Sales by discount band.
9. Inventory at or below reorder point.
10. Revenue share by ship-to country.

## Run

Requires Python 3.10+ (uses the built-in SQLite driver):

```powershell
python run_queries.py
```

This refreshes the ten CSV result files in `results/`.
