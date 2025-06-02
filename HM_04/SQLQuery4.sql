USE WideWorldImporters
--1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), и не сделали ни одной продажи 04 июля 2015 года. 
--Вывести ИД сотрудника и его полное имя. Продажи смотреть в таблице Sales.Invoices.

select People.PersonID, FullName, inv.SalespersonPersonID 
from Application.People
	left join (select Invoices.SalespersonPersonID, count(Invoices.InvoiceID) as c from Sales.Invoices
				left join Application.People on People.PersonID = Invoices.SalespersonPersonID
				where InvoiceDate = '2015-07-04'
				group by Invoices.SalespersonPersonID) as inv on People.PersonID = inv.SalespersonPersonID
where inv.SalespersonPersonID is null
and IsSalesperson = 1;


--2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
--Вывести: ИД товара, наименование товара, цена.
;
select InvoiceLines.StockItemID, StockItemName, InvoiceLines.UnitPrice from Sales.InvoiceLines
Left join Warehouse.StockItems on InvoiceLines.StockItemID = StockItems.StockItemID
where InvoiceLines.UnitPrice = (select min(UnitPrice) from Sales.InvoiceLines)
group by InvoiceLines.StockItemID, StockItemName,InvoiceLines.UnitPrice;

; WITH MinPrice AS (
	select min(UnitPrice) as price from Sales.InvoiceLines
	)
select InvoiceLines.StockItemID, StockItemName, InvoiceLines.UnitPrice from Sales.InvoiceLines
Left join Warehouse.StockItems on InvoiceLines.StockItemID = StockItems.StockItemID
JOIN MinPrice on MinPrice.price = InvoiceLines.UnitPrice
group by InvoiceLines.StockItemID, StockItemName,InvoiceLines.UnitPrice;

--3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей из Sales.CustomerTransactions. 
--Представьте несколько способов (в том числе с CTE).

select top(5) with ties CustomerTransactions.CustomerID, Customers.CustomerName, TransactionAmount 
from Sales.CustomerTransactions
LEFT JOIN Sales.Customers on CustomerTransactions.CustomerID = Customers.CustomerID
order by TransactionAmount desc;

;with MaxTrans As(
select top(5) with ties CustomerTransactions.CustomerID, TransactionAmount 
from Sales.CustomerTransactions
order by TransactionAmount desc
)
select * from Sales.Customers
JOIN MaxTrans on MaxTrans.CustomerID = Customers.CustomerID

--4. Выберите города (ид и название), в которые были доставлены товары, входящие в тройку самых дорогих товаров, 
--а также имя сотрудника, который осуществлял упаковку заказов (PackedByPersonID).

;with MaxPriceStock  AS (select top(3) with ties InvoiceLines.StockItemID
from Sales.InvoiceLines
group by InvoiceLines.StockItemID, UnitPrice
order by UnitPrice, InvoiceLines.StockItemID desc)

select Cities.CityName, People.FullName
fROM Sales.Invoices
LEFT JOIN Sales.InvoiceLines on Invoices.InvoiceID = InvoiceLines.InvoiceID
JOIN MaxPriceStock on InvoiceLines.StockItemID = MaxPriceStock.StockItemID
lEFT JOIN Application.People on People.PersonID = Invoices.PackedByPersonID
LEFT JOIN Sales.Customers on Customers.CustomerID = Invoices.CustomerID
LEFT JOIN Application.Cities on Cities.CityID = Customers.DeliveryCityID

GROUP BY Cities.CityName, People.FullName
