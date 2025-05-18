/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT DATENAME(year, Orders.OrderDate) as Год, DATENAME(month, Orders.OrderDate) as Месяц, AVG(UnitPrice) as AvgUnitPrice, SUM(UnitPrice) as SumUnitPrice
FROM Sales.OrderLines
LEFT JOIN Sales.Orders on Orders.OrderID = OrderLines.OrderID
GROUP BY year(Orders.OrderDate), DATENAME(year, Orders.OrderDate),month(Orders.OrderDate), DATENAME(month, Orders.OrderDate)
ORDER BY year(Orders.OrderDate), month(Orders.OrderDate) asc;

--+сумма по годам
SELECT 
year(Orders.OrderDate),
month(Orders.OrderDate), 
AVG(UnitPrice) as AvgUnitPrice, SUM(UnitPrice) as SumUnitPrice
FROM Sales.OrderLines
LEFT JOIN Sales.Orders on Orders.OrderID = OrderLines.OrderID
GROUP BY Rollup( 
year(Orders.OrderDate), 
month(Orders.OrderDate)
)
ORDER BY year(Orders.OrderDate), month(Orders.OrderDate) asc;


/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT year(Orders.OrderDate), month(Orders.OrderDate), AVG(InvoiceLines.UnitPrice) as AvgUnitPrice, SUM(OrderLines.Quantity* InvoiceLines.UnitPrice) as SumUnitPrice
FROM Sales.OrderLines
LEFT JOIN Sales.Orders on Orders.OrderID = OrderLines.OrderID
LEFT JOIN Sales.Invoices on Invoices.OrderID = Orders.OrderID
LEFT JOIN Sales.InvoiceLines on InvoiceLines.InvoiceID = Invoices.InvoiceID
GROUP BY Rollup( year(Orders.OrderDate),
month(Orders.OrderDate))
HAVING SUM(OrderLines.Quantity * InvoiceLines.UnitPrice) > 4600000
ORDER BY year(Orders.OrderDate), month(Orders.OrderDate) asc;
/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/
SELECT year(Orders.OrderDate) Год,
month(Orders.OrderDate) Месяц, StockItemName, 
SUM(OrderLines.Quantity * InvoiceLines.UnitPrice) as Сумма, 
MIN (Orders.OrderDate) Первая_продажа, 
SUM(OrderLines.Quantity) as Количество
FROM Sales.OrderLines
LEFT JOIN Sales.Orders on Orders.OrderID = OrderLines.OrderID
LEFT JOIN Warehouse.StockItems on StockItems.StockItemID = OrderLines.StockItemID
LEFT JOIN Sales.Invoices on Invoices.OrderID = Orders.OrderID
LEFT JOIN Sales.InvoiceLines on InvoiceLines.InvoiceID = Invoices.InvoiceID
GROUP BY  Rollup(year(Orders.OrderDate),
month(Orders.OrderDate), StockItemName)
HAVING SUM(OrderLines.Quantity * InvoiceLines.UnitPrice) > 50
ORDER BY Год, Месяц desc

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
