-- Q1: How did net sales change month over month?
WITH monthly_sales AS (
  SELECT strftime('%Y-%m', o.OrderDate) AS sales_month,
         SUM(od.UnitPrice * od.Quantity * (1.0 - od.Discount)) AS net_sales
  FROM Orders o JOIN "Order Details" od ON od.OrderID = o.OrderID
  GROUP BY strftime('%Y-%m', o.OrderDate)
), trend AS (
  SELECT sales_month, net_sales, LAG(net_sales) OVER (ORDER BY sales_month) AS prior_month_sales
  FROM monthly_sales
)
SELECT sales_month, ROUND(net_sales, 2) AS net_sales,
       ROUND(net_sales - prior_month_sales, 2) AS change_vs_prior_month,
       ROUND(100.0 * (net_sales - prior_month_sales) / NULLIF(prior_month_sales, 0), 1) AS pct_change
FROM trend ORDER BY sales_month;
-- END Q1

-- Q2: Which product categories generate the most revenue, and what is each category's share?
WITH category_sales AS (
  SELECT c.CategoryName, SUM(od.UnitPrice * od.Quantity * (1.0 - od.Discount)) AS net_sales
  FROM "Order Details" od JOIN Products p ON p.ProductID = od.ProductID
  JOIN Categories c ON c.CategoryID = p.CategoryID
  GROUP BY c.CategoryName
)
SELECT CategoryName, ROUND(net_sales, 2) AS net_sales,
       ROUND(100.0 * net_sales / SUM(net_sales) OVER (), 2) AS pct_of_sales,
       DENSE_RANK() OVER (ORDER BY net_sales DESC) AS sales_rank
FROM category_sales ORDER BY net_sales DESC;
-- END Q2

-- Q3: What are the top three products by net sales within each category?
WITH product_sales AS (
  SELECT c.CategoryName, p.ProductName,
         SUM(od.UnitPrice * od.Quantity * (1.0 - od.Discount)) AS net_sales,
         SUM(od.Quantity) AS units_sold
  FROM "Order Details" od JOIN Products p ON p.ProductID = od.ProductID
  JOIN Categories c ON c.CategoryID = p.CategoryID
  GROUP BY c.CategoryName, p.ProductID, p.ProductName
), ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY CategoryName ORDER BY net_sales DESC) AS category_rank
  FROM product_sales
)
SELECT CategoryName, category_rank, ProductName, ROUND(net_sales, 2) AS net_sales, units_sold
FROM ranked WHERE category_rank <= 3 ORDER BY CategoryName, category_rank;
-- END Q3

-- Q4: Which customers have the highest lifetime net sales within each country?
WITH customer_sales AS (
  SELECT c.Country, c.CompanyName, c.CustomerID,
         COUNT(DISTINCT o.OrderID) AS order_count,
         SUM(od.UnitPrice * od.Quantity * (1.0 - od.Discount)) AS lifetime_net_sales
  FROM Customers c JOIN Orders o ON o.CustomerID = c.CustomerID
  JOIN "Order Details" od ON od.OrderID = o.OrderID
  GROUP BY c.Country, c.CompanyName, c.CustomerID
), ranked AS (
  SELECT *, DENSE_RANK() OVER (PARTITION BY Country ORDER BY lifetime_net_sales DESC) AS country_rank
  FROM customer_sales
)
SELECT Country, country_rank, CompanyName, order_count, ROUND(lifetime_net_sales, 2) AS lifetime_net_sales
FROM ranked WHERE country_rank <= 3 ORDER BY Country, country_rank;
-- END Q4

-- Q5: How do employees rank by annual net sales?
WITH employee_year_sales AS (
  SELECT strftime('%Y', o.OrderDate) AS sales_year, e.EmployeeID,
         e.FirstName || ' ' || e.LastName AS employee,
         SUM(od.UnitPrice * od.Quantity * (1.0 - od.Discount)) AS net_sales,
         COUNT(DISTINCT o.OrderID) AS orders_handled
  FROM Employees e JOIN Orders o ON o.EmployeeID = e.EmployeeID
  JOIN "Order Details" od ON od.OrderID = o.OrderID
  GROUP BY sales_year, e.EmployeeID, employee
), ranked AS (
  SELECT *, RANK() OVER (PARTITION BY sales_year ORDER BY net_sales DESC) AS annual_rank
  FROM employee_year_sales
)
SELECT sales_year, annual_rank, employee, orders_handled, ROUND(net_sales, 2) AS net_sales
FROM ranked ORDER BY sales_year, annual_rank;
-- END Q5

