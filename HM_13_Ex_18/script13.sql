/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

--Уровень изоляции: Read Commited (Чтение зафиксированных данных).
--Тут всё зависит от преследуемой цели. Если нам нужно поискать этого клиента где-то в рхивах данных, то подойдет и второй уровень изоляции
--Если каким-то образом прямо во время транзакции происходит подсчет наибольшей суммы покупки для всех клиентов и мы хотим в конце получить
	--клиента с максимумом да еще и строго к текущему моменту времени, то лучше использовать Serializable (Сериализуемый)

CREATE OR ALTER FUNCTION dbo.GetCustomerWithMaxOrder()  
RETURNS int  

AS  
BEGIN
	 DECLARE @maxPrice decimal;
     DECLARE @Customer int; 
	 
	 SET @maxPrice = (select
		max (InvoiceLines.Quantity * InvoiceLines.UnitPrice) as Price
		from
		Sales.InvoiceLines 
		LEFT JOIN Sales.Invoices on Invoices.InvoiceID = InvoiceLines.InvoiceID
		LEFT JOIN Sales.Customers on Customers.CustomerID = Invoices.CustomerID);

     SET @Customer= (select top 1
		Customers.CustomerID
		from
		Sales.InvoiceLines 
		LEFT JOIN Sales.Invoices on Invoices.InvoiceID = InvoiceLines.InvoiceID
		LEFT JOIN Sales.Customers on Customers.CustomerID = Invoices.CustomerID
		where (InvoiceLines.Quantity * InvoiceLines.UnitPrice) = @maxPrice);  

     RETURN(@Customer);  
END;  

--использование
SELECT  dbo.GetCustomerWithMaxOrder() as IdCustomer;

--проверка
select top 1
Customers.CustomerID
from
Sales.InvoiceLines 
LEFT JOIN Sales.Invoices on Invoices.InvoiceID = InvoiceLines.InvoiceID
LEFT JOIN Sales.Customers on Customers.CustomerID = Invoices.CustomerID
order by (InvoiceLines.Quantity * InvoiceLines.UnitPrice) desc

/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

--Уровень изоляции: Read Commited (Чтение зафиксированных данных).
--Если эта функция будет использоваться где-то в отчете в режиме runtime, то можно рассмотреть и Repeatable Read (Повторяемое чтение)
CREATE OR ALTER PROCEDURE dbo.Get_SumOrder  @СustomerID int   

AS   
BEGIN
	--Без вывода информации о затронутых строках
    SET NOCOUNT ON; 
	
	select sum(InvoiceLines.Quantity * InvoiceLines.UnitPrice)
 as SumPrice
from
Sales.InvoiceLines 
LEFT JOIN Sales.Invoices on Invoices.InvoiceID = InvoiceLines.InvoiceID
LEFT JOIN Sales.Customers on Customers.CustomerID = Invoices.CustomerID
where Customers.CustomerID = @СustomerID

END
GO 


EXECUTE dbo.Get_SumOrder 894;

/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/
--Ддя каждого покупателя вывести разницу между самой максимальной покупкой в магазине и его максимальной покупки

--Уровень изоляции: Read Commited (Чтение зафиксированных данных).
CREATE OR ALTER FUNCTION dbo.GetPersonalDifferenceWithMaxOrder(@Customer INT)  
RETURNS int  

AS  
BEGIN
	 DECLARE @maxPrice decimal;
     DECLARE @difPrice decimal; 
	 
	 SET @maxPrice = (select
		max (InvoiceLines.Quantity * InvoiceLines.UnitPrice) as Price
		from
		Sales.InvoiceLines 
		LEFT JOIN Sales.Invoices on Invoices.InvoiceID = InvoiceLines.InvoiceID
		LEFT JOIN Sales.Customers on Customers.CustomerID = Invoices.CustomerID);

     SET @difPrice = (select (@maxPrice -  max(Sales.InvoiceLines.Quantity *InvoiceLines.UnitPrice))
		from
		Sales.InvoiceLines 
		LEFT JOIN Sales.Invoices on Invoices.InvoiceID = InvoiceLines.InvoiceID
		LEFT JOIN Sales.Customers on Customers.CustomerID = Invoices.CustomerID
		where Customers.CustomerID = @Customer);  

     RETURN(@difPrice);  
