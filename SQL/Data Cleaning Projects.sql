-- DATA CLEANING

-- 1. Remove Duplicate Data
-- 2. Standardize the Data
-- 3. Null Values
-- 4. Remove Unnecessary Column

-- Candy Factories Data Cleaning (Remove Duplicate Data)
SELECT * 
FROM candy_factories;
 -- No Duplicate Value

-- Candy Products Data Cleaning (Remove Duplicate Data)
SELECT *
FROM candy_products;
-- No Duplicate value

-- Candy Sales Data Cleaning (Remove Duplicate Data)
SELECT *
FROM candy_sales;

WITH duplicate_CTE AS (
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY `Row ID`, `Order ID`, `Order Date`, `Ship Date`, 
`Ship Mode`, `Customer ID`, `Country/Region`, `City`, 
`State/Province`, `Postal Code`, 
`Division`, `Region`, `Product ID`, 
`Product Name`, `Sales`, `Units`, `Gross Profit`, `Cost`) AS row_num
FROM candy_sales)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;
-- No Duplicate Data

-- candy targets data cleaning (remove duplicate data)
SELECT *
FROM candy_targets;
-- No Duplicate Data

-- uszips (remove duplicate data)
SELECT *
FROM uszips;

WITH duplicate_CTE2 AS (
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY zip, lat, lng, city, 
state_id, state_name, zcta, parent_zcta, population, 
density, county_fips, county_name, county_weights, 
county_names_all, county_fips_all, 
imprecise, military, timezone) AS row_num
FROM uszips)
SELECT *
FROM duplicate_cte2
WHERE row_num > 1;
-- No Duplicate Data

-- Standardize Data

-- candy_products
CREATE TABLE candy_products_staging
SELECT *
FROM candy_products;

SELECT *
FROM candy_products_staging;

CREATE TABLE candy_sales_staging
SELECT *
FROM candy_sales;

SELECT *
FROM candy_sales_staging;

ALTER TABLE candy_sales_staging
CHANGE `Country/Region` `Country` VARCHAR(50);

ALTER TABLE candy_sales_staging
CHANGE `State/Province` `State` VARCHAR(50);

SELECT `Product ID`, `Product Name`
FROM candy_sales_staging
WHERE `Product ID` = 'CHO-SCR-58000';

SELECT `Product ID`, `Product Name`
FROM candy_sales_staging
WHERE `Product ID` = 'SUG-LAF-25000';

UPDATE candy_products_staging
SET `Product Name` = 'Laffy Taffy'
WHERE `Product ID` = 'SUG-LAF-25000';

UPDATE candy_products_staging
SET `Division` = 'Sugar'
WHERE `Product ID` = 'SUG-LAF-25000';

UPDATE candy_products_staging
SET `Factory` = 'Sugar Shack'
WHERE `Product ID` = 'SUG-LAF-25000';

UPDATE candy_products_staging
SET `Product Name` = 'Wonka Bar -Scrumdiddlyumptious'
WHERE `Product ID` = 'CHO-SCR-58000';

UPDATE candy_products_staging
SET `Division` = 'Chocolate'
WHERE `Product ID` = 'CHO-SCR-58000';

SELECT *
FROM candy_sales_staging;

SELECT DISTINCT Country
FROM candy_sales_staging;

SELECT DISTINCT State
FROM candy_sales_staging;

SELECT `Order Date`, 
str_to_date(`Order Date`, '%Y-%m-%d')
FROM candy_sales_staging;

UPDATE candy_sales_staging
SET `Order Date` = str_to_date(`Order Date`, '%Y-%m-%d');

ALTER TABLE candy_sales_staging
MODIFY COLUMN `Order Date` DATE;

SELECT `Ship Date`, 
str_to_date(`Ship Date`, '%Y-%m-%d')
FROM candy_sales_staging;

UPDATE candy_sales_staging
SET `Ship Date` = str_to_date(`Ship Date`, '%Y-%m-%d');

ALTER TABLE candy_sales_staging
MODIFY COLUMN `Ship Date` DATE;

-- DATA CLEANING DONE




