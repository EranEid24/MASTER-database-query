# MASTER-database-query

WELCOME! 

This is my very first project, my main goal was playing with the data as i see it without any external intention.

In this project, i wanted to analyze few aspects of this particular dataset, but more important-ask business questions 
that will be meaningful to the business activity and retrieve the right data to answer it.

Queries were made with SQL Server and visualization was made with Google Sheets. 




#  lets get to know our customers!
## where are they from? where do we get the most orders?

****
`SELECT  c.Country, `

`COUNT(o.orderid) as ord_count`

`FROM orders o LEFT JOIN customers c`

`ON c.customerid = o.customerid`

`JOIN [Order Details] od `

`ON o.OrderID = od.OrderID`

`GROUP BY country`

<img width="394" alt="image" src="https://github.com/EranEid24/MASTER-database-query/assets/149265837/888aff0c-0dab-4d6e-b1b5-3ae97c57b3a0">

### --USA has the most orders

#  1) i wanted to reach all customers whose order is out of stock, so our customer service department can solve the situtaion.


## -- (STEP 1) here are all the orders which are out of stock:


`with No_Stock as (`

`SELECT od.OrderId, `

`p.ProductName, `

`od.UnitPrice,`

`od.Quantity,`

`od.UnitPrice * od.Quantity as order_value `

`FROM [Order Details] od JOIN Products p `

`ON od.ProductID = p.ProductID`

`WHERE UnitsInStock = 0 `

`AND `

`Discontinued = 0`

`)`

<img width="262" alt="image" src="https://github.com/EranEid24/MASTER-database-query/assets/149265837/c4323e50-26ea-46fa-8860-6b09ef3523c5">


## -- (STEP 2) here is the table of top 10 customers with their info, ranked by urgency:

`SELECT TOP 10 cu.CompanyName, cu.CustomerID, cu.ContactName, cu.Phone, ns.order_value, os.orderdate,`

`DENSE_RANK () over (ORDER BY os.orderdate) as Urgency`

`FROM Orders os JOIN No_Stock ns ON os.OrderID = ns.OrderID`

               `JOIN customers cu ON cu.CustomerID = os.CustomerID `

			   `ORDER BY urgency`

<img width="531" alt="Screenshot 2023-11-03 182647" src="https://github.com/EranEid24/MASTER-database-query/assets/149265837/8aa934d8-af54-4aa8-81db-4e2e1737db79">



 # 2) now i want to see the distribution of sells by each category, so we know which one is more profitable:


## -- (STEP 1) ID and CategoryID of the orders, joining products table and orders table: 
 

`;with crValue as (`

`SELECT pr.productid, pr.categoryid, ord.unitprice*ord.quantity AS Total_Value`

`FROM products pr INNER JOIN [Order Details] ord`

`ON pr.ProductID = ord.ProductID `

 `) `

<img width="159" alt="image" src="https://github.com/EranEid24/MASTER-database-query/assets/149265837/43a62b81-d88e-40b4-9dab-b80a07f556bd">


 -- (STEP 2) sum of total sells (crd.Total_Value), grouped by category:
 
`SELECT cr.CategoryName, SUM(crd.Total_Value) AS Total_Sells`

`FROM categories cr INNER JOIN crValue crd`

`ON cr.categoryid = crd.categoryid`

`GROUP BY  cr.CategoryName`

`ORDER BY Total_Sells desc`

## -- another way with joins

`SELECT cr.categoryname, SUM(od.unitprice*od.quantity) AS total_sells`

`FROM [Order Details] od JOIN Products pr`

`ON od.productid = pr.productid`

`JOIN Categories cr`

`ON cr.categoryid = pr.categoryid`

`GROUP BY cr.categoryname`

<img width="352" alt="image" src="https://github.com/EranEid24/MASTER-database-query/assets/149265837/0639458b-3a95-4df8-91d5-83f3ece00586">

# 3) company wants to stop cooperation with the 3 least profitable suppliers, 
# and accelerate cooperation with the top 3 profitable suppliers: 

## -- (STEP 1) table of top 3 profitable:

`SELECT TOP 3 sp.CompanyName AS Most_Profitable, SUM(od.UnitPrice*od.Quantity) AS Total_Sells`

`FROM Products pr JOIN [Order Details] od`

`ON pr.ProductID = od.ProductID`

`JOIN Suppliers sp`

`ON pr.SupplierID = sp.SupplierID `

`GROUP BY sp.CompanyName`

`ORDER BY SUM(od.UnitPrice*od.Quantity)`

<img width="208" alt="image" src="https://github.com/EranEid24/MASTER-database-query/assets/149265837/f3645529-70bf-4ea8-8d33-e5b5547de745">


## -- (STEP 2) table of least 3 profitable:

`SELECT TOP 3 sp.CompanyName AS Least_Profitable, SUM(od.UnitPrice*od.Quantity) AS Total_Sells`

`FROM Products pr JOIN [Order Details] od`

`ON pr.ProductID = od.ProductID`
`JOIN Suppliers sp`
`ON pr.SupplierID = sp.SupplierID `
`GROUP BY sp.CompanyName`

`ORDER BY SUM(od.UnitPrice*od.Quantity) `

<img width="184" alt="image" src="https://github.com/EranEid24/MASTER-database-query/assets/149265837/8ca4ed05-9a11-422b-a817-e50fd18406c1">


#  4) what share of the total company's revenue takes each supplier?


## -- (STEP 1) find the total sells for each supplier (sum of unitprice*quantity group by supplier)


`SELECT `
`s.CompanyName,` `s.Country,`