-- Q6: Which shippers are most reliable against required delivery dates?
SELECT s.CompanyName AS shipper, COUNT(*) AS shipped_orders,
       SUM(CASE WHEN julianday(o.ShippedDate) <= julianday(o.RequiredDate) THEN 1 ELSE 0 END) AS on_time_orders,
       ROUND(100.0 * SUM(CASE WHEN julianday(o.ShippedDate) <= julianday(o.RequiredDate) THEN 1 ELSE 0 END) / COUNT(*), 1) AS on_time_pct,
       ROUND(AVG(julianday(o.ShippedDate) - julianday(o.OrderDate)), 1) AS avg_days_order_to_ship,
       ROUND(AVG(MAX(0, julianday(o.ShippedDate) - julianday(o.RequiredDate))), 1) AS avg_late_days
FROM Orders o JOIN Shippers s ON s.ShipperID = o.ShipVia
WHERE o.ShippedDate IS NOT NULL AND o.RequiredDate IS NOT NULL
GROUP BY s.ShipperID, s.CompanyName ORDER BY on_time_pct DESC;
-- END Q6

-- Q7: Which repeat customers place at least three orders, and how often do they reorder?
WITH order_gaps AS (
  SELECT o.CustomerID, o.OrderID, o.OrderDate,
         LAG(o.OrderDate) OVER (PARTITION BY o.CustomerID ORDER BY o.OrderDate, o.OrderID) AS prior_order_date
  FROM Orders o
), customer_cadence AS (
  SELECT CustomerID, COUNT(*) AS order_count,
         AVG(julianday(OrderDate) - julianday(prior_order_date)) AS avg_days_between_orders
  FROM order_gaps GROUP BY CustomerID
)
SELECT c.CompanyName, c.Country, cc.order_count, ROUND(cc.avg_days_between_orders, 1) AS avg_days_between_orders
FROM customer_cadence cc JOIN Customers c ON c.CustomerID = cc.CustomerID
WHERE cc.order_count >= 3 ORDER BY cc.order_count DESC, avg_days_between_orders;
-- END Q7

-- Q8: How much sales value is associated with each discount band?
WITH line_sales AS (
  SELECT CASE WHEN od.Discount = 0 THEN 'No discount'
              WHEN od.Discount <= 0.10 THEN 'Up to 10%'
              WHEN od.Discount <= 0.20 THEN '10%-20%'
              ELSE 'Above 20%' END AS discount_band,
         od.Quantity,
         od.UnitPrice * od.Quantity AS gross_sales,
         od.UnitPrice * od.Quantity * (1.0 - od.Discount) AS net_sales,
         od.Discount
  FROM "Order Details" od
)
SELECT discount_band, COUNT(*) AS line_items, SUM(Quantity) AS units,
       ROUND(SUM(gross_sales), 2) AS gross_sales, ROUND(SUM(net_sales), 2) AS net_sales,
       ROUND(100.0 * (SUM(gross_sales) - SUM(net_sales)) / NULLIF(SUM(gross_sales), 0), 2) AS effective_discount_pct
FROM line_sales GROUP BY discount_band ORDER BY MIN(Discount);
-- END Q8

-- Q9: Which products are at or below their reorder point, and who supplies them?
SELECT p.ProductName, c.CategoryName, s.CompanyName AS supplier,
       p.UnitsInStock, p.UnitsOnOrder, p.ReorderLevel,
       (p.ReorderLevel - p.UnitsInStock) AS units_below_reorder_point
FROM Products p LEFT JOIN Categories c ON c.CategoryID = p.CategoryID
LEFT JOIN Suppliers s ON s.SupplierID = p.SupplierID
WHERE p.Discontinued = '0' AND p.UnitsInStock <= p.ReorderLevel
ORDER BY units_below_reorder_point DESC, p.UnitsInStock;
-- END Q9

-- Q10: Which ship-to countries contribute the most net sales?
WITH country_sales AS (
  SELECT o.ShipCountry,
         SUM(od.UnitPrice * od.Quantity * (1.0 - od.Discount)) AS net_sales,
         COUNT(DISTINCT o.OrderID) AS order_count
  FROM Orders o JOIN "Order Details" od ON od.OrderID = o.OrderID
  GROUP BY o.ShipCountry
)
SELECT ShipCountry, order_count, ROUND(net_sales, 2) AS net_sales,
       ROUND(100.0 * net_sales / SUM(net_sales) OVER (), 2) AS pct_of_sales,
       DENSE_RANK() OVER (ORDER BY net_sales DESC) AS country_rank
FROM country_sales ORDER BY net_sales DESC;
-- END Q10
