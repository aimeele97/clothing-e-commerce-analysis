-- E-COMMERCE SALE ANALYSIS - PART 1

-- Question 1: International sales by month and year

SELECT 
    YEAR(Date) AS Year,
    MONTH(Date) AS Month,
    SUM(Qty) AS Quantity,
    CAST(SUM(TotalAmount) AS NUMERIC(10,2)) Total_sale
FROM SalesGlobal2022
GROUP BY YEAR(Date), MONTH(Date)
WITH ROLLUP
ORDER BY Year, Total_sale desc;

-- Question 2: National sales by month and year

SELECT 
    MONTH(Date) AS Month,
    YEAR(Date) AS Year,
    Courier_Status,
    SUM(Qty) AS Quantity,
    SUM(Amount) AS Total_sale,
    SUM(SUM(Amount)) OVER (PARTITION BY YEAR(Date) ORDER BY MONTH(Date)) AS Cumulative_Total_Sale
FROM SalesAmazon
WHERE  Courier_Status = 'Shipped'
GROUP BY MONTH(Date), YEAR(Date), Courier_Status
ORDER BY Year, Month;

-- Question 3: Top overseas customers contributing the most revenue

SELECT CustomerName, 
    Sum(Qty) as Quantity,
    Sum(TotalAmount) Total_sale,
    cast(Sum(TotalAmount) / sum(Sum(TotalAmount)) over () as numeric(3,2))
FROM SalesGlobal2022
GROUP BY CustomerName
ORDER by sum(TotalAmount) desc;

-- Question 4: Best-selling products categorized by category, size, and color

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

-- Question 5: Orders fulfilled by Amazon versus merchants and shipping service levels

SELECT Fulfilment, fulfilled_by, 
    ship_service_level, 
    COUNT(Qty) AS TotalOrders
FROM SalesAmazon
GROUP BY Fulfilment, fulfilled_by, ship_service_level;

-- Question 6: Percentage of canceled orders based on promotions

/* Number of canceled order over the total orders*/
SELECT count(case when STATUS ='Cancelled' then 1 end) cancel_order,
     count(*),
     cast(count(case when STATUS ='Cancelled' then 1 end) as float)/ count(*)
FROM SalesAmazon;

/* Percentage of cancelled orders incorporate with promotion_id*/
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

/* TOP 10 products have been cancelled, group by state, types of customers */
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

-- Question 7: Compare domestic (Amazon) sales to international sales

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