END;  

CREATE OR ALTER PROCEDURE dbo.GetPersonalDifferenceWithMaxOrderProcedure   

AS   
BEGIN
	--Без вывода информации о затронутых строках
    SET NOCOUNT ON; 
		 DECLARE @maxPrice decimal;
	 
	 SET @maxPrice = (select
		max (InvoiceLines.Quantity * InvoiceLines.UnitPrice) as Price
		from
		Sales.InvoiceLines 
		LEFT JOIN Sales.Invoices on Invoices.InvoiceID = InvoiceLines.InvoiceID
		LEFT JOIN Sales.Customers on Customers.CustomerID = Invoices.CustomerID);

		select CustomerId, (@maxPrice - Price) as diffPrice from
		(select Customers.CustomerID, max(Sales.InvoiceLines.Quantity *InvoiceLines.UnitPrice) as Price
		from
		Sales.Customers
		LEFT JOIN Sales.Invoices on Customers.CustomerID = Invoices.CustomerID 
		LEFT JOIN Sales.InvoiceLines on Invoices.InvoiceID = InvoiceLines.InvoiceID
		GROUP BY Customers.CustomerID) as t
		order by CustomerID

END
GO 

--Использование

select CustomerID, dbo.GetPersonalDifferenceWithMaxOrder(CustomerID) from Sales.Customers order by CustomerID;
EXEC dbo.GetPersonalDifferenceWithMaxOrderProcedure;

--Разница в производительности в том, что функция должна выполняться для каждой строки отдельно. 
--Таким образом получается множественный вызов одних и тех же вычислений
--Процедура производит вычисления сразу для всех.
/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/

--Уровень изоляции: Read Commited (Чтение зафиксированных данных).
CREATE OR ALTER FUNCTION dbo.GetTablePersonalDifferenceWithMaxOrder(@Customer INT)  
RETURNS Table 

AS
RETURN
(
with cte as(select
		max (InvoiceLines.Quantity * InvoiceLines.UnitPrice) as maxPrice
		from
		Sales.InvoiceLines 
		LEFT JOIN Sales.Invoices on Invoices.InvoiceID = InvoiceLines.InvoiceID
		LEFT JOIN Sales.Customers on Customers.CustomerID = Invoices.CustomerID) 

		select CustomerId, (cte.maxPrice - Price) as diffPrice from
		(select Customers.CustomerID, max(Sales.InvoiceLines.Quantity *InvoiceLines.UnitPrice) as Price
		from
		Sales.Customers
		LEFT JOIN Sales.Invoices on Customers.CustomerID = Invoices.CustomerID 
		LEFT JOIN Sales.InvoiceLines on Invoices.InvoiceID = InvoiceLines.InvoiceID
		where Customers.CustomerID = @Customer
		GROUP BY Customers.CustomerID) as t
		CROSS JOIN cte
); 


select Customers.CustomerID, func.diffPrice
from Sales.Customers
CROSS APPLY dbo.GetTablePersonalDifferenceWithMaxOrder(Customers.CustomerID) as func
order by  Customers.CustomerID;

--Уровень изоляции: Read Uncommited (Грязное чтение). Здесь происходит большая выборка по архивным данным. Очень малнькая вероятность изменений этих данных.
CREATE OR ALTER FUNCTION dbo.GetInvoiceLinesForDates (@Customer INT, @DateStart Date, @DateEnd Date)  
RETURNS Table 

AS
RETURN
(
select Customers.CustomerID, (Sales.InvoiceLines.Quantity *InvoiceLines.UnitPrice) as Price
		from
		Sales.Customers
		LEFT JOIN Sales.Invoices on Customers.CustomerID = Invoices.CustomerID 
		LEFT JOIN Sales.InvoiceLines on Invoices.InvoiceID = InvoiceLines.InvoiceID
		where Customers.CustomerID = @Customer
		and InvoiceDate between @DateStart AND @DateEnd
); 

select Customers.CustomerID, func.Price
from Sales.Customers
CROSS APPLY dbo.GetInvoiceLinesForDates(Customers.CustomerID, '2013-01-01', '2013-03-01') as func
order by  Customers.CustomerID;

/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/
--Комментарий приложен к каждому запросу