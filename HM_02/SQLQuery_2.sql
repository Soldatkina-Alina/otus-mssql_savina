-- �������� ���� ������
-- https://learn.microsoft.com/en-us/sql/samples/wide-world-importers-oltp-database-catalog?view=sql-server-ver16#tables

--1. ��� ������, � �������� ������� ���� "urgent" ��� �������� ���������� � "Animal"
SELECT * 
FROM Warehouse.StockItems
WHERE StockItemName like '%urgent%'
or StockItemName like 'Animal%';

--2.����������� (Suppliers), � ������� �� ���� ������� �� ������ ������ (PurchaseOrders).
SELECT *
FROM Purchasing.Suppliers sup
LEFT JOIN Purchasing.PurchaseOrders orders on sup.SupplierID = orders.SupplierID
WHERE orders.PurchaseOrderID is null;

--3.������ (Orders) � ����� ������ (UnitPrice) ����� 100$ ���� ����������� ������ (Quantity) ������ ����� 20 ����� 
--�������������� ����� ������������ ����� ������ (PickingCompletedWhen).
SELECT Orders.OrderID, cast( orlines.PickingCompletedWhen as date) as PickingCompletedWhen 
FROM Sales.Orders
LEFT JOIN Sales.OrderLines orlines on Orders.OrderID = orlines.OrderID
WHERE orlines.UnitPrice > 100
or orlines.Quantity > 20
and Orders.PickingCompletedWhen is not null
and orlines.PickingCompletedWhen is not null
GROUP BY Orders.OrderID, cast( orlines.PickingCompletedWhen as date) 
order by OrderID;

--3.1
SELECT DISTINCT Orders.OrderID, cast( Orders.PickingCompletedWhen as date) as PickingCompletedWhen 
FROM Sales.Orders
LEFT JOIN Sales.OrderLines orlines on Orders.OrderID = orlines.OrderID and cast( orlines.PickingCompletedWhen as date) = cast( Orders.PickingCompletedWhen as date)
WHERE orlines.UnitPrice > 100
or orlines.Quantity > 20
order by OrderID;

-- 3.2 ��� ����� �������� null � ���� ������
SELECT DISTINCT Orders.OrderID, cast( orlines.PickingCompletedWhen as date) as PickingCompletedWhen 
FROM Sales.Orders
LEFT JOIN Sales.OrderLines orlines on Orders.OrderID = orlines.OrderID
WHERE orlines.UnitPrice > 100
or orlines.Quantity > 20
order by OrderID;

--4. ������ ����������� (Purchasing.Suppliers), ������� ������ ���� ��������� (ExpectedDeliveryDate) � ������ 2013 ���� 
--� ��������� "Air Freight" ��� "Refrigerated Air Freight" (DeliveryMethodName) � ������� ��������� (IsOrderFinalized).
SELECT *
FROM Purchasing.PurchaseOrders
LEFT JOIN Application.DeliveryMethods on PurchaseOrders.DeliveryMethodID = DeliveryMethods.DeliveryMethodID
WHERE ExpectedDeliveryDate between '2013-01-01' AND '2013-01-31'
and DeliveryMethods.DeliveryMethodName IN ('Air Freight', 'Refrigerated Air Freight')
AND IsOrderFinalized = 1
ORDER by ExpectedDeliveryDate;

--5. ������ ��������� ������ (�� ���� �������) � ������ ������� � ������ ����������, ������� ������� ����� (SalespersonPerson). ������� ��� �����������.
SELECT top (10) Orders.OrderID, Customers.CustomerID, Customers.CustomerName, Application.People.PersonID, Application.People.FullName, OrderDate
FROM Sales.Orders
JOIN Sales.Customers on Orders.CustomerID = Customers.CustomerID
JOIN Application.People on Orders.SalespersonPersonID = People.PersonID
ORDER BY OrderDate desc

--5.1 ������ ��������� ������ ��� ������� �������
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


--6. ��� �� � ����� �������� � �� ���������� ��������, ������� �������� ����� "Chocolate frogs 250g"
SELECT Customers.CustomerID, Customers.CustomerName, Customers.PhoneNumber
FROM Sales.OrderLines
JOIN Warehouse.StockItems on OrderLines.StockItemID = StockItems.StockItemID
JOIN Sales.Orders on Orders.OrderID = OrderLines.OrderID
JOIN Sales.Customers on Orders.CustomerID = Customers.CustomerID
WHERE StockItemName like 'Chocolate frogs 250g'
GROUP BY Customers.CustomerID, Customers.CustomerName, Customers.PhoneNumber
ORDER BY CustomerName asc