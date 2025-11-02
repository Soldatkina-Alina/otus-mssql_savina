--создадим файловую группу
ALTER DATABASE [WideWorldImporters] ADD FILEGROUP [YearData]
GO

--добавляем файл БД
ALTER DATABASE [WideWorldImporters] ADD FILE 
( NAME = N'Years', FILENAME = N'C:\Path\Yeardata.ndf' , 
SIZE = 1097152KB , FILEGROWTH = 65536KB ) TO FILEGROUP [YearData]
GO
--[Sales].[Orders]
-- граничные точки
CREATE PARTITION FUNCTION [fnYearPartition](DATE) 
AS 
	RANGE RIGHT FOR VALUES ('20130101','20140101','20150101','20160101', '20160601');
GO

-- расположение секций 
CREATE PARTITION SCHEME [schmYearPartition] 
AS 
	PARTITION [fnYearPartition] ALL TO ([YearData])
GO




USE [WideWorldImporters]
--создадим новую секционированную таблицу
CREATE TABLE [Sales].[OrderLinesYears](
	[OrderLineID] [int] NOT NULL,
	[OrderID] [int] NOT NULL,
	[OrderDate] [date] NOT NULL, --новое поле для секционирования
	[StockItemID] [int] NOT NULL,
	[Description] [nvarchar](100) NOT NULL,
	[PackageTypeID] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
	[UnitPrice] [decimal](18, 2) NULL,
	[TaxRate] [decimal](18, 3) NOT NULL,
	[PickedQuantity] [int] NOT NULL,
	[PickingCompletedWhen] [datetime2](7) NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL,
) ON [schmYearPartition]([OrderDate])---в схеме [schmYearPartition] по ключу [OrderDate]
GO

--создадим кластерный индекс в той же схеме с ключом секционирования
ALTER TABLE [Sales].[OrderLinesYears] 
	ADD CONSTRAINT PK_Sales_OrderLinesYears 
	PRIMARY KEY CLUSTERED  (OrderDate, OrderId, OrderLineId) ON [schmYearPartition]([OrderDate]);

