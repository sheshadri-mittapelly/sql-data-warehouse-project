/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================

--SELECT * FROM silver.crm_cust_info;
DROP VIEW IF EXISTS gold.dim_customers;

CREATE VIEW gold.dm_customers AS
SELECT 
    row_number() over(ORDER BY ci.cst_id)    AS customer_key,
    ci.cst_id                                AS customer_id,
    ci.cst_key                               AS customer_number,
    ci.cst_firstname                         As Firstname,
    ci.cst_lastname                          AS Lastname,
    la.cntry                                 AS country,
    ci.cst_marital_status                    AS Marital_status,
    CASE 
        WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr
        ELSE  COALESCE(ca.gen, 'N/A')
    END                                       AS gender,
    ca.bdate                                  AS Birthdate,
    ci.cst_create_date                        AS Create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key = la.cid;

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
DROP VIEW IF EXISTS gold.dim_prodcuts;

CREATE VIEW gold.dim_products AS
SELECT 
    pn.prd_id       AS product_id,
    pn.prd_key      AS prdocut_number,
    pn.prd_nm       AS product_number,
    pn.cat_id       AS category_id,
    pc.cat          AS category,
    pc.subcat       AS subcategory
    pc.maintenance  AS maintenance,
    pn.prd_cost     AS cost,
    pn.prd_line     AS product_line,
    pn.prd_start_dt AS start_dates
FROM silver.crm_prd_info pn
LEFT JOIN  silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.ids
    WHERE pn.prd_end_dt IS NULL; -- Filter out all historical data

-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================

SELECT * FROM silver.crm



