-- EDA Project

-- 1. What is the most profitable products?

SELECT `Product Name`, SUM(`Gross Profit`) AS `Gross Profit`, AVG(`Gross Profit`/`Units`) AS `Gross Profit Per Unit`
FROM candy_sales_staging
GROUP BY `Product Name`
ORDER BY `Gross Profit` DESC;

-- 2. Sales Analysis by Region

SELECT Region, SUM(Units) AS Units
FROM candy_sales_staging
GROUP BY Region
ORDER BY Units DESC;

-- 3. What is the best selling products
SELECT `Product Name`, SUM(Units) AS Units
FROM candy_sales_staging
GROUP BY `Product Name`
ORDER BY Units DESC;

-- 4. Time Series Analysis

SELECT EXTRACT(YEAR FROM `Order Date`) AS order_year, 
       SUM(`Sales`) AS total_sales
FROM candy_sales_staging
GROUP BY order_year
ORDER BY order_year;

-- 5. What are the most efficient factory to customer shipping routes?

-- Step 1: Create a temporary table with calculated distance and efficiency status
CREATE TEMPORARY TABLE temp_distance_calculation AS
SELECT 
    p.`Product ID`, 
    p.`Product Name`, 
    p.`Factory`, 
    s.`Customer ID`, 
    s.`Country`, 
    s.`State`, 
    s.`Postal Code`, 
    u.`lat`, 
    u.`lng`, 
    f.`Latitude`, 
    f.`Longitude`,
    2 * 6371 * ASIN(
        SQRT(
            POWER(SIN(RADIANS(f.`Latitude` - u.`lat`) / 2), 2) +
            COS(RADIANS(u.`lat`)) * COS(RADIANS(f.`Latitude`)) *
            POWER(SIN(RADIANS(f.`Longitude` - u.`lng`) / 2), 2)
		)
	) AS distance_km,
    CASE
        WHEN 2 * 6371 * ASIN(
            SQRT(
                POWER(SIN(RADIANS(f.`Latitude` - u.`lat`) / 2), 2) +
                COS(RADIANS(u.`lat`)) * COS(RADIANS(f.`Latitude`)) *
                POWER(SIN(RADIANS(f.`Longitude` - u.`lng`) / 2), 2)
            )
        ) <= 2000 THEN 'Efficient'
        ELSE 'Not Efficient'
    END AS efficiency_status
FROM 
    candy_products p
JOIN 
    candy_sales_staging s ON p.`Product ID` = s.`Product ID`
JOIN 
    uszips u ON s.`Postal Code` = u.`zip`
JOIN 
    candy_factories f ON p.`Factory` = f.`Factory`;

-- Step 2: Query the temporary table with a WHERE clause for efficiency status
SELECT *
FROM temp_distance_calculation
WHERE efficiency_status = 'Efficient';

-- What is the most least efficient factory to customer shipping route?
SELECT *
FROM temp_distance_calculation
WHERE efficiency_status = 'Not Efficient';

-- Which Product Lines Should Moved to a Different Factories to Optimize Shipping Routes?

CREATE TEMPORARY TABLE temp_all_distances AS
SELECT 
    p.`Product ID`, 
    p.`Product Name`, 
    p.`Factory` AS current_factory, 
    s.`Customer ID`, 
    s.`Country`, 
    s.`State`, 
    s.`Postal Code`, 
    u.`lat` AS customer_lat, 
    u.`lng` AS customer_lng, 
    f.`Factory` AS potential_factory,
    f.`Latitude` AS factory_lat, 
    f.`Longitude` AS factory_lng,
    2 * 6371 * ASIN(
        SQRT(
            POWER(SIN(RADIANS(f.`Latitude` - u.`lat`) / 2), 2) +
            COS(RADIANS(u.`lat`)) * COS(RADIANS(f.`Latitude`)) *
            POWER(SIN(RADIANS(f.`Longitude` - u.`lng`) / 2), 2)
        )
    ) AS distance_km
FROM 
    candy_products p
JOIN 
    candy_sales_staging s ON p.`Product ID` = s.`Product ID`
JOIN 
    uszips u ON s.`Postal Code` = u.`zip`
JOIN 
    candy_factories f;

SELECT *
FROM temp_all_distances;

CREATE TEMPORARY TABLE inefficient_current AS
SELECT 
    d.`Product ID`,
    d.`Product Name`,
    d.`Customer ID`,
    d.`current_factory`,
    d.`distance_km` AS current_distance
FROM 
    temp_all_distances d
WHERE 
    d.`distance_km` > 2000;
    
CREATE TEMPORARY TABLE closest_alternative AS
SELECT 
    a.`Product ID`,
    a.`Customer ID`,
    MIN(a.`distance_km`) AS closest_distance,
    MIN(a.`potential_factory`) AS closest_factory
FROM 
    temp_all_distances a
JOIN 
    inefficient_current ic ON a.`Product ID` = ic.`Product ID` AND a.`Customer ID` = ic.`Customer ID`
GROUP BY 
    a.`Product ID`, a.`Customer ID`;
    
SELECT 
    ic.`Product ID`,
    ic.`Product Name`,
    ic.`Customer ID`,
    ic.`current_factory`,
    ic.`current_distance`,
    ca.`closest_distance`,
    ca.`closest_factory`,
    CASE 
        WHEN ca.`closest_distance` < ic.`current_distance` THEN 'Reassign to Closest Factory'
        ELSE 'Current Factory Efficient'
    END AS recommendation
FROM 
    inefficient_current ic
JOIN 
    closest_alternative ca ON ic.`Product ID` = ca.`Product ID` AND ic.`Customer ID` = ca.`Customer ID`
WHERE 
    ca.`closest_distance` < ic.`current_distance`;