`SUM(ord.unitprice*ord.quantity) as total_sup_sells, 
`
`LEFT(`
        `CAST(CAST(SUM(ord.unitprice * ord.quantity) * 100.0 / 1354458.59 AS DECIMAL(10, 2)) AS VARCHAR),`

        `LEN(CAST(CAST(SUM(ord.unitprice * ord.quantity) * 100.0 / 1354458.59 AS DECIMAL(10, 2)) AS VARCHAR)) `
    `) + '%' AS revenue_share,`
`RANK() OVER (PARTITION BY Country ORDER BY SUM(ord.unitprice * ord.quantity) DESC) AS rank_in_country`

`FROM suppliers s `
`JOIN products p`

`ON s.supplierID = p.supplierID`

`JOIN [Order Details]  ord`

`ON p.ProductID = ord.ProductID`

`GROUP BY s.Country, s.CompanyName`

<img width="391" alt="image" src="https://github.com/EranEid24/MASTER-database-query/assets/149265837/b820dab0-d392-467a-b6bd-87cc33379e45"> <img width="422" alt="image" src="https://github.com/EranEid24/MASTER-database-query/assets/149265837/16a1cd3a-4c06-426d-ad7f-5b3cddccd14e">


### --TOP 6 suppliers constitutes about half of the total revenue.
### --France is 21.9%, Germany is 14.5%, Australia is 13.6%
### --USA has highest amount of suppliers but consists only 9.5%. 


#  what are the top 25 selling products? 

`SELECT TOP 25 p.productname, c.categoryname, COUNT(o.productid) AS total_sells,`

   `SUM(o.UnitPrice * o.Quantity) AS product_income`

`FROM products p JOIN Categories c`

`ON c.CategoryID = p.CategoryID`

`RIGHT JOIN [Order Details] o`

`ON o.ProductID = p.ProductID`

`GROUP BY  c.CategoryName, p.ProductName`

`ORDER BY total_sells DESC`

<img width="328" alt="image" src="https://github.com/EranEid24/MASTER-database-query/assets/149265837/47f72bc1-fd58-406f-9072-a313f7870ffb">

### we get a different result when we change the ORDER BY value. 
### when we want to check top selling by amount of sells, dairy products are the winners,
### but when  we order it by product income, it is way more volatile.  


 # how do orders distributed through time? 

`with new1 as`
`(`

`SELECT OrderID, CustomerID, `

`CAST(MONTH(Orderdate) as varchar) + '-' + CAST(YEAR(Orderdate) as varchar) AS newdate,`

`ROW_NUMBER () OVER (PARTITION BY CAST(MONTH(Orderdate) as varchar) + '-' + CAST(YEAR(Orderdate) as varchar)`

`ORDER BY CustomerID) AS date_count`

`FROM Orders`

`GROUP BY CustomerID, OrderID, OrderDate )`

`SELECT  newdate, COUNT (date_count) as orders_count`

`FROM new1`

`GROUP BY newdate`

<img width="398" alt="image" src="https://github.com/EranEid24/MASTER-database-query/assets/149265837/130f12ac-d292-4c7d-b685-95ef7c90cea8">


#  sells through time, from the oldest to newest 

`SELECT orderdate, SUM (order_value) AS order_value2`

`FROM (` `SELECT  CAST(MONTH(o.OrderDate) as varchar) + '-'`

`+ CAST(YEAR(o.OrderDate) as varchar) AS orderdate,`

`(od.UnitPrice*od.Quantity) as order_value`

`FROM Orders as o INNER JOIN [Order Details] as od`

`ON o.OrderID = od.OrderID`

`) AS date_value`

`GROUP BY orderdate`

<img width="395" alt="image" src="https://github.com/EranEid24/MASTER-database-query/assets/149265837/3832a8ae-7eed-454f-8f9c-0d49b912d1c7">


# shippers distribution 

`SELECT s.CompanyName, COUNT(o.shipvia) AS shipments_num`

`FROM Shippers s JOIN orders o`

`ON s.ShipperID = o.ShipVia`

`GROUP BY s.companyname `

<img width="395" alt="image" src="https://github.com/EranEid24/MASTER-database-query/assets/149265837/8de835e6-50d4-4fdb-928d-29aea6cd78bf">


# shipment time distribution and average 

`with shiptimes as (`

`SELECT orderid, CAST(MONTH(orderdate) AS VARCHAR) + '/' + CAST(YEAR(orderdate) AS varchar) as order_date,`

`CAST(DAY(ShippedDate - OrderDate) AS int) AS ship_time,`

`CASE `

	`WHEN RequiredDate < ShippedDate THEN 'Overdue'`

	`ELSE 'On Time'`

	`END`

		`AS delievery_status`

`FROM Orders )`

`SELECT order_date,`

`AVG(ship_time) as average_ship_days`

`from Shiptimes`

`GROUP BY order_date`



<img width="398" alt="image" src="https://github.com/EranEid24/MASTER-database-query/assets/149265837/b97d20de-7758-402e-ad1f-7f3083097cae">


# is there a correlation between employee's territories and orders amount? 


`SELECT`
    `et.EmployeeID,`

    `COUNT(DISTINCT et.TerritoryID) AS territories,`

    `COUNT(DISTINCT od.OrderID) AS orders`

`FROM`
    `EmployeeTerritories et`

`JOIN`
    `Orders od ON et.EmployeeID = od.EmployeeID`

`GROUP BY`
    `et.EmployeeID`

<img width="399" alt="image" src="https://github.com/EranEid24/MASTER-database-query/assets/149265837/d0131b78-e029-4939-ace8-2a97c6488fe5">

### there is no direct correlation between number of territories and orders amount. 
