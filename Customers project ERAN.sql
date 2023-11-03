

/* 1) i wanted to reach all customers whose order is out of stock, so our customer service department can solve the situtaion.
*/

-- (STEP 1) here are all the orders which are out of stock:

with No_Stock as (
SELECT od.OrderId, 
p.ProductName, 
od.UnitPrice,
od.Quantity,
p.UnitsInStock, 
od.UnitPrice * od.Quantity as order_value 
FROM [Order Details] od JOIN Products p 
ON od.ProductID = p.ProductID
WHERE UnitsInStock = 0 
AND 
Discontinued = 0
)

-- (STEP 2) here is the table of all those customers with their info, ranked by urgency:

SELECT distinct cu.CompanyName, cu.CustomerID, cu.ContactName, cu.Phone, ns.order_value, 
DENSE_RANK () over (ORDER BY os.orderdate) as Urgency
FROM Orders os JOIN No_Stock ns ON os.OrderID = ns.OrderID
               JOIN customers cu ON cu.CustomerID = os.CustomerID 

ORDER BY urgency 


/* 2) now i want to see the distribution of sells by each category, so we know which one is more profitable:
*/

-- (STEP 1) ID and CategoryID of the orders, joining products table and orders table: 
 

;with crValue as (
SELECT pr.productid, pr.categoryid, ord.unitprice*ord.quantity AS Total_Value
FROM products pr INNER JOIN [Order Details] ord
ON pr.ProductID = ord.ProductID 
 ) 


 -- (STEP 2) sum of total sells (crd.Total_Value), grouped by category:

SELECT cr.CategoryName, SUM(crd.Total_Value) AS Total_Sells
FROM categories cr INNER JOIN crValue crd
ON cr.categoryid = crd.categoryid
GROUP BY  cr.CategoryName
ORDER BY Total_Sells desc

SELECT cr.categoryname, SUM(od.unitprice*od.quantity) AS total_sells
FROM [Order Details] od JOIN Products pr
ON od.productid = pr.productid
JOIN Categories cr
ON cr.categoryid = pr.categoryid
GROUP BY cr.categoryname
ORDER BY total_sells desc

/* 3) company wants to stop cooperation with the 3 least profitable suppliers, 
and accelerate cooperation with the top 3 profitable suppliers: */

-- (STEP 1) table of top 3 profitable:

SELECT TOP 3 sp.CompanyName AS Most_Profitable, SUM(od.UnitPrice*od.Quantity) AS Total_Sells
FROM Products pr JOIN [Order Details] od
ON pr.ProductID = od.ProductID
JOIN Suppliers sp
ON pr.SupplierID = sp.SupplierID 
GROUP BY sp.CompanyName
ORDER BY Total_sells desc

-- (STEP 2) table of least 3 profitable:

SELECT TOP 3 sp.CompanyName AS Least_Profitable, SUM(od.UnitPrice*od.Quantity) AS Total_Sells
FROM Products pr JOIN [Order Details] od
ON pr.ProductID = od.ProductID
JOIN Suppliers sp
ON pr.SupplierID = sp.SupplierID 
GROUP BY sp.CompanyName
ORDER BY Total_sells

/* what share of the total company's revenue takes each supplier
*/

-- (STEP 1) find the total sells for each supplier (sum of unitprice*quantity group by supplier)


SELECT 
s.CompanyName,
s.Country,
SUM(ord.unitprice*ord.quantity) as total_sup_sells, 
LEFT(
        CAST(CAST(SUM(ord.unitprice * ord.quantity) * 100.0 / 1354458.59 AS DECIMAL(10, 2)) AS VARCHAR),
        LEN(CAST(CAST(SUM(ord.unitprice * ord.quantity) * 100.0 / 1354458.59 AS DECIMAL(10, 2)) AS VARCHAR)) 
    ) + '%' AS revenue_share,