--то же самое для второй таблицы
CREATE TABLE [Sales].[OrderYears](
	[OrderID] [int] NOT NULL,
	[CustomerID] [int] NOT NULL,
	[SalespersonPersonID] [int] NOT NULL,
	[PickedByPersonID] [int] NULL,
	[ContactPersonID] [int] NOT NULL,
	[BackorderOrderID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[ExpectedDeliveryDate] [date] NOT NULL,
	[CustomerPurchaseOrderNumber] [nvarchar](20) NULL,
	[IsUndersupplyBackordered] [bit] NOT NULL,
	[Comments] [nvarchar](max) NULL,
	[DeliveryInstructions] [nvarchar](max) NULL,
	[InternalComments] [nvarchar](max) NULL,
	[PickingCompletedWhen] [datetime2](7) NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL,
) ON [schmYearPartition]([OrderDate])
GO

ALTER TABLE [Sales].[OrderYears] 
	ADD CONSTRAINT PK_Sales_OrderYears 
	PRIMARY KEY CLUSTERED  (OrderDate, OrderId) ON [schmYearPartition]([OrderDate]);
 

 exec master..xp_cmdshell 'bcp "select [OrderLineID],OrderLines.[OrderID],Orders.OrderDate,OrderLines.[StockItemID],[Description],[PackageTypeID],[Quantity],[UnitPrice],[TaxRate],[PickedQuantity],OrderLines.[PickingCompletedWhen],OrderLines.[LastEditedBy],OrderLines.[LastEditedWhen] FROM [WideWorldImporters].[Sales].[OrderLines] JOIN [WideWorldImporters].[Sales].[Orders] on Orders.OrderID = OrderLines.OrderID" queryout "C:\Path\OrderLines.txt" -T -w -t "@eu&$" -S localhost'
 exec master..xp_cmdshell 'bcp "[WideWorldImporters].Sales.Orders" out "C:\Path\Orders.txt" -T -w -t "@eu&$" -S  localhost'

 DECLARE 
	@path NVARCHAR(256) = N'C:\Path\',
	@FileName NVARCHAR(256) = N'OrderLines.txt',
	@onlyScript BIT = 0, 
	@query	NVARCHAR(MAX),
	@dbname NVARCHAR(255) = DB_NAME(),
	@batchsize INT = 1000;
	
BEGIN TRY
	IF @FileName IS NOT NULL
	BEGIN
		SET @query = 'BULK INSERT ['+@dbname+'].[Sales].[OrderLinesYears]
				FROM "' + @path + @FileName + '"
				WITH 
					(
					BATCHSIZE = '+CAST(@batchsize AS VARCHAR(255))+', 
					DATAFILETYPE = ''widechar'',
					FIELDTERMINATOR = ''@eu&$'',
					ROWTERMINATOR =''\n'',
					KEEPNULLS,
					TABLOCK        
					);'

		PRINT @query

		IF @onlyScript = 0
			EXEC sp_executesql @query 
		PRINT 'Bulk insert '+@FileName+' is done, current time '+CONVERT(VARCHAR, GETUTCDATE(),120);
	END;
END TRY

BEGIN CATCH
	SELECT   
		ERROR_NUMBER() AS ErrorNumber  
		,ERROR_MESSAGE() AS ErrorMessage; 

	PRINT 'ERROR in Bulk insert '+@FileName+' , current time '+CONVERT(VARCHAR, GETUTCDATE(),120);

END CATCH
	
select count(*) from Sales.OrderLinesYears



DECLARE 
	@path VARCHAR(256),
	@FileName VARCHAR(256),
	@onlyScript BIT, 
	@query	nVARCHAR(MAX),
	@dbname VARCHAR(255),
	@batchsize INT
	
	SELECT @dbname = DB_NAME();
	SET @batchsize = 1000;
	SET @onlyScript = 0
	SET @path = 'C:\Path\';
SET @FileName = 'Orders.txt';
BEGIN TRY

		IF @FileName IS NOT NULL
		BEGIN
			SET @query = 'BULK INSERT ['+@dbname+'].[Sales].[OrderYears]
				   FROM "'+@path+@FileName+'"
				   WITH 
					 (
						BATCHSIZE = '+CAST(@batchsize AS VARCHAR(255))+', 
						DATAFILETYPE = ''widechar'',
						FIELDTERMINATOR = ''@eu&$'',
						ROWTERMINATOR =''\n'',
						KEEPNULLS,
						TABLOCK        
					  );'

			PRINT @query

			IF @onlyScript = 0
				EXEC sp_executesql @query 
			PRINT 'Bulk insert '+@FileName+' is done, current time '+CONVERT(VARCHAR, GETUTCDATE(),120);
		END;
	END TRY

	BEGIN CATCH
		SELECT   
			ERROR_NUMBER() AS ErrorNumber  
			,ERROR_MESSAGE() AS ErrorMessage; 

		PRINT 'ERROR in Bulk insert '+@FileName+' , current time '+CONVERT(VARCHAR, GETUTCDATE(),120);

	END CATCH

select count(*) from Sales.OrderYears



set statistics time, io on
SELECT OrderYears.OrderID, OrderYears.OrderDate, Details.Quantity, Details.UnitPrice
FROM Sales.OrderYears 
JOIN Sales.OrderLinesYears AS Details ON OrderYears.OrderID = Details.OrderID AND OrderYears.OrderDate = Details.OrderDate
WHERE OrderYears.CustomerID = 1

-----Результат-----
/*Таблица "OrderLinesYears". Сканирований 129, логических операций чтения 737, физических операций чтения 20
Таблица "OrderYears". Сканирований 6, логических операций чтения 789, физических операций чтения 0 */

-- с фильтром
SELECT OrderYears.OrderID, OrderYears.OrderDate, Details.Quantity, Details.UnitPrice
FROM Sales.OrderYears 
JOIN Sales.OrderLinesYears AS Details ON OrderYears.OrderID = Details.OrderID AND OrderYears.OrderDate = Details.OrderDate
WHERE OrderYears.CustomerID = 1
	AND OrderYears.OrderDate > '20130101' AND OrderYears.OrderDate < '20130501'

-----Результат-----
/*Таблица "OrderLinesYears". Сканирований 11, логических операций чтения 50, физических операций чтения 0
Таблица "OrderYears". Сканирований 1, логических операций чтения 65, физических операций чтения 0*/