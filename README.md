# E-commerce Database Analytics (Capstone Project, Problem Statement 3)

**Student:** Jayesh Shrivastava (Roll No. 2501420043), B.Tech Data Science, Semester III, Section A
**University:** K.R Mangalam University
**Database:** MySQL 8.0 (InnoDB), SQL only

This project is a database for an e-commerce marketplace (sellers, products, customers, orders and reviews) with SQL queries for sales, customer satisfaction and customer behaviour. I also tested how indexes and views change the speed of the queries.

## What is covered

| Requirement | Script |
|---|---|
| Schema for product listings, seller information and customer reviews (7 tables, PK/FK, CHECK, UNIQUE) | `sql/01_schema.sql` |
| Synthetic data generated with SQL (50 sellers, 5,000 customers, 2,000 products, 50,000 orders, 100,000 order lines, ~10,000 reviews) and the base view `v_sales_lines` | `sql/02_sample_data.sql` |
| Sales trends, top-selling products, customer satisfaction scores | `sql/03_sales_satisfaction.sql` |
| Cohort analysis (retention matrix, cumulative revenue, days to second order) | `sql/04_cohort_analysis.sql` |
| Composite indexes, FULLTEXT index, EXPLAIN / EXPLAIN ANALYZE, low-selectivity example | `sql/05_indexing.sql` |
| Seller performance view, customer lifetime value view, summary table + procedure + event | `sql/06_views_summary.sql` |
| Window functions: RANK, LAG, 3-month moving average, MIN OVER, NTILE(4) | `sql/07_window_functions.sql` |

## How to run

1. Install MySQL 8.0 (window functions and `EXPLAIN ANALYZE` need 8.0.18 or newer).
2. Run the scripts in order, for example in MySQL Workbench or with the command line:

```bash
mysql -u root -p < sql/01_schema.sql
mysql -u root -p < sql/02_sample_data.sql
mysql -u root -p < sql/03_sales_satisfaction.sql
# ... and so on up to 07_window_functions.sql
```

The data is made with a deterministic function `rnd()`, so every run gives the same rows. The event scheduler is switched on in script 06 (`SET GLOBAL event_scheduler = ON` needs the right privileges).

## Folders

- `sql/` - all SQL scripts
- `docs/` - the full project report (Word file), the ER diagram and the Workbench screenshots

## Some results (from my scripted run, database `shop`)

| Query | Without optimisation | With optimisation | Speed-up |
|---|---|---|---|
| Orders of one customer in a date range (composite index) | 8.94 ms | 0.20 ms | 44x |
| Products in a category and price range (composite index) | 0.92 ms | 0.32 ms | 2.8x |
| Keyword search 'wireless' (LIKE vs FULLTEXT) | 2.54 ms | 1.71 ms | 1.5x |
| Top 10 sellers (view vs summary table) | 289.1 ms | 0.31 ms | 943x |

An index on the low-selectivity `orders.status` column made the 'delivered' query about twice as slow as a table scan, so I dropped it.

## Notes

- The data is synthetic, so the business numbers are only for practice.
- The screenshots in `docs/screenshots/` were taken in MySQL Workbench on a smaller copy of the project (database `ecommerce_db`, 20,000 orders) with a few different object names. The report explains this in Section 7.
