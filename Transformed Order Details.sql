-- Selecting Database
USE [Restaurant Sales]

-- Selecting the table
SELECT * FROM order_details
SELECT * FROM menu_items

-- Keeping the original table and making temporary table
SELECT  *
INTO transformed_order_details
FROM order_details

-- droping the order_detail_id
ALTER TABLE transformed_order_details
DROP COLUMN order_details_id
SELECT * FROM transformed_order_details

-- Removing null values
DELETE FROM transformed_order_details
WHERE item_id = 'NULL'

-- Joinging the order with menu
SELECT
	t.order_id,
	t.order_date,
	t.order_time, 
	t.item_id,
	m.item_name,
	m.category,
	m.price
FROM transformed_order_details t
INNER JOIN menu_items m ON t.item_id = m.menu_item_id

--  What were the least and most ordered items? What categories were they in?	
WITH OrderCounts AS (
    SELECT
        od.item_id,
        COUNT(*) AS order_count
    FROM
        order_details od
    GROUP BY
        od.item_id
),
MaxMinCounts AS (
    SELECT
        MAX(order_count) AS max_order_count,
        MIN(order_count) AS min_order_count
    FROM
        OrderCounts
),
MostOrdered AS (
    SELECT
        oc.item_id,
        mi.item_name,
        mi.category,
        oc.order_count
    FROM
        OrderCounts oc
        JOIN menu_items mi ON oc.item_id = mi.menu_item_id
        JOIN MaxMinCounts mmc ON oc.order_count = mmc.max_order_count
),
LeastOrdered AS (
    SELECT
        oc.item_id,
        mi.item_name,
        mi.category,
        oc.order_count
    FROM
        OrderCounts oc
        JOIN menu_items mi ON oc.item_id = mi.menu_item_id
        JOIN MaxMinCounts mmc ON oc.order_count = mmc.min_order_count
)
SELECT 'Most Ordered Item' AS description, item_id, item_name, category, order_count
FROM MostOrdered
UNION ALL
SELECT 'Least Ordered Item' AS description, item_id, item_name, category, order_count
FROM LeastOrdered

SELECT 
    od.order_id, 
    MAX(od.order_date) AS order_date,
    MAX(od.order_time) AS order_time,
    STRING_AGG(CAST(od.item_id AS VARCHAR), ', ') AS total_items,
    STRING_AGG(CONCAT(mi.item_name, ' ($', FORMAT(mi.price, 'N2'), ')'), ', ') AS item_name_and_price,
    CONCAT('$', FORMAT(SUM(mi.price), 'N2')) AS total_price_per_order
FROM 
    transformed_order_details AS od
INNER JOIN 
    menu_items AS mi 
ON 
    od.item_id = mi.menu_item_id
GROUP BY 
    od.order_id
ORDER BY 
    SUM(mi.price) DESC

-- Were there certain times that had more or less orders?
SELECT 
    time_bin,
    COUNT(*) AS number_of_orders
FROM (
    SELECT 
        CASE 
            WHEN DATEPART(HOUR, order_time) BETWEEN 5 AND 9 THEN 'Morning'
            WHEN DATEPART(HOUR, order_time) BETWEEN 10 AND 11 THEN 'Midday'
            WHEN DATEPART(HOUR, order_time) BETWEEN 12 AND 16 THEN 'Afternoon'
            WHEN DATEPART(HOUR, order_time) BETWEEN 17 AND 20 THEN 'Evening'
            WHEN DATEPART(HOUR, order_time) BETWEEN 21 AND 23 THEN 'Night'
            ELSE 'Midnight'
        END AS time_bin
    FROM 
        order_details
) AS OrdersGrouped
GROUP BY 
    time_bin
ORDER BY 
    number_of_orders DESC;

-- Most order on a particular days?
SELECT TOP 5 
    CAST(order_date AS DATE) AS order_day, 
    DATENAME(WEEKDAY, order_date) AS day_of_week,
    COUNT(*) AS number_of_orders
FROM 
    order_details
GROUP BY 
    CAST(order_date AS DATE),
    DATENAME(WEEKDAY, order_date)
ORDER BY 
    number_of_orders DESC;

-- Least Order on a particular days?
SELECT TOP 5 
    CAST(order_date AS DATE) AS order_day, 
    DATENAME(WEEKDAY, order_date) AS day_of_week,
    COUNT(*) AS number_of_orders
FROM 
    order_details
GROUP BY 
    CAST(order_date AS DATE),
    DATENAME(WEEKDAY, order_date)
ORDER BY 
    number_of_orders ASC;

-- Top Selling Item
SELECT mi.item_name, COUNT(*) AS number_sold
FROM transformed_order_details od
JOIN menu_items mi ON od.item_id = mi.menu_item_id
GROUP BY mi.item_name
ORDER BY number_sold DESC;

-- Rarely Ordered Item
SELECT mi.item_name, COUNT(*) AS number_sold
FROM transformed_order_details od
JOIN menu_items mi ON od.item_id = mi.menu_item_id
GROUP BY mi.item_name
ORDER BY number_sold ASC;

-- Item generating most revenue
SELECT mi.item_name, SUM(mi.price) AS revenue
FROM transformed_order_details od
JOIN menu_items mi ON od.item_id = mi.menu_item_id
GROUP BY mi.item_name
ORDER BY revenue DESC;

-- Sales Fluctuation by Day of the Week
SELECT DATENAME(WEEKDAY, order_date) AS day_of_week, COUNT(*) AS number_of_orders
FROM transformed_order_details
GROUP BY DATENAME(WEEKDAY, order_date)
ORDER BY day_of_week;



