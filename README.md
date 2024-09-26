# E-commerce sales analysis
![image.jpg](https://github.com/Aimee-Le/e_commerce_sale_analysis/blob/main/logosale.png)

## Overview
This project analyzes the Janasia clothing using SQL to extract insights and address key business questions. The following README summarizes the project's objectives, challenges, solutions, findings, and conclusions.

## Objectives

- **Sales trend**: Analyze trends by month/year, market, product category, quantity, promotion, location, and customer classification to  to identify high-performing and those needing improvement.
- **Stock management**: Extract monthly product sales data and stock levels to ensure timely restocking. Identify products eligible for promotion or clearance to reduce storage costs, and recommend solutions to enhance product performance.
- **Geography and customer classification**: Identify how customer preferences vary by geography to tailor product offerings and marketing strategies.
- **Order fulfillment**: Uncover order volumes by fulfillment to identify locations and services fulfilled by a single provider, determine whether to explore alternative providers for contingency plans or to consolidate services with one provider to reduce costs.

## Tasks:
- Set up workspace: download CSV files and import to database that was created using Azure Data Studio.
- Defining objectives and questions: understand the business problems, identify the data needed, define the metrics to measure the outcomes.
- Data cleaning: check errors and inconsistencies to correct the data, ensures the quality and reliability of the data.
- Data analysis: answer objective questions, discover patterns, relationships, trends. Focus on optimizing the query to reduce the running time.
- Upload to Github's repository.

## Findings and Conclusion

- **Content Distribution:** 

- **Geographical Insights:**

- **Content Categorization:**

## Dataset

The data for this project is sourced from the Kaggle dataset:

- **Dataset Link:** [E-Commerce Dataset](https://www.kaggle.com/datasets/thedevastator/unlock-profits-with-e-commerce-sales-data/data?)

## Schema - The Datasets were downloaded as CSV file and import to Database using Import Wizard tool

```sql
CREATE DATABASE OnlineClothing;
USE OnlineClothing;
```

## Business Problems and Solutions

### Question 1: International sales by month, year
```sql
SELECT MONTH(Date) as Month,
    YEAR(Date) as Year,
    SUM(Qty) as Quantity,
    SUM(TotalAmount) as Total_sale,
    ROUND(SUM(TotalAmount)/SUM(Qty), 2) CostPerItem
FROM SalesGlobal2022
GROUP BY MONTH(Date), YEAR(Date)
ORDER BY Year, Month;
```
**Observations:**

###  Question 2: National sales by month, year
```sql
SELECT MONTH(Date) as Month,
    YEAR(Date) as Year,
    Courier_Status,
    SUM(Qty) as Quantity,
    SUM(Amount) as Total_sale,
    ROUND(SUM(Amount)/SUM(Qty), 2) CostPerItem
FROM SalesAmazon
GROUP BY MONTH(Date), YEAR(Date), Courier_Status
HAVING Courier_Status = 'Shipped'
ORDER BY Year, Month;
```
### Question 3: Top biggest oversea customers paying the most
```sql
SELECT CustomerName, 
    Sum(Qty) as Quantity,
    Sum(TotalAmount) Total_sale
FROM SalesGlobal2022
GROUP BY CustomerName
ORDER by sum(TotalAmount) desc;
```
### Question 4: Best selling products group by category, size, colors
```sql
SELECT ama.Category, ama.Size, pro.Color, 
    SUM(ama.Qty) Quantity, 
    ROUND(SUM(TotalAmount),2) TotalSales
FROM SalesGlobal2022 sal
FULL JOIN ( 
        SELECT *
        FROM SalesAmazon
        WHERE Courier_Status = 'Shipped') ama
    ON sal.sku = ama.SKU
JOIN Products pro 
    ON sal.sku = pro.SKU_Code
GROUP BY ama.Category, ama.Size, pro.Color
ORDER BY Quantity desc;
```
### Question 5: Number of order fulfil by Amazon and Merchant, shipping service level
```sql
SELECT  Fulfilment, fulfilled_by, ship_service_level, COUNT(Qty) TotalOrders
FROM SalesAmazon
GROUP BY Fulfilment, fulfilled_by, ship_service_level;
```
### Question 6: Percentage of cancelled orders partition by promotion 
```sql
WITH TBL AS (
    SELECT *,
        CASE WHEN promotion_ids IS NULL THEN 0
        ELSE 1 
        END AS PROMOTION
    FROM SalesAmazon
    WHERE STATUS = 'Cancelled'
)
SELECT PROMOTION, ROUND(100 * CAST(COUNT(PROMOTION) AS FLOAT)/ SUM(COUNT(PROMOTION)) OVER (), 2) PER_CANCELLED
FROM TBL
GROUP BY PROMOTION;
-- TOP 10 products have been cancelled, group by state, types of customers
SELECT TOP 10 
    ship_state,
    SKU, 
    Category, 
    B2B,
    promotion_ids,
    COUNT(Order_ID) NumberOrdersCancelled
FROM SalesAmazon
GROUP BY SKU, B2B, Status, ship_state, Category, promotion_ids
HAVING STATUS = 'Cancelled'
ORDER BY NumberOrdersCancelled desc;
```
### Quesitons 7: Compare sales between Domestic (through Amazon) and International Sale 
```sql
WITH NAT AS (
    SELECT 
        MONTH(Date) AS Month,
        YEAR(Date) AS Year,
        SUM(Qty) AS qty, 
        SUM(Amount) AS TotalSalesA
    FROM SalesAmazon
    WHERE Courier_Status = 'Shipped'
    GROUP BY MONTH(Date), YEAR(Date)
),
INT AS (
    SELECT 
        MONTH(Date) AS Month,
        YEAR(Date) AS Year,
        SUM(Qty) AS Quantity,
        SUM(TotalAmount) AS Total_sale
    FROM SalesGlobal2022 
    GROUP BY MONTH(Date), YEAR(Date)
)
SELECT 
    COALESCE(INT.Month, NAT.Month) AS Month,
    COALESCE(INT.Year, NAT.Year) AS Year,
    COALESCE(INT.Quantity, 0) AS QuanIn,
    COALESCE(INT.Total_sale, 0) AS SaleIn,
    COALESCE(NAT.qty, 0) AS QuanNa,
    COALESCE(NAT.TotalSalesA, 0) AS SaleNa
FROM INT
FULL JOIN NAT
    ON NAT.Month = INT.Month AND NAT.Year = INT.Year
ORDER BY Year, Month;
```
### Question 8: Total orders, sales by Status, delivery type
```sql
SELECT Status, 
    ship_service_level,
    SUM(Qty) TotalQuantity, 
    SUM(Amount) TotalSales
FROM SalesAmazon ama 
GROUP BY Status, ship_service_level
ORDER BY Status, ship_service_level;
```
### Question 9: Popular products sales on Amazon
```sql
SELECT PRO.Category, ama.Size, 
    SUM(Qty) TotalQuantity, 
    ROUND(SUM(Amount),2) TotalSales
FROM SalesAmazon ama 
JOIN Products pro 
    ON ama.sku = pro.SKU_Code 
GROUP BY pro.Category, ama.Size
ORDER BY TotalSales desc;
```
### Question 10: Order distribution between B2B and B2C
```sql
WITH sorted_tbl as (
    SELECT B2B, 
    COUNT(Order_ID) NumberOrders,
    SUM(Qty) TotalQuantity,
    SUM(Amount) TotalSales
    FROM SalesAmazon
    GROUP BY B2B
)
SELECT *,
    round(cast(NumberOrders as float) / sum(NumberOrders) over(), 2) Percent_orders
FROM sorted_tbl
```
### Question 11: Percentage of orders by status and fulfilment methods
```sql
WITH TBL AS (
    SELECT 
    Fulfilment,
    Status, 
    Courier_Status,
    COUNT(Order_ID) NumberOrders,
    SUM(Qty) TotalQuantity
    FROM SalesAmazon ama 
    GROUP BY Status, Fulfilment, Courier_Status
)
SELECT *,
    Round(cast(NumberOrders as float) / sum(NumberOrders) over(partition by Fulfilment), 2) percent_by_fulfilment
FROM TBL
ORDER BY Fulfilment, percent_by_fulfilment DESC;
```
### Question 12: Percentage of number orders of Amazon and Mercahnt by State.
```sql
WITH City as (
    SELECT ship_state, Fulfilment, count(Order_ID) as NumberOrders 
    FROM SalesAmazon
    GROUP BY ship_state, Fulfilment
)
SELECT *, 
    concat(round(100* cast(NumberOrders as float) / SUM(NumberOrders) OVER (PARTITION BY ship_state), 2), '%') as 'Percentage_state'
FROM City
ORDER BY ship_state
```
### Question 13: Extract the states that only Amazon or Merchant fulfilment
```sql
WITH City as (
    SELECT ship_state, Fulfilment, count(Order_ID) as NumberOrders 
    FROM SalesAmazon
    GROUP BY ship_state, Fulfilment
)
, rank as ( 
    SELECT *, 
    count(ship_state) OVER (PARTITION BY ship_state ORDER BY Fulfilment) rank
    FROM City
)
SELECT ship_state, Fulfilment
FROM rank
WHERE ship_state in
    (SELECT ship_state
    FROM rank
    GROUP BY ship_state
    HAVING count(rank) = 1)
```
### Question 14: Recent number of days that customers place orders from the last orders
```sql
WITH TBL_SORT AS ( 
    SELECT Date, CustomerName,
           COUNT(CustomerName) OVER (PARTITION BY CustomerName) AS Count
    FROM (
        SELECT Date, CustomerName
        FROM SalesGlobal2022
        GROUP BY Date, CustomerName
    ) AS Temp
),
TBL_RANK AS (
    SELECT Date, CustomerName, Count,
           RANK() OVER (PARTITION BY CustomerName ORDER BY Date DESC) AS Rank
    FROM TBL_SORT
),
TBL_FINAL AS (
    SELECT *,
           DATEDIFF(DAY, Date, LEAD(Date) OVER (PARTITION BY CustomerName ORDER BY Date)) AS Date_difference
    FROM TBL_RANK
    WHERE Rank <= 2 AND Count > 1
)
SELECT Date AS RecentOrderDate, CustomerName, Count AS TotalOrders, Date_difference
FROM TBL_FINAL
WHERE Date_difference IS NOT NULL
ORDER BY RecentOrderDate DESC, TotalOrders DESC, Date_difference;
```
### Question 15: Extract the average order quantity and amount of sales for each products group by month, year. discover the products that out of stock and overstock
```sql
/* CREATE VIEW Sale_figures_month AS */

WITH NAT AS (
    SELECT 
        SKU,
        MONTH(Date) AS Month,
        YEAR(Date) AS Year,
        SUM(Qty) AS qty, 
        SUM(Amount) AS TotalSalesA
    FROM SalesAmazon
    WHERE Courier_Status = 'Shipped'
    GROUP BY MONTH(Date), YEAR(Date), SKU
),
INT AS (
    SELECT 
        SKU,
        MONTH(Date) AS Month,
        YEAR(Date) AS Year,
        SUM(Qty) AS Quantity,
        SUM(TotalAmount) AS Total_sale
    FROM SalesGlobal2022 
    GROUP BY MONTH(Date), YEAR(Date), SKU
)
SELECT COALESCE(INT.SKU, NAT.SKU) AS SKU,
    COALESCE(INT.Month, NAT.Month) AS Month,
    COALESCE(INT.Year, NAT.Year) AS Year,
    COALESCE(INT.Quantity, 0) AS QuanIn,
    COALESCE(INT.Total_sale, 0) AS SaleIn,
    COALESCE(NAT.qty, 0) AS QuanNa,
    COALESCE(NAT.TotalSalesA, 0) AS SaleNa
FROM INT
FULL JOIN NAT
    ON NAT.Month = INT.Month AND NAT.Year = INT.Year;

/* Extract the stock number of each products, order by recent month, and year */

SELECT Month, Year, SKU, Category, Stock, sum(QuanIn + QuanNa) OrderQuantity, sum(SaleIn + SaleNa) AmountSales
FROM Sale_figures_month sal
JOIN Products pro
    ON sal.SKU = pro.SKU_Code
GROUP BY Month, Year, Category, Stock, SKU
ORDER BY YEAR DESC, MONTH DESC, Stock
```

This analysis provides a comprehensive view of E-commerce clothing business's sales performance to drive business decision-making.

