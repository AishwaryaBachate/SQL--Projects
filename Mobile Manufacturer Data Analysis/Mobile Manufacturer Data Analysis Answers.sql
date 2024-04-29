--SQL Advance Case Study

--Q1--BEGIN 	
SELECT DISTINCT State 
FROM (
    SELECT dl.State, SUM(Quantity) AS qty, YEAR(ft.Date) AS Year 
    FROM DIM_LOCATION AS dl
    JOIN FACT_TRANSACTIONS AS ft
    ON dl.IDLocation = ft.IDLocation
    WHERE YEAR(ft.Date) >= 2005
    GROUP BY dl.State, YEAR(ft.Date)
) as states;

--Q1--END

--Q2--BEGIN
SELECT TOP 1 State, COUNT(*) as qty 
FROM DIM_LOCATION AS dl
JOIN FACT_TRANSACTIONS AS ft ON dl.IDLocation = ft.IDLocation
JOIN DIM_MODEL AS dm ON ft.IDModel = dm.IDModel
JOIN DIM_MANUFACTURER AS dmf ON dm.IDManufacturer = dmf.IDManufacturer
WHERE Country = 'US' AND Manufacturer_Name = 'Samsung'
GROUP BY State
ORDER BY qty DESC;


--Q2--END

--Q3--BEGIN      
SELECT IDModel, State, ZipCode, count(*) as tot_trans
FROM FACT_TRANSACTIONS AS ft
JOIN DIM_LOCATION AS dl ON ft.IDLocation = dl.IDLocation
GROUP BY IDModel, State, ZipCode;
	

--Q3--END

--Q4--BEGIN
SELECT TOP 1 Model_Name, MIN(Unit_price) AS min_unit_price 
FROM DIM_MODEL
GROUP BY Model_Name
ORDER BY min_unit_price ASC;

--Q4--END

--Q5--BEGIN
SELECT ft.IDModel, AVG(TotalPrice) AS avg_price, SUM(Quantity) AS total_qty 
FROM FACT_TRANSACTIONS AS ft
JOIN DIM_MODEL AS dm ON ft.IDModel = dm.IDModel
JOIN DIM_MANUFACTURER AS dmf ON dm.IDManufacturer = dmf.IDManufacturer
WHERE Manufacturer_Name IN (
    SELECT TOP 5 Manufacturer_Name FROM FACT_TRANSACTIONS AS ft
    JOIN DIM_MODEL AS dm ON ft.IDModel = dm.IDModel
    JOIN DIM_MANUFACTURER AS dmf ON dm.IDManufacturer = dmf.IDManufacturer
    GROUP BY Manufacturer_Name
    ORDER BY SUM(TotalPrice) DESC
)
GROUP BY ft.IDModel
ORDER BY avg_price DESC;


--Q5--END

--Q6--BEGIN
SELECT Customer_Name, AVG(TotalPrice) AS avg_price 
FROM DIM_CUSTOMER as dc
JOIN FACT_TRANSACTIONS AS ft ON dc.IDCustomer = ft.IDCustomer
WHERE YEAR(Date) = 2009
GROUP BY Customer_Name
HAVING AVG(TotalPrice) > 500;


--Q6--END
	
--Q7--BEGIN  
SELECT * FROM
(
    SELECT TOP 5 IDModel
    FROM FACT_TRANSACTIONS
    WHERE YEAR(Date) = 2008
    GROUP BY IDModel, YEAR(Date)
    ORDER BY SUM(Quantity) DESC
) AS tb1
INTERSECT
SELECT * FROM 
(
    SELECT TOP 5 IDModel 
    FROM FACT_TRANSACTIONS
    WHERE YEAR(Date) = 2009
    GROUP BY IDModel, YEAR(Date)
    ORDER BY SUM(Quantity) DESC
) AS tb2
INTERSECT
SELECT * FROM
(
    SELECT TOP 5 IDModel 
    FROM FACT_TRANSACTIONS
    WHERE YEAR(Date) = 2010
    GROUP BY IDModel, YEAR(Date)
    ORDER BY SUM(Quantity) DESC
) AS tb3;	

--Q7--END	

--Q8--BEGIN
SELECT * FROM 
(
    SELECT TOP 1 * FROM 
    (
        SELECT TOP 2 Manufacturer_Name, YEAR(Date) AS YEAR, SUM(TotalPrice) AS Sales FROM FACT_TRANSACTIONS AS ft
        JOIN DIM_MODEL AS dm ON ft.IDModel = dm.IDModel
        JOIN DIM_MANUFACTURER AS dmf ON dm.IDManufacturer = dmf.IDManufacturer
        WHERE YEAR(Date) = 2009
        GROUP BY Manufacturer_Name, YEAR(Date)
        ORDER BY Sales DESC
    ) AS tb
    ORDER BY Sales ASC
) AS tb1
UNION
SELECT * FROM 
(
    SELECT TOP 1 * FROM 
    (
        SELECT TOP 2 Manufacturer_Name, YEAR(Date) AS YEAR, SUM(TotalPrice) AS Sales 
        FROM FACT_TRANSACTIONS AS ft
        JOIN DIM_MODEL AS dm ON ft.IDModel = dm.IDModel
        JOIN DIM_MANUFACTURER AS dmf ON dm.IDManufacturer = dmf.IDManufacturer
        WHERE YEAR(Date) = 2010
        GROUP BY Manufacturer_Name, YEAR(Date)
        ORDER BY Sales DESC
    ) AS tb
    ORDER BY Sales ASC
) AS tb2;

--Q8--END

--Q9--BEGIN
SELECT Manufacturer_Name 
FROM FACT_TRANSACTIONS AS ft
JOIN DIM_MODEL AS dm ON ft.IDModel = dm.IDModel
JOIN DIM_MANUFACTURER AS dmf ON dm.IDManufacturer = dmf.IDManufacturer
WHERE YEAR(Date) = 2010
GROUP BY Manufacturer_Name
EXCEPT
SElECT Manufacturer_Name 
FROM FACT_TRANSACTIONS AS ft
JOIN DIM_MODEL AS dm ON ft.IDModel = dm.IDModel 
JOIN DIM_MANUFACTURER AS dmf ON dm.IDManufacturer = dmf.IDManufacturer
WHERE YEAR(Date) = 2009
GROUP BY Manufacturer_Name;

--Q9--END

--Q10--BEGIN
SELECT *, ((avg_price - lag_price)/lag_price) AS percentage_change 
FROM 
(
    SELECT *, LAG(avg_price, 1) OVER(PARTITION BY IDCustomer ORDER BY year) AS lag_price 
    FROM 
    (
        SELECT IDCustomer, YEAR(date) AS YEAR, AVG(TotalPrice) AS avg_price, SUM(Quantity) AS total_qty 
        FROM FACT_TRANSACTIONS
        WHERE IDCustomer IN 
        (
            SELECT TOP 10 IDCustomer 
            FROM FACT_TRANSACTIONS
            GROUP BY IDCustomer
            ORDER BY SUM(TotalPrice) DESC
        )
        GROUP BY IDCustomer, YEAR(date)
    ) AS tb1
) AS tb2;

--Q10--END
	