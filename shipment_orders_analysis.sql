SELECT DISTINCT * FROM shipment_orders;

-- total selling price and profit for all orders    
SELECT "Order Id", 
       SUM("Total Sales") AS "Total Selling Price",
       SUM("Quantity" * ("Selling Price" - "cost price")) AS "Total Profit"
FROM shipment_orders
GROUP BY "Order Id"
ORDER BY "Total Profit" DESC;

-- technology orders shipped via second class
SELECT "Order Id", "Order Date" FROM shipment_orders
WHERE "Category" = 'Technology' AND "Ship Mode" = 'Second Class'
ORDER BY "Order Date";

-- average order value
SELECT ROUND(AVG("Total Sales")) AS Average_Total_Sales
FROM shipment_orders;

-- city with highest total quantity
SELECT "City", SUM("Quantity") AS total_quantity FROM shipment_orders
GROUP BY "City"
ORDER BY total_quantity DESC;

-- rank orders in each region by quantity
SELECT "Order Id", "Region", "Quantity",
       DENSE_RANK() OVER (PARTITION BY "Region" ORDER BY "Quantity" DESC) AS rnk
FROM shipment_orders
ORDER BY "Region", rnk;


-- highest sales month per category
WITH cte AS (
    SELECT "Category",
           TO_CHAR("Order Date", 'YYYY-MM') AS order_year_month,
           ROUND(SUM("Total Sales")) AS sales,
           ROW_NUMBER() OVER (PARTITION BY "Category" ORDER BY SUM("Total Sales") DESC) AS rn
    FROM shipment_orders
    GROUP BY "Category", TO_CHAR("Order Date", 'YYYY-MM')
)
SELECT "Category", order_year_month AS "Order Year-Month", sales AS "Total Sales"
FROM cte
WHERE rn = 1;


-- orders in Quater1-Q1 (Jan to March) with total value
SELECT "Order Id", "Order Date",
       ROUND(SUM("Total Sales")::numeric, 2) AS "Total Value"
FROM shipment_orders
WHERE EXTRACT(MONTH FROM "Order Date") IN (1, 2, 3)
GROUP BY "Order Id", "Order Date"
ORDER BY "Total Value" DESC;

-- month over month growth 2022 vs 2023
SELECT 
    EXTRACT(MONTH FROM "Order Date") AS order_month,
    ROUND(SUM(CASE WHEN EXTRACT(YEAR FROM "Order Date") = 2022 THEN "Total Sales" ELSE 0 END)::numeric, 2) AS sales_2022,
    ROUND(SUM(CASE WHEN EXTRACT(YEAR FROM "Order Date") = 2023 THEN "Total Sales" ELSE 0 END)::numeric, 2) AS sales_2023
FROM shipment_orders
GROUP BY order_month
ORDER BY order_month;


-- sub category with highest growth in 2023 vs 2022
WITH cte AS (
    SELECT "Sub Category",
           EXTRACT(YEAR FROM "Order Date") AS order_year,
           SUM("Quantity" * "Selling Price") AS sales
    FROM shipment_orders
    GROUP BY "Sub Category", order_year
),
cte2 AS (
    SELECT "Sub Category",
           ROUND(SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END)::numeric, 2) AS sales_2022,
           ROUND(SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END)::numeric, 2) AS sales_2023
    FROM cte
    GROUP BY "Sub Category"
)
SELECT "Sub Category",
       sales_2022 AS "Sales in 2022",
       sales_2023 AS "Sales in 2023",
       (sales_2023 - sales_2022) AS "Diff in Amount"
FROM cte2
ORDER BY "Diff in Amount" DESC
LIMIT 1;



--- Use SQL to segment customers based on their purchasing patterns, such as frequent vs. infrequent buyers, high vs. low spenders, or by the categories they purchase from most often. This might involve multiple joins and aggregations to calculate the metrics that define each segment.

WITH spender_segments AS (
    SELECT "Order Id",
           ROUND(SUM("Total Sales")::numeric, 2) AS total_spent,
           CASE
               WHEN SUM("Total Sales") >= 1000 THEN 'High Spender'
               WHEN SUM("Total Sales") BETWEEN 500 AND 999 THEN 'Medium Spender'
               ELSE 'Low Spender'
           END AS spender_segment
    FROM shipment_orders
    GROUP BY "Order Id"
)
SELECT spender_segment,
       COUNT(*) AS total_customers,
       ROUND(AVG(total_spent)::numeric, 2) AS avg_spend,
       ROUND(SUM(total_spent)::numeric, 2) AS total_revenue,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM spender_segments
GROUP BY spender_segment
ORDER BY total_revenue DESC;