RANK() OVER (PARTITION BY Country ORDER BY SUM(ord.unitprice * ord.quantity) DESC) AS rank_in_country
FROM suppliers s 
JOIN products p
ON s.supplierID = p.supplierID
JOIN [Order Details]  ord
ON p.ProductID = ord.ProductID
GROUP BY s.Country, s.CompanyName
ORDER BY COUNTRY, SUM(ord.unitprice*ord.quantity) DESC

--TOP 6 suppliers constitutes about half of the total revenue.
--France is 20%, Germany is 14.5%, Australia is 13.6%
--USA has highest amount of suppliers but consists only 9.5%. 

/* lets get to know our customers, where are they from? where do we get the most orders?
*/


SELECT  c.Country, 
COUNT(o.orderid) as ord_count
FROM orders o LEFT JOIN customers c
ON c.customerid = o.customerid
JOIN [Order Details] od 
ON o.OrderID = od.OrderID
GROUP BY country
ORDER BY ord_count desc

--USA has the most orders

/* what are the top 25 selling products? */

SELECT TOP 25 p.productname, c.categoryname, COUNT(o.productid) AS total_sells,
   SUM(o.UnitPrice * o.Quantity) AS product_income
FROM products p JOIN Categories c
ON c.CategoryID = p.CategoryID
RIGHT JOIN [Order Details] o
ON o.ProductID = p.ProductID
GROUP BY  c.CategoryName, p.ProductName
ORDER BY total_sells DESC

SELECT TOP 25 p.productname, c.categoryname, COUNT(o.productid) AS total_sells,
   SUM(o.UnitPrice * o.Quantity) AS product_income
FROM products p JOIN Categories c
ON c.CategoryID = p.CategoryID
RIGHT JOIN [Order Details] o
ON o.ProductID = p.ProductID
GROUP BY  c.CategoryName, p.ProductName
ORDER BY product_income DESC

/* we get a different result when we change the ORDER BY value. 
when we want to check top selling by amount of sells, dairy products are the winners,
but when  we order it by product income, it is way more volatile.  */


/* how do orders distibuted through time? */


;with new1 as
(
SELECT OrderID, CustomerID, 
CAST(MONTH(Orderdate) as varchar) + '-' + CAST(YEAR(Orderdate) as varchar) AS newdate,
ROW_NUMBER () OVER (PARTITION BY CAST(MONTH(Orderdate) as varchar) + '-' + CAST(YEAR(Orderdate) as varchar)
ORDER BY CustomerID) AS date_count
FROM Orders
GROUP BY CustomerID, OrderID, OrderDate )

SELECT  newdate, COUNT (date_count) as orders_count
FROM new1
GROUP BY newdate
ORDER BY CONVERT(DATE, '01-' + newdate, 105)

/* sells through time, from the oldest to newest */

SELECT orderdate, SUM (order_value) AS order_value2
FROM (
SELECT  CAST(MONTH(o.OrderDate) as varchar) + '-'
+ CAST(YEAR(o.OrderDate) as varchar) AS orderdate,
(od.UnitPrice*od.Quantity) as order_value
FROM Orders as o INNER JOIN [Order Details] as od
ON o.OrderID = od.OrderID
) AS date_value
GROUP BY orderdate
ORDER BY orderdate


/* shippers distribution */

SELECT s.CompanyName, COUNT(o.shipvia) AS shipments_num
FROM Shippers s JOIN orders o
ON s.ShipperID = o.ShipVia
GROUP BY s.companyname 
ORDER BY shipments_num DESC

/* shipment time distribution and average */


SELECT orderid, LEFT(orderdate,11) as order_date,
CAST(DAY(ShippedDate - OrderDate) AS int) AS ship_time
FROM Orders 



SELECT orderid, 
CASE 
	WHEN RequiredDate < ShippedDate THEN 'Overdue'
	ELSE 'On Time'
	END
		AS delievery_status
FROM Orders
ORDER BY delievery_status
