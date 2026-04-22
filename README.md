# Data Warehouse Project

A SQL data warehouse built with PostgreSQL using the **Medallion Architecture** (Bronze → Silver → Gold).

---

## What This Project Does

This project takes raw data from two source systems (CRM and ERP), cleans it, and organizes it into a final Star Schema that is ready for reporting and analysis.

---

## Architecture

```
CSV Files  →  Bronze (Raw)  →  Silver (Cleaned)  →  Gold (Reporting)
```

- **Bronze** – Loads raw CSV data as-is into the database
- **Silver** – Cleans and standardizes the Bronze data
- **Gold** – Creates final views (Star Schema) for analysis

---

## Folder Structure

```
scripts/
├── BRONZE/
│   ├── ddl_bronze.sql           # Creates Bronze tables
│   └── proc_load_bronze.sql     # Loads CSV data into Bronze
├── SILVER/
│   ├── ddl_silver.sql           # Creates Silver tables
│   └── proc_load_silver.sql     # Cleans and loads data into Silver
└── GOLD/
    └── ddl_gold.sql             # Creates Gold views (Star Schema)
```

---

## Data Sources

**CRM**
- `cust_info.csv` → Customer details (name, gender, marital status)
- `prd_info.csv` → Product information (cost, product line, dates)
- `sales_details.csv` → Sales transactions

**ERP**
- `LOC_A101.csv` → Customer country/location
- `CUST_AZ12.csv` → Customer birthdate and gender
- `PX_CAT_G1V2.csv` → Product categories

---

## Gold Layer (Final Output)

| View | Description |
|---|---|
| `gold.dim_customers` | Customer dimension with full profile |
| `gold.dim_products` | Product dimension with category info |
| `gold.fact_sales` | Sales fact table linked to customers and products |

---

## How to Run

### Requirements
- PostgreSQL 13+
- CSV source files saved locally

### Steps

**1. Update the CSV file paths** in `proc_load_bronze.sql` to match your local folder.

**2. Run the scripts in this order:**

```sql
-- Create tables
\i scripts/BRONZE/ddl_bronze.sql
\i scripts/SILVER/ddl_silver.sql
\i scripts/GOLD/ddl_gold.sql

-- Create stored procedures
\i scripts/BRONZE/proc_load_bronze.sql
\i scripts/SILVER/proc_load_silver.sql

-- Run the pipeline
CALL bronze.load_bronze();
CALL silver.load_silver();
```

**3. Query the Gold layer:**

```sql
SELECT * FROM gold.dim_customers;
SELECT * FROM gold.dim_products;
SELECT * FROM gold.fact_sales;
```

---

## Tools Used

- PostgreSQL
- SQL (DDL + Stored Procedures)
- Medallion Architecture pattern
