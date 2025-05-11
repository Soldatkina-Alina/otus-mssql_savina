-- Описание всех таблиц
-- https://learn.microsoft.com/en-us/sql/samples/wide-world-importers-oltp-database-catalog?view=sql-server-ver16#tables

--1. Все товары, в названии которых есть "urgent" или название начинается с "Animal"
SELECT * 
FROM Warehouse.StockItems
WHERE StockItemName like '%urgent%'
or StockItemName like 'Animal%';

--2.Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
SELECT *
FROM Purchasing.Suppliers sup
LEFT JOIN Purchasing.PurchaseOrders orders on sup.SupplierID = orders.SupplierID
WHERE orders.PurchaseOrderID is null;

--3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
--либо количеством единиц (Quantity) товара более 20 штук
--и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
--Вывести:
--* OrderID
--* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
--* название месяца, в котором был сделан заказ
--* номер квартала, в котором был сделан заказ
--* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
--* имя заказчика (Customer)
--Добавьте вариант этого запроса с постраничной выборкой,
--пропустив первую 1000 и отобразив следующие 100 записей.

--Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

--3.1
SELECT DISTINCT Orders.OrderID, 
CONVERT(VARCHAR(10), Orders.PickingCompletedWhen, 104) as Дата,
datename(month, Orders.PickingCompletedWhen) as "Месяц ", 
DATEADD(quarter, DATEDIFF(quarter, 0, Orders.PickingCompletedWhen), 0) AS StartOfQuarter,
CASE 
        WHEN DATEPART(month, Orders.PickingCompletedWhen) BETWEEN 1 AND 3 THEN 1
        WHEN DATEPART(month, Orders.PickingCompletedWhen) BETWEEN 4 AND 6 THEN 2
        WHEN DATEPART(month, Orders.PickingCompletedWhen) BETWEEN 7 AND 9 THEN 3
        ELSE 4
    END AS YearThird,
Orders.CustomerId
FROM Sales.Orders
LEFT JOIN Sales.OrderLines orlines on Orders.OrderID = orlines.OrderID and cast( orlines.PickingCompletedWhen as date) = cast( Orders.PickingCompletedWhen as date)
WHERE orlines.UnitPrice > 100
or orlines.Quantity > 20
order by StartOfQuarter, YearThird, Дата;

-- 3.2 Добавьте вариант этого запроса с постраничной выборкой,
--пропустив первую 1000 и отобразив следующие 100 записей.
DECLARE @pagesize BIGINT = 100, -- Размер страницы
	@pagenum BIGINT = 10;-- Номер страницы
SELECT DISTINCT Orders.OrderID, 
CONVERT(VARCHAR(10), Orders.PickingCompletedWhen, 104) as Дата,
datename(month, Orders.PickingCompletedWhen) as "Месяц ", 
DATEADD(quarter, DATEDIFF(quarter, 0, Orders.PickingCompletedWhen), 0) AS StartOfQuarter,
CASE 
        WHEN DATEPART(month, Orders.PickingCompletedWhen) BETWEEN 1 AND 3 THEN 1
        WHEN DATEPART(month, Orders.PickingCompletedWhen) BETWEEN 4 AND 6 THEN 2
        WHEN DATEPART(month, Orders.PickingCompletedWhen) BETWEEN 7 AND 9 THEN 3
        ELSE 4
    END AS YearThird,
Orders.CustomerId
FROM Sales.Orders
LEFT JOIN Sales.OrderLines orlines on Orders.OrderID = orlines.OrderID and cast( orlines.PickingCompletedWhen as date) = cast( Orders.PickingCompletedWhen as date)
WHERE orlines.UnitPrice > 100
or orlines.Quantity > 20
order by StartOfQuarter, YearThird, Дата DESC OFFSET(@pagenum - 1) * @pagesize ROWS 
FETCH NEXT @pagesize ROWS ONLY;

--4. Заказы поставщикам (Purchasing.Suppliers), которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года 
--с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName) и которые исполнены (IsOrderFinalized).
SELECT *
FROM Purchasing.PurchaseOrders
LEFT JOIN Application.DeliveryMethods on PurchaseOrders.DeliveryMethodID = DeliveryMethods.DeliveryMethodID
WHERE ExpectedDeliveryDate between '2013-01-01' AND '2013-01-31'
and DeliveryMethods.DeliveryMethodName IN ('Air Freight', 'Refrigerated Air Freight')
AND IsOrderFinalized = 1
ORDER by ExpectedDeliveryDate;

--5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника, который оформил заказ (SalespersonPerson). Сделать без подзапросов.
SELECT top (10) Orders.OrderID, Customers.CustomerID, Customers.CustomerName, Application.People.PersonID, Application.People.FullName, OrderDate
FROM Sales.Orders
JOIN Sales.Customers on Orders.CustomerID = Customers.CustomerID
JOIN Application.People on Orders.SalespersonPersonID = People.PersonID
ORDER BY OrderDate desc

--5.1 Десять последних продаж для каждого клиента
WITH RankedSales AS (
    SELECT 
        Orders.OrderID,
		Customers.CustomerName,
		People.FullName,
        OrderDate,
        ROW_NUMBER() OVER (PARTITION BY Orders.CustomerID ORDER BY OrderDate DESC) AS SaleRank
    FROM 
        Sales.Orders
    JOIN 
        Sales.Customers ON Orders.CustomerID = Customers.CustomerID
	JOIN Application.People on Orders.SalespersonPersonID = People.PersonID
)
SELECT 
        OrderID,
		CustomerName,
		FullName,
        OrderDate
FROM 
    RankedSales
WHERE 
    SaleRank <= 10
ORDER BY 
    CustomerName, 
    OrderDate DESC;


--6. Все ид и имена клиентов и их контактные телефоны, которые покупали товар "Chocolate frogs 250g"
SELECT Customers.CustomerID, Customers.CustomerName, Customers.PhoneNumber
FROM Sales.OrderLines
JOIN Warehouse.StockItems on OrderLines.StockItemID = StockItems.StockItemID
JOIN Sales.Orders on Orders.OrderID = OrderLines.OrderID
JOIN Sales.Customers on Orders.CustomerID = Customers.CustomerID
WHERE StockItemName like 'Chocolate frogs 250g'
GROUP BY Customers.CustomerID, Customers.CustomerName, Customers.PhoneNumber
ORDER BY CustomerName asc