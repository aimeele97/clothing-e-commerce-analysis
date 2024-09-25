-- E-COMMERCE SALE ANALYSIS - PART 2

-- Question 8: Total orders, sales by Status, delivery type

SELECT Status, 
    ship_service_level,
    SUM(Qty) TotalQuantity, 
    SUM(Amount) TotalSales
FROM SalesAmazon ama 
GROUP BY Status, ship_service_level
ORDER BY Status, ship_service_level;

-- Question 9: Popular products sales on Amazon

SELECT PRO.Category, ama.Size, SUM(Qty) TotalQuantity, ROUND(SUM(Amount),2) TotalSales
FROM SalesAmazon ama 
JOIN Products pro 
ON ama.sku = pro.SKU_Code 
GROUP BY pro.Category, ama.Size
ORDER BY TotalSales desc;

-- Question 10: Order distribution between B2B and B2C

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

-- Question 11: Percentage of orders by status and fulfilment methods

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

-- Question 12: Percentage of number orders of Amazon and Mercahnt by State.

WITH City as (
    SELECT ship_state, Fulfilment, count(Order_ID) as NumberOrders 
    FROM SalesAmazon
    GROUP BY ship_state, Fulfilment
)
SELECT *, 
    concat(round(100* cast(NumberOrders as float) / SUM(NumberOrders) OVER (PARTITION BY ship_state), 2), '%') as 'Percentage_state'
FROM City
ORDER BY ship_state

-- Question 13:  Extract the states that only Amazon or Merchant fulfilment

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

-- Question 14: Recent number of days that customers place orders from the last orders

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

-- Question 15: Extract the average order quantity and amount of sales for each products group by month, year. discover the products that out of stock and overstock

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