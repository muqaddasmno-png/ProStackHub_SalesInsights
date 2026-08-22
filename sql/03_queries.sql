-- ---------------------------------------------------------------------
-- Q1: Top 10 products by revenue, per region
-- (window function to rank within each region; GROUP BY on aggregated revenue)

SELECT Region, ProductName, Revenue, Rnk
FROM (
    SELECT
        r.RegionName AS Region,
        p.ProductName,
        SUM(oi.Quantity * oi.UnitPriceAtSale) AS Revenue,
        RANK() OVER (PARTITION BY r.RegionName ORDER BY SUM(oi.Quantity * oi.UnitPriceAtSale) DESC) AS Rnk
    FROM OrderItems oi
    JOIN Orders o ON o.OrderID = oi.OrderID
    JOIN Customers c ON c.CustomerID = o.CustomerID
    JOIN Regions r ON r.RegionID = c.RegionID
    JOIN Products p ON p.ProductID = oi.ProductID
    GROUP BY r.RegionName, p.ProductName
) ranked
WHERE Rnk <= 10
ORDER BY Region, Rnk;


-- ---------------------------------------------------------------------
-- Q2: Month-over-month revenue growth (overall)

SELECT
    Month,
    Revenue,
    ROUND(
        100.0 * (Revenue - LAG(Revenue) OVER (ORDER BY Month))
        / NULLIF(LAG(Revenue) OVER (ORDER BY Month), 0)
    , 2) AS MoM_Growth_Pct
FROM (
    SELECT
        DATE_FORMAT(o.OrderDate, '%Y-%m') AS Month,
        SUM(oi.Quantity * oi.UnitPriceAtSale) AS Revenue
    FROM Orders o
    JOIN OrderItems oi ON oi.OrderID = o.OrderID
    GROUP BY DATE_FORMAT(o.OrderDate, '%Y-%m')
) monthly
ORDER BY Month;


-- ---------------------------------------------------------------------
-- Q3: Customers inactive for 90+ days

SELECT
    c.CustomerID, c.FirstName, c.LastName,
    MAX(o.OrderDate) AS LastOrderDate,
    DATEDIFF(
        (SELECT MAX(OrderDate) FROM Orders),   
        MAX(o.OrderDate)
    ) AS DaysSinceLastOrder
FROM Customers c
JOIN Orders o ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
HAVING DaysSinceLastOrder >= 90
ORDER BY DaysSinceLastOrder DESC;


-- ---------------------------------------------------------------------
-- Q4: Customers whose average order value is above the overall average

SELECT * FROM (
    SELECT
        c.CustomerID, c.FirstName, c.LastName,
        (
            SELECT ROUND(AVG(order_total), 2)
            FROM (
                SELECT SUM(oi.Quantity * oi.UnitPriceAtSale) AS order_total
                FROM Orders o2
                JOIN OrderItems oi ON oi.OrderID = o2.OrderID
                WHERE o2.CustomerID = c.CustomerID   
                GROUP BY o2.OrderID
            ) per_order
        ) AS CustomerAOV
    FROM Customers c
) cust_aov
WHERE CustomerAOV > (
    SELECT AVG(order_total)                       
    FROM (
        SELECT SUM(oi.Quantity * oi.UnitPriceAtSale) AS order_total
        FROM Orders o
        JOIN OrderItems oi ON oi.OrderID = o.OrderID
        GROUP BY o.OrderID
    ) all_orders
)
ORDER BY CustomerAOV DESC;


-- ---------------------------------------------------------------------
-- Q5: Products that have never been ordered

SELECT p.ProductID, p.ProductName, p.Category
FROM Products p
WHERE NOT EXISTS (
    SELECT 1 FROM OrderItems oi
    WHERE oi.ProductID = p.ProductID   
)
ORDER BY p.Category, p.ProductName;


-- ---------------------------------------------------------------------
-- Q6: Revenue contribution by category (with % share)

SELECT
    p.Category,
    SUM(oi.Quantity * oi.UnitPriceAtSale) AS CategoryRevenue,
    ROUND(
        100.0 * SUM(oi.Quantity * oi.UnitPriceAtSale)
        / (SELECT SUM(oi2.Quantity * oi2.UnitPriceAtSale) FROM OrderItems oi2)
    , 2) AS PctOfTotalRevenue
FROM OrderItems oi
JOIN Products p ON p.ProductID = oi.ProductID
GROUP BY p.Category
HAVING CategoryRevenue > 0
ORDER BY CategoryRevenue DESC;


-- ---------------------------------------------------------------------
-- Q7: Average order value per region
SELECT
    r.RegionName,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    ROUND(SUM(oi.Quantity * oi.UnitPriceAtSale) / COUNT(DISTINCT o.OrderID), 2) AS AvgOrderValue
FROM Regions r
JOIN Customers c ON c.RegionID = r.RegionID
JOIN Orders o ON o.CustomerID = c.CustomerID
JOIN OrderItems oi ON oi.OrderID = o.OrderID
GROUP BY r.RegionName
ORDER BY AvgOrderValue DESC;


-- ---------------------------------------------------------------------
-- Q8: Top 5 customers by lifetime spend, using HAVING to filter on
-- the aggregated total (not a raw-row WHERE)

SELECT
    c.CustomerID, c.FirstName, c.LastName, r.RegionName,
    SUM(oi.Quantity * oi.UnitPriceAtSale) AS LifetimeSpend,
    COUNT(DISTINCT o.OrderID) AS TotalOrders
FROM Customers c
JOIN Regions r ON r.RegionID = c.RegionID
JOIN Orders o ON o.CustomerID = c.CustomerID
JOIN OrderItems oi ON oi.OrderID = o.OrderID
GROUP BY c.CustomerID, c.FirstName, c.LastName, r.RegionName
HAVING LifetimeSpend > 0
ORDER BY LifetimeSpend DESC
LIMIT 5;


-- ---------------------------------------------------------------------
-- Q9: Products with above-average unit price within their own category

SELECT p.ProductName, p.Category, p.UnitPrice
FROM Products p
WHERE p.UnitPrice > (
    SELECT AVG(p2.UnitPrice)
    FROM Products p2
    WHERE p2.Category = p.Category      
)
ORDER BY p.Category, p.UnitPrice DESC;
