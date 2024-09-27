CREATE DATABASE OnlineClothing;
USE OnlineClothing;

/* Import CSV files into the database using import wizard tools */

/* DATA CLEANING AND TRANSFORMATION */

-- Remove duplicate GROSS_AMT values
SELECT DISTINCT GROSS_AMT
FROM SalesSummary2022;

-- Delete incorrect data from the table
DELETE FROM SalesSummary2022
WHERE GROSS_AMT = 'stock';

-- Change data types of specified columns
ALTER TABLE SalesSummary2022
ALTER COLUMN GROSS_AMT FLOAT;

ALTER TABLE SalesSummary2022
ALTER COLUMN RATE FLOAT;

ALTER TABLE SalesSummary2022
ALTER COLUMN PCS FLOAT;

-- Delete rows with NULL values where DATE is not a year and RATE / SKU are NULL
DELETE FROM SalesSummary2022
WHERE DATE NOT LIKE '%-21' AND DATE NOT LIKE '%-22' AND RATE IS NULL AND SKU IS NULL;

-- Correct column placements for DATE, MONTHS, and CUSTOMER
UPDATE SalesSummary2022
SET DATE = Months,
    Months = CUSTOMER,
    CUSTOMER = DATE
WHERE DATE NOT LIKE '%-21' AND DATE NOT LIKE '%-22';

-- Update data type of DATE column
ALTER TABLE SalesSummary2022
ALTER COLUMN DATE DATE;

-- Reorder Size, Qty, and TotalAmount columns
UPDATE SalesSummary2022
SET 
    Qty = Size,
    Price = Qty,
    TotalAmount = Price
WHERE 
    Size NOT IN ('Free', 'M') 
    AND Size NOT LIKE '%L' 
    AND Size NOT LIKE '%S%';

-- Extract size from SKU
WITH CTE AS (
    SELECT SKU,
           SUBSTRING(SKU, LEN(SKU) - CHARINDEX('-', REVERSE(SKU)) + 2, LEN(SKU)) AS new_size
    FROM SalesSummary2022
)
UPDATE SalesSummary2022 
SET Size = CTE.new_size
FROM SalesSummary2022 sal
JOIN CTE ON sal.SKU = CTE.SKU
WHERE Size LIKE '%.00';

-- Set Size to NULL if not indicated in SKU
UPDATE SalesSummary2022
SET Size = NULL
WHERE 
    Size NOT IN ('Free', 'M') 
    AND Size NOT LIKE '%L%' 
    AND Size NOT LIKE '%S%';

-- Remove '.' from Size
UPDATE SalesSummary2022
SET Size = SUBSTRING(Size, 1, LEN(Size) - 1)
WHERE Size LIKE '%.'; 

-- Set Size to NULL if it is still not indicated
UPDATE SalesSummary2022 
SET Size = NULL
WHERE Size LIKE '%.00';

-- Delete rows with NULL values in RATE and GROSS_AMT
DELETE FROM SalesSummary2022
WHERE RATE IS NULL AND GROSS_AMT IS NULL;

-- Check for NULL values in MONTHS
SELECT *
FROM SalesSummary2022
WHERE Months IS NULL;

-- Fill NULL values in SKU column using data from SalesAmazon
UPDATE SalesSummary2022
SET SKU = SalesAmazon.SKU
FROM SalesAmazon
WHERE SalesSummary2022.Style = SalesAmazon.Style
AND SalesSummary2022.SKU IS NULL;  

-- Rename the columns for clarity
EXEC sp_rename 'SalesSummary2022.DATE', 'Date', 'COLUMN';
EXEC sp_rename 'SalesSummary2022.CUSTOMER', 'CustomerName', 'COLUMN';
EXEC sp_rename 'SalesSummary2022.PCS', 'Qty', 'COLUMN';
EXEC sp_rename 'SalesSummary2022.RATE', 'Price', 'COLUMN';
EXEC sp_rename 'SalesSummary2022.GROSS_AMT', 'TotalAmount', 'COLUMN';
