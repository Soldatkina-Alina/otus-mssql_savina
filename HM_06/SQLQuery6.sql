/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/
select FORMAT(InvoiceDate, 'dd.MM.yyyy') as InvoiceMonth ,[Tailspin Toys (Sylvanite, MT)], [Tailspin Toys (Peeples Valley, AZ)], [Tailspin Toys (Medicine Lodge, KS)],
[Tailspin Toys (Gasport, NY)], [Tailspin Toys (Jessie, ND)]
from (
	select Customers.CustomerName, Invoices.InvoiceID, datetrunc(month, InvoiceDate) as InvoiceDate
	from Sales.Invoices
	JOIN Sales.Customers on Invoices.CustomerID = Customers.CustomerID
	where Invoices.CustomerID > 2
and Invoices.CustomerID < 7
	)
as SourceTable
pivot 
(
count(InvoiceID)
for CustomerName
in ([Tailspin Toys (Sylvanite, MT)], [Tailspin Toys (Peeples Valley, AZ)], [Tailspin Toys (Medicine Lodge, KS)],
[Tailspin Toys (Gasport, NY)], [Tailspin Toys (Jessie, ND)])
)
as PivotTable
order by InvoiceDate asc;


/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

SELECT CustomerName, Address
FROM (
select CustomerName, DeliveryAddressLine1, DeliveryAddressLine2 from Sales.Customers
where CustomerName like 'Tailspin Toys%'
) AS src
UNPIVOT (
    Address FOR AddrType IN (DeliveryAddressLine1, DeliveryAddressLine2)
) AS unpvt
order by CustomerName;

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/
select CountryName, Code
FROM(
select CountryName, IsoAlpha3Code, CAST(IsoNumericCode AS nvarchar(3)) IsoNumericCode
from Application.Countries) AS src
UNPIVOT(
Code for IsoCode in(IsoAlpha3Code, IsoNumericCode)
) as unpvt
order by CountryName;
/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

select  LatestTransaction.InvoiceID,
		LatestTransaction.InvoiceLineID,
		LatestTransaction.StockItemID,
		LatestTransaction.CustomerID, 
		Cust.CustomerName,
		LatestTransaction.InvoiceDate, 
		LatestTransaction.Price
from
		Sales.Customers as Cust
		CROSS APPLY (
	select top 2 with ties Customers.CustomerID, (InvoiceLines.Quantity * InvoiceLines.UnitPrice) as Price,
	Invoices.InvoiceID,
		InvoiceLines.InvoiceLineID,
		InvoiceLines.StockItemID,
		Cust.CustomerName,
		Invoices.InvoiceDate
	from 		
	Sales.InvoiceLines 
	LEFT JOIN Sales.Invoices on Invoices.InvoiceID = InvoiceLines.InvoiceID
	LEFT JOIN Sales.Customers on Customers.CustomerID = Invoices.CustomerID
	LEFT JOIN Warehouse.StockItems on StockItems.StockItemID = InvoiceLines.StockItemID
	WHERE Invoices.CustomerID = Cust.CustomerID
	order by (InvoiceLines.Quantity * InvoiceLines.UnitPrice) desc
	) AS LatestTransaction
	order by CustomerID, LatestTransaction.Price;

	--Сравнение с Оконной функцией rank
	select distinct InvoiceID,CustomerID, CustomerName, InvoiceDate, Price, Rank
 from(
		select Invoices.InvoiceID,
		InvoiceLines.InvoiceLineID,
		InvoiceLines.StockItemID,
		Invoices.CustomerID, 
		Customers.CustomerName,
		Invoices.InvoiceDate, 
		InvoiceLines.Quantity * InvoiceLines.UnitPrice as Price,
		dense_rank() over (partition by Invoices.CustomerID order by InvoiceLines.Quantity * InvoiceLines.UnitPrice desc) as Rank
		from
		Sales.InvoiceLines 
		LEFT JOIN Sales.Invoices on Invoices.InvoiceID = InvoiceLines.InvoiceID
		LEFT JOIN Sales.Customers on Customers.CustomerID = Invoices.CustomerID
		LEFT JOIN Warehouse.StockItems on StockItems.StockItemID = InvoiceLines.StockItemID
		) as t
		where Rank < 3
order by CustomerID,Rank;
