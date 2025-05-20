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


-- +Месяца в которых нет продаж
select mm.value as dmonth, yy.value as dyear, ISNULL( AvgUnitPrice, 0) AvgUnitPrice, ISNULL( SumUnitPrice, 0) SumUnitPrice
from string_split('1 2 3 4 5 6 7 8 9 10 11 12', ' ') as mm
cross join string_split('2013 2014 2015 2016', ' ') as yy
LEFT JOIN (
SELECT year(Orders.OrderDate) tyear, month(Orders.OrderDate) tmonth, AVG(InvoiceLines.UnitPrice) as AvgUnitPrice, 
SUM(OrderLines.Quantity* InvoiceLines.UnitPrice) as SumUnitPrice
FROM Sales.OrderLines
LEFT JOIN Sales.Orders on Orders.OrderID = OrderLines.OrderID
LEFT JOIN Sales.Invoices on Invoices.OrderID = Orders.OrderID
LEFT JOIN Sales.InvoiceLines on InvoiceLines.InvoiceID = Invoices.InvoiceID
GROUP BY Rollup( year(Orders.OrderDate),
month(Orders.OrderDate))
HAVING SUM(OrderLines.Quantity * InvoiceLines.UnitPrice) > 8000000
) as t1 on t1.tyear = yy.value and t1.tmonth = mm.value
ORDER BY dyear, dmonth, t1.tyear, t1.tmonth asc
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
SELECT year(Invoices.InvoiceDate) Год,
month(Invoices.InvoiceDate) Месяц, StockItemName, 
SUM(InvoiceLines.Quantity * InvoiceLines.UnitPrice) as Сумма, 
MIN (Invoices.InvoiceDate) Первая_продажа, 
SUM(InvoiceLines.Quantity) as Количество
FROM 
Sales.Invoices  
LEFT JOIN Sales.InvoiceLines on InvoiceLines.InvoiceID = Invoices.InvoiceID
LEFT JOIN Warehouse.StockItems on InvoiceLines.StockItemID = StockItems.StockItemID
GROUP BY  Rollup(year(Invoices.InvoiceDate),
month(Invoices.InvoiceDate), StockItemName)
HAVING SUM(InvoiceLines.Quantity) < 50
ORDER BY Год, Месяц desc

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
