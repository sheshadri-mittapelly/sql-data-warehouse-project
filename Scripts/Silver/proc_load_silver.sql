/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/
CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE 
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_batch_start_time TIMESTAMP;
    V_batch_end_time TIMESTAMP;

BEGIN
    v_batch_start_time := NOW();
    RAISE NOTICE '==========================================================';
    RAISE NOTICE 'LOADING SILVER LAYER';
    RAISE NOTICE '==========================================================';

    RAISE NOTICE '==========================================================';
    RAISE NOTICE 'LOADING CRM TABLES';
    RAISE NOTICE '==========================================================';
-- Loading  silver.crm_cust_info
    v_start_time := NOW();
    RAISE NOTICE '>> Truncating Table: silver.crm_cust_info';
    TRUNCATE TABLE silver.crm_cust_info;
    RAISE NOTICE '>> Inserting Data Into: silver.crm_cust_info';
    INSERT INTO silver.crm_cust_info(
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date
    )
    SELECT 
    cst_id,cst_key,
    TRIM(cst_firstname) as cst_firstname,
    TRIM(cst_lastname) as cst_lastname,
    CASE 
        WHEN TRIM(cst_marital_status)= 'M' THEN 'Married'
        WHEN TRIM(cst_marital_status)= 'S' THEN 'Single'
        ELSE 'N/A'
    END AS cst_marital_status,
    CASE 
        WHEN TRIM(cst_gndr)= 'M' THEN 'Male'
        WHEN TRIM(cst_gndr)= 'S' THEN 'Female'
        ELSE 'N/A'
    END AS cst_gndr,
    cst_create_date
    FROM (SELECT*,ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC)AS flage_last
        FROM bronze.crm_cust_info
        WHERE cst_id IS NOT NULL
    )t
    WHERE flag_last = 1;

    v_end_time := NOW();
    RAISE NOTICE '>> Load Duration: % seconds',
    EXTRACT(EPOCH FROM(v_end_time - v_start_time))::INT;
    RAISE NOTICE '>> --------------------';

    -- Loading crm_prd_info
    v_start_time := NOW();
    RAISE NOTICE '>> Truncating Table: silver.crm_prd_info';
    TRUNCATE TABLE silver.crm_prd_info;
    RAISE NOTICE '>> Inserting Data Info: silver.crm_prd_info';

    INSERT INTO silver.crm_prd_info (
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )

    SELECT prd_id,
        REPLACE(SUBSTRING(prd_key, 1,5),'-','_') AS cat_id,
        SUBSTRING(prd_key,7,LENGTH(prd_key)) AS prd_key,
        prd_nm,
        COALESCE(prd_cost,0) AS prd_cost,
        CASE
            WHEN TRIM(prd_line) = 'M' THEN 'Mountain'
            WHEN TRIM(prd_line) = 'R' THEN 'Road'
            WHEN TRIM(prd_line) = 'S' THEN 'Other Sales'
            WHEN TRIM(prd_line) = 'T' THEN 'Touring'
            ELSE 'N/A'
        END AS prd_line,
        CAST(prd_start_dt AS DATE) AS prd_start_dt,
        CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)- INTERVAL '1 day' AS DATE) AS prd_end_dt
    FROM bronze.crm_prd_info;
    v_end_time := NOW();
    RAISE NOTICE '>> Load Duration: % seconds',
    EXTRACT(EPOCH FROM (v_end_time - v_start_time))::INT;
    RAISE NOTICE '>>---------------------';
    

    -- Loading crm_sales_details
    v_start_time := NOW();
    RAISE NOTICE '>> Truncating Table: silver.crm_sales_details';
    TRUNCATE TABLE silver.crm_sales_details;
    RAISE NOTICE '>> Inserting Data Info: silver.crm_sales_details';
    INSERT INTO silver.crm_sales_details(
        sls_ord_num,
        sls_pro_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantit,
        sls_price
    )

    SELECT sls_ord_num,
        sls_pro_key,
        sls_cust_id,
        CASE 
            WHEN sls_order_dt = 0 or LENGTH(sls_order_dt :: TEXT) != 8 THEN NULL
            ELSE TO_DATE(sls_order_dt :: TEXT, 'YYYYMMDD')
        END AS sls_order_dt,
        CASE 
            WHEN sls_ship_dt = 0 or LENGTH(sls_ship_dt :: TEXT) != 8 THEN NULL
            ELSE TO_DATE(sls_ship_dt :: TEXT , 'YYYYMMDD')
        END AS sls_ship_dt,
        CASE 
            WHEN sls_due_dt = 0 or LENGTH(sls_due_dt :: TEXT) != 8 THEN NULL
            ELSE TO_DATE(sls_due_dt :: TEXT,'YYYYMMDD')
        END AS sls_due_dt,
        CASE 
            WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantit * ABS(sls_price)
            THEN sls_quantit * ABS(sls_price)
            ELSE sls_sales
        END AS sls_sales,
        sls_quantit,
        CASE 
            WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantit,0)
            ELSE sls_price
        END
    FROM bronze.crm_sales_details;
    v_end_time := NOW();
    RAISE NOTICE '>> Load Duration: % seconds',
    EXTRACT(EPOCH FROM (v_end_time - v_start_time))::INT;
    RAISE NOTICE '>>---------------------';

    -- Loading erp_cust_az12
    v_start_time := NOW();
    RAISE NOTICE '>> Truncating Table: silver.erp_cust_az12';
    TRUNCATE TABLE silver.erp_cust_az12;
    RAISE NOTICE '>> Inserting Data Info: silver.erp_cust_az12';
    INSERT INTO silver.erp_cust_az12(
        cid,
        bdate,
        gen
    )

    SELECT 
        CASE 
            WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LENGTH(cid))
            ELSE cid
        END AS cid,
        CASE 
            WHEN bdate > CURRENT_DATE THEN NULL
            ELSE bdate
        END AS bdate,
        TRIM(gen)
    FROM bronze.erp_cust_az12;
    v_end_time := NOW();
    RAISE NOTICE '>> Load Duration: % seconds',
    EXTRACT(EPOCH FROM (v_end_time - v_start_time))::INT;
    RAISE NOTICE '>>---------------------';
        
    -- Loading erp_loc_a101
    v_start_time := NOW();
    RAISE NOTICE '>> Truncating Table: silver.erp_loc_a101';
    TRUNCATE TABLE silver.erp_loc_a101;
    RAISE NOTICE '>> Inserting Data Info: silver.erp_loc_a101';
    INSERT INTO silver.erp_loc_a101(
        cid,
        cntry
    )
    SELECT 
        REPLACE(cid,'-','') AS cid,
        CASE
            WHEN TRIM(cntry) = 'DE' THEN 'Germany'
            WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
            WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
            ELSE TRIM(cntry)
        END AS cntry
    FROM bronze.erp_loc_a101;
    v_end_time := NOW();
    RAISE NOTICE '>> Load Duration: % seconds',
    EXTRACT(EPOCH FROM (v_end_time - v_start_time))::INT;
    RAISE NOTICE '>>---------------------';

-- Loading silver.erp_px_cat_g1v2
    v_start_time := NOW();
    RAISE NOTICE '>> Truncating Table: silver.erp_px_cat_g1v2';
    TRUNCATE TABLE silver.erp_px_cat_g1v2;
    RAISE NOTICE '>> Inserting Data Info: silver.erp_px_cat_g1v2';

    INSERT INTO silver.erp_px_cat_g1v2(
        ids,
        cat,
        subcat,
        maintenance
    )
    SELECT ids,
        cat,
        subcat,
        maintenance
    FROM bronze.erp_px_cat_g1v2;
    v_end_time := NOW();
    RAISE NOTICE '>> Load Duration: % seconds',
    EXTRACT(EPOCH FROM (v_end_time - v_start_time))::INT;
    RAISE NOTICE '>>---------------------';
END;
$$;
