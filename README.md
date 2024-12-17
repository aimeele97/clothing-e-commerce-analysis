# Janasia online clothing sale analysis
![image.jpg](https://github.com/Aimee-Le/e_commerce_sale_analysis/blob/main/logosale.png)

## Overview
This project analyzes Janasia, an e-commerce clothing store based in India, **the datasets combine revenue from sales through Amazon and are divided into international and national sales, along with current stock levels data.** **15 business questions were formulated** to assess the store's performance and extract valuable insights. The goal is to identify strategies that can help improve and expand the business.

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

- The international revenue reached INR 32.9M from June 2021 to May 2022, with October 2021 as the best month at $6.25M. 
- National sales totaled INR 71M from March to June 2022, peaking in April at INR 26.3M. Mulberries Boutique accounted for 12% of international revenue. 
- Fulfillment methods include Amazon (82,051 expedited orders) and Janasia (36,725 standard orders). 
- 9 percent of national orders were canceled, primarily by B2C customers, with the Western dress being the most canceled item. 
- National revenue surpassed international in April 2022 and May 2022. Kurta and Kurta sets were the top domestic sellers, while jumpsuits and cardigans lagged. 
- The store faces inventory challenges with 736 items out of stock and excess stock on others, necessitating effective marketing strategies to optimize sales and reduce costs.

## Recommendations:
- Enhance Inventory Management: Implement robust tracking to minimize stock shortages and excess inventory.
- Targeted Marketing: Create promotions for overstock items and underperforming categories (e.g., jumpsuits, cardigans) alongside popular products like Kurtas.
- Boost Customer Engagement: Investigate the causes of the 9% order cancellations, especially in Western dresses, and offer incentives (promotions or discounts) to encourage purchases.
- Focus on High-Performing Markets: Tailor marketing efforts to national markets in April and May, when domestic revenue outperformed international sales.
- Diversify Fulfillment Channels: Explore additional fulfillment options beyond Amazon and Janasia to enhance customer satisfaction.
- Cultivate Key Customer Relationships: Strengthen ties with top overseas clients, such as Mulberries Boutique, by offering loyalty programs or bulk purchase discounts.

## Dataset

The data for this project is sourced from the Kaggle dataset:

- **Dataset Link:** [E-Commerce Dataset](https://www.kaggle.com/datasets/thedevastator/unlock-profits-with-e-commerce-sales-data/data?)

## Business Questions

- [Q1: International sales by month and year](#q1-international-sales-by-month-and-year)
- [Q2: National sales by month and year](#q2-national-sales-by-month-and-year)
- [Q3: Top overseas customers contributing the most revenue](#q3-top-overseas-customers-contributing-the-most-revenue)
- [Q4: Best-selling products categorized by category, size, and color](#q4-best-selling-products-categorized-by-category-size-and-color)
- [Q5: Orders fulfilled by Amazon versus merchants and shipping service levels](#q5-orders-fulfilled-by-amazon-versus-merchants)
- [Q6: Percentage of canceled orders based on promotions](#q6-percentage-of-canceled-orders-based-on-promotions)
- [Q7: Comparison of domestic (Amazon) sales to international sales](#q7-comparison-of-domestic-amazon-sales-to-international-sales)
- [Q8: Total orders and sales by status](#q8-total-orders-and-sales-by-status)
- [Q9: Most popular products on Amazon](#q9-most-popular-products-on-amazon)
- [Q10: Distribution of orders between B2B and B2C customers](#q10-distribution-of-orders-between-b2b-and-b2c-customers)
- [Q11: Percentage of orders affected by status and fulfillment methods](#q11-percentage-of-orders-affected-by-status-and-fulfillment-methods)
- [Q12: Order percentages for Amazon and merchant by state](#q12-order-percentages-for-amazon-and-merchant-by-state)
- [Q13: States with only Amazon or Merchant fulfillment](#q13-states-with-only-amazon-or-merchant-fulfillment)
- [Q14: Days since last customer order](#q14-days-since-last-customer-order)
- [Q15: Monthly quantity of items ordered and current stock levels](#q15-monthly-quantity-of-items-ordered-and-current-stock-levels)

## Schema - The Datasets were downloaded as CSV files and imported into the Database using the Import Wizard tool

```sql
CREATE DATABASE OnlineClothing;
USE OnlineClothing;
```

## Solutions

### Q1: International sales by month and year
```sql
SELECT 
    YEAR(Date) AS Year,
    MONTH(Date) AS Month,
    SUM(Qty) AS Quantity,
    CAST(SUM(TotalAmount) AS NUMERIC(10,2)) AS Total_sale
FROM SalesGlobal2022
GROUP BY YEAR(Date), MONTH(Date)
WITH ROLLUP
ORDER BY Year, Total_sale DESC;
```

### Q2: National sales by month and year
```sql
SELECT 
    MONTH(Date) AS Month,
    YEAR(Date) AS Year,
    Courier_Status,
    SUM(Qty) AS Quantity,
    SUM(Amount) AS Total_sale,
    SUM(SUM(Amount)) OVER (PARTITION BY YEAR(Date) ORDER BY MONTH(Date)) AS Cumulative_Total_Sale
FROM SalesAmazon
WHERE Courier_Status = 'Shipped'
GROUP BY MONTH(Date), YEAR(Date), Courier_Status
ORDER BY Year, Month;
```

### Q3: Top overseas customers contributing the most revenue
```sql
SELECT 
    CustomerName, 
    SUM(Qty) AS Quantity,
    SUM(TotalAmount) AS Total_sale,
    CAST(SUM(TotalAmount) / SUM(SUM(TotalAmount)) OVER () AS NUMERIC(3,2)) AS Percentage_Contribution
FROM SalesGlobal2022
GROUP BY CustomerName
ORDER BY SUM(TotalAmount) DESC;
```

### Q4: Best-selling products categorized by category, size, and color
```sql
SELECT 
    ama.Category, 
    ama.Size, 
    pro.Color, 
    SUM(ama.Qty) AS Quantity, 
    ROUND(SUM(TotalAmount), 2) AS TotalSales
FROM SalesGlobal2022 sal
FULL JOIN ( 
    SELECT *
    FROM SalesAmazon
    WHERE Courier_Status = 'Shipped'
) ama ON sal.sku = ama.SKU
JOIN Products pro ON sal.sku = pro.SKU_Code
GROUP BY ama.Category, ama.Size, pro.Color
ORDER BY Quantity DESC;
```

### Q5: Orders fulfilled by Amazon versus merchants and shipping service levels
```sql
SELECT 
    Fulfilment, 
    fulfilled_by, 
    ship_service_level, 
    COUNT(Qty) AS TotalOrders
FROM SalesAmazon
GROUP BY Fulfilment, fulfilled_by, ship_service_level;
```

### Q6: Percentage of canceled orders based on promotions
```sql
/* Number of canceled orders over the total orders */
SELECT 
    COUNT(CASE WHEN STATUS = 'Cancelled' THEN 1 END) AS Cancelled_Orders,
    COUNT(*) AS Total_Orders,
    CAST(COUNT(CASE WHEN STATUS = 'Cancelled' THEN 1 END) AS FLOAT) / COUNT(*) AS Cancellation_Rate
FROM SalesAmazon;

/* Percentage of cancelled orders incorporating promotion_ids */
WITH TBL AS (
    SELECT *,
        CASE WHEN promotion_ids IS NULL THEN 0 ELSE 1 END AS PROMOTION
    FROM SalesAmazon
    WHERE STATUS = 'Cancelled'
)
SELECT 
    PROMOTION, 
    ROUND(100 * CAST(COUNT(PROMOTION) AS FLOAT) / SUM(COUNT(PROMOTION)) OVER (), 2) AS Percentage_Cancelled
FROM TBL
GROUP BY PROMOTION;

/* TOP 10 products that have been cancelled, grouped by state and types of customers */
SELECT TOP 10 
    ship_state,
    SKU, 
    Category, 
    B2B,
    promotion_ids,
    COUNT(Order_ID) AS NumberOrdersCancelled
FROM SalesAmazon
GROUP BY SKU, B2B, Status, ship_state, Category, promotion_ids
HAVING STATUS = 'Cancelled'
ORDER BY NumberOrdersCancelled DESC;
```

### Q7: Comparison of domestic (Amazon) sales to international sales
```sql
WITH NAT AS (
    SELECT 
        MONTH(Date) AS Month,
        YEAR(Date) AS Year,
        SUM(Qty) AS Qty, 
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
    COALESCE(INT.Quantity, 0) AS QtyIn,
    COALESCE(INT.Total_sale, 0) AS SaleIn,
    COALESCE(NAT.Qty, 0) AS QtyNa,
    COALESCE(NAT.TotalSalesA, 0) AS SaleNa
FROM INT
FULL JOIN NAT ON NAT.Month = INT.Month AND NAT.Year = INT.Year
ORDER BY Year, Month;
```

### Q8: Total orders and sales by status
```sql
SELECT 
    Status,
    SUM(Qty) AS TotalQuantity, 
    SUM(Amount) AS TotalSales
FROM SalesAmazon 
GROUP BY Status
ORDER BY Status;
```

### Q9: Most popular products on Amazon
```sql
SELECT 
    PRO.Category, 
    ama.Size, 
    SUM(Qty) AS TotalQuantity, 
    ROUND(SUM(Amount), 2) AS TotalSales
FROM SalesAmazon ama 
JOIN Products pro ON ama.sku = pro.SKU_Code 
GROUP BY pro.Category, ama.Size
ORDER BY TotalSales DESC;
```

### Q10: Distribution of orders between B2B and B2C customers
```sql
WITH sorted_tbl AS (
    SELECT 
        B2B, 
        COUNT(Order_ID) AS NumberOrders,
        SUM(Qty) AS TotalQuantity,
        SUM(Amount) AS TotalSales
    FROM SalesAmazon
    GROUP BY B2B
)
SELECT *,
    ROUND(CAST(NumberOrders AS FLOAT) / SUM(NumberOrders) OVER(), 2) AS Percent_Orders
FROM sorted_tbl;
```

### Q11: Percentage of orders affected by status and fulfillment methods
```sql
WITH TBL AS (
    SELECT 
        Fulfilment,
        Status, 
        Courier_Status,
        COUNT(Order_ID) AS NumberOrders,
        SUM(Qty) AS TotalQuantity
    FROM SalesAmazon 
    GROUP BY Status, Fulfilment, Courier_Status
)
SELECT *,
    ROUND(CAST(NumberOrders AS FLOAT) / SUM(NumberOrders) OVER (PARTITION BY Fulfilment), 2) AS Percent_By_Fulfilment
FROM TBL
ORDER BY Fulfilment, Percent_By_Fulfilment DESC;
```

### Q12: Order percentages for Amazon and merchant by state
```sql
WITH City AS (
    SELECT 
        ship_state, 
        Fulfilment, 
        COUNT(Order_ID) AS NumberOrders 
    FROM SalesAmazon
    GROUP BY ship_state, Fulfilment
)
SELECT *, 
    CONCAT(ROUND(100 * CAST(NumberOrders AS FLOAT) / SUM(NumberOrders) OVER (PARTITION BY ship_state), 2), '%') AS Percentage_State
FROM City
ORDER BY ship_state;
```

### Q13: States with only Amazon or Merchant fulfillment
```sql
WITH City AS (
    SELECT 
        ship_state, 
        Fulfilment, 
        COUNT(Order_ID) AS NumberOrders 
    FROM SalesAmazon
    GROUP BY ship_state, Fulfilment
),
Ranked AS ( 
    SELECT *, 
    COUNT(ship_state) OVER (

PARTITION BY ship_state ORDER BY Fulfilment) AS Rank
    FROM City
)
SELECT ship_state, Fulfilment
FROM Ranked
WHERE ship_state IN (
    SELECT ship_state
    FROM Ranked
    GROUP BY ship_state
    HAVING COUNT(Rank) = 1
);
```

### Q14: Days since last customer order
```sql
WITH TBL_SORT AS ( 
    SELECT 
        Date, 
        CustomerName,
        COUNT(CustomerName) OVER (PARTITION BY CustomerName) AS Count
    FROM (
        SELECT 
            Date, 
            CustomerName
        FROM SalesGlobal2022
        GROUP BY Date, CustomerName
    ) AS Temp
),
TBL_RANK AS (
    SELECT 
        Date, 
        CustomerName, 
        Count,
        RANK() OVER (PARTITION BY CustomerName ORDER BY Date DESC) AS Rank
    FROM TBL_SORT
),
TBL_FINAL AS (
    SELECT *,
           DATEDIFF(DAY, Date, LEAD(Date) OVER (PARTITION BY CustomerName ORDER BY Date)) AS Date_Difference
    FROM TBL_RANK
    WHERE Rank <= 2 AND Count > 1
)
SELECT 
    Date AS RecentOrderDate, 
    CustomerName, 
    Count AS TotalOrders, 
    Date_Difference
FROM TBL_FINAL
WHERE Date_Difference IS NOT NULL
ORDER BY RecentOrderDate DESC, TotalOrders DESC, Date_Difference;
```

### Q15: Monthly quantity of items ordered and current stock levels
```sql
CREATE VIEW Sale_Figures_Month AS
WITH NAT AS (
    SELECT 
        SKU,
        MONTH(Date) AS Month,
        YEAR(Date) AS Year,
        SUM(Qty) AS Qty
    FROM SalesAmazon
    WHERE Courier_Status = 'Shipped'
    GROUP BY MONTH(Date), YEAR(Date), SKU
),
INT AS (
    SELECT 
        SKU,
        MONTH(Date) AS Month,
        YEAR(Date) AS Year,
        SUM(Qty) AS Quantity
    FROM SalesGlobal2022 
    GROUP BY MONTH(Date), YEAR(Date), SKU
)
SELECT 
    COALESCE(INT.SKU, NAT.SKU) AS SKU,
    COALESCE(INT.Month, NAT.Month) AS Month,
    COALESCE(INT.Year, NAT.Year) AS Year,
    COALESCE(INT.Quantity, 0) AS QtyIn,
    COALESCE(NAT.Qty, 0) AS QtyNa
FROM INT
FULL JOIN NAT ON NAT.Month = INT.Month AND NAT.Year = INT.Year;

/* Extract the stock number of each product, ordered by recent month and year */
WITH tbl AS (
    SELECT 
        Month, 
        Year, 
        SKU, 
        Category, 
        Stock, 
        SUM(QtyIn + QtyNa) AS OrderQuantity
    FROM Sale_Figures_Month sal
    JOIN Products pro ON sal.SKU = pro.SKU_Code
    GROUP BY Month, Year, Category, Stock, SKU
    ORDER BY OrderQuantity, Stock DESC
)
SELECT 
    COUNT(CASE WHEN Stock = 0 THEN 1 END) AS Out_Of_Stock,
    COUNT(CASE WHEN Stock < 10 THEN 1 END) AS Low_Stock
FROM tbl;
```
