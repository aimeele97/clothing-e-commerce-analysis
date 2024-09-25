-- E-COMMERCE SALE ANALYSIS - PART 1

-- Question 1: International sales by month, year

SELECT MONTH(Date) as Month,
    YEAR(Date) as Year,
    SUM(Qty) as Quantity,
    SUM(TotalAmount) as Total_sale,
    ROUND(SUM(TotalAmount)/SUM(Qty), 2) CostPerItem
FROM SalesGlobal2022
GROUP BY MONTH(Date), YEAR(Date)
ORDER BY Year, Month;

-- Question 2: National sales by month, year

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

-- Question 3: Top biggest oversea customers paying the most

SELECT CustomerName, 
    Sum(Qty) as Quantity,
    Sum(TotalAmount) Total_sale
FROM SalesGlobal2022
GROUP BY CustomerName
ORDER by sum(TotalAmount) desc;

-- Question 4: Best selling products group by category and size

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

-- Question 5: Number of order fulfil by Amazon and Merchant, shipping service level

SELECT  Fulfilment, fulfilled_by, ship_service_level, COUNT(Qty) TotalOrders
FROM SalesAmazon
GROUP BY Fulfilment, fulfilled_by, ship_service_level;

-- Question 6: Percentage of cancelled orders partition by promotion

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

-- TOP ten products have been cancelled, group by state, types of customers
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

-- Quesitons 7: Compare sales between Domestic (through Amazon) and International Sale 

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
