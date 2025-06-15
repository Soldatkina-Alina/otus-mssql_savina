/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/
select 
 InvoiceLines.InvoiceID, 
 Invoices.InvoiceDate, 
 CustomerId,
(select sum(il1.Quantity * il1.UnitPrice) 
from Sales.InvoiceLines il1
where il1.InvoiceID =  Invoices.InvoiceID) as ПростаСумма,

(select sum(il2.Quantity * il2.UnitPrice) 
from Sales.InvoiceLines il2
lEFT JOIN Sales.Invoices as inv on inv.InvoiceID = il2.InvoiceID
where MONTH( inv.InvoiceDate) <= MONTH( Invoices.InvoiceDate) and inv.InvoiceDate <= Invoices.InvoiceDate) as СуммаНарастающимИтогом
from Sales.Invoices
LEFT JOIN Sales.InvoiceLines on Invoices.InvoiceID = InvoiceLines.InvoiceID
where Invoices.InvoiceDate > '2014-12-31'
ORDER BY YEAR(Invoices.InvoiceDate), MONTH(Invoices.InvoiceDate);


/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

select 
 InvoiceLines.InvoiceID, 
 Invoices.InvoiceDate, 
 CustomerId,
 sum(Quantity * UnitPrice) over(partition by InvoiceLines.InvoiceID order by InvoiceLines.InvoiceID ) ПростаСуммаОконнаяФункция,
 sum(Quantity * UnitPrice) over(partition by Invoices.InvoiceDate  ) СуммаНарастающимИтогомОконнаяФункция
--(select sum(il1.Quantity * il1.UnitPrice) 
--from Sales.InvoiceLines il1
--where il1.InvoiceID =  Invoices.InvoiceID) as ПростаСумма,

--(select sum(il2.Quantity * il2.UnitPrice) 
--from Sales.InvoiceLines il2
--lEFT JOIN Sales.Invoices as inv on inv.InvoiceID = il2.InvoiceID
--where MONTH( inv.InvoiceDate) <= MONTH( Invoices.InvoiceDate) and inv.InvoiceDate <= Invoices.InvoiceDate) as СуммаНарастающимИтогом
from Sales.Invoices
LEFT JOIN Sales.InvoiceLines on Invoices.InvoiceID = InvoiceLines.InvoiceID
where Invoices.InvoiceDate > '2014-12-31'
ORDER BY YEAR(Invoices.InvoiceDate), MONTH(Invoices.InvoiceDate);

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

select * from (
	select distinct Месяц, StockItemID, КоличествоПроданного
	,dense_rank() over (partition by Месяц order by КоличествоПроданного desc) НомерПозиции from(
		select 
		MONTH(Invoices.InvoiceDate) as Месяц
		,InvoiceLines.StockItemID
		,StockItemName,
		Quantity,
		sum(Quantity) over(partition by InvoiceLines.StockItemID, MONTH(Invoices.InvoiceDate)) as КоличествоПроданного
		from
		Sales.InvoiceLines 
		LEFT JOIN Warehouse.StockItems on InvoiceLines.StockItemID = StockItems.StockItemID
		LEFT JOIN Sales.Invoices on Invoices.InvoiceID = InvoiceLines.InvoiceID
		where Invoices.InvoiceDate > '31-12-2015'
		and Invoices.InvoiceDate < '01-01-2017'
		) as t1) 
	as tt2
where НомерПозиции in(1,2)
order by Месяц, НомерПозиции, StockItemID


/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/
select 
StockItemName, 
Номер = ROW_NUMBER() OVER (PARTITION BY LEFT(StockItems.StockItemName , 1) ORDER BY StockItemName asc),
ОбщееКол = count(StockItemID) over(partition by 1), -- 1 просто символ для вывода общего количества
ПерваяБуква = LEFT(StockItemName, 1),
ОбщееКолПоПервойБукве = count(StockItemID) over(partition by LEFT(StockItemName, 1)),
StockItemID,
Следующая = LEAD(StockItemID) OVER (ORDER BY StockItemName),
Предыдущая = LAG(StockItemID) OVER (ORDER BY StockItemName),
Предыдущая2СтрокиНазад = LAG(StockItemName, 2) OVER (ORDER BY StockItemName),
Предыдущая2СтрокиНазадNotNull = isnull( LAG(StockItemName, 2) OVER (ORDER BY StockItemName), 'No items'),
TypicalWeightPerUnit,
ГруппаTypicalWeightPerUnit =  DENSE_RANK() OVER (ORDER BY TypicalWeightPerUnit),
РазделениеНа30Групп = NTILE(30) OVER (
ORDER BY TypicalWeightPerUnit) 
from Warehouse.StockItems
order by StockItemName, Номер asc;

/*
5. По каждому сотруднику выведите последнего клиента(CustomerId), которому сотрудник(AccountPersonId) что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

;with cte as(
		select 
		Customers.CustomerName,
		Customers.CustomerID,
		People.PersonID,
		People.FullName as AccountsPersonName,
		Invoices.InvoiceDate, 
		SUM(Quantity * UnitPrice) Summ,
		ROW_NUMBER() OVER (PARTITION BY People.PersonID ORDER BY Invoices.InvoiceDate DESC) AS RowNum
		from
		Sales.InvoiceLines 
		LEFT JOIN Sales.Invoices on Invoices.InvoiceID = InvoiceLines.InvoiceID
		LEFT JOIN Application.People  on People.PersonID = Invoices.SalespersonPersonID
		LEFT JOIN Sales.Customers on Customers.CustomerID = Invoices.CustomerID
		GROUP BY CustomerName, Customers.CustomerID, PersonID, People.FullName, InvoiceDate
)
select distinct CustomerID, CustomerName, PersonID, AccountsPersonName, Summ, InvoiceDate
from cte
WHERE RowNum = 1
ORDER BY AccountsPersonName, InvoiceDate DESC;
/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

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

--Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 