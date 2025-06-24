/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

INSERT INTO [Purchasing].[Suppliers](
    [SupplierName],
    [SupplierCategoryID],
    [PrimaryContactPersonID],
    [AlternateContactPersonID],
    --[DeliveryMethodID],
    [DeliveryCityID],
    [PostalCityID],
    [SupplierReference],
    --[BankAccountName],
    --[BankAccountBranch],
    --[BankAccountCode],
    --[BankAccountNumber],
    --[BankInternationalCode],
    [PaymentDays],
    [InternalComments],
    [PhoneNumber],
    [FaxNumber],
    [WebsiteURL],
    [DeliveryAddressLine1],
    [DeliveryAddressLine2],
    [DeliveryPostalCode],
    [DeliveryLocation],
    [PostalAddressLine1],
    [PostalAddressLine2],
    [PostalPostalCode],
    [LastEditedBy]--,
    --[ValidFrom],
    --[ValidTo]
) VALUES (
    'Поставщик1', -- SupplierName
    7, -- SupplierCategoryID
    45, -- PrimaryContactPersonID
    46, -- AlternateContactPersonID
    --2, -- DeliveryMethodID
    30378, -- DeliveryCityID
    30378, -- PostalCityID
    '028034202', -- SupplierReference
    --'Имя банка', -- BankAccountName
    --'Отделение банка', -- BankAccountBranch
    --'Код банка', -- BankAccountCode
    --'Номер счета', -- BankAccountNumber
    --'Международный код', -- BankInternationalCode
    30, -- PaymentDays
    'InternalComments', -- InternalComments
    '+71234567890', -- PhoneNumber
    '+79876543210', -- FaxNumber
    'https://example.com', -- WebsiteURL
    'Адрес доставки 1', -- DeliveryAddressLine1
    'Адрес доставки 2', -- DeliveryAddressLine2
    '123456', -- DeliveryPostalCode
    0xE6100000010C529ACDE330E34240DFFB1BB4D79A5EC0, -- DeliveryLocation
    'Почтовый адрес 1', -- PostalAddressLine1
    'Почтовый адрес 2', -- PostalAddressLine2
    '654321', -- PostalPostalCode
    1--, -- LastEditedBy
);

INSERT INTO [Purchasing].[Suppliers](
    [SupplierName],
    [SupplierCategoryID],
    [PrimaryContactPersonID],
    [AlternateContactPersonID],
    --[DeliveryMethodID],
    [DeliveryCityID],
    [PostalCityID],
    [SupplierReference],
    --[BankAccountName],
    --[BankAccountBranch],
    --[BankAccountCode],
    --[BankAccountNumber],
    --[BankInternationalCode],
    [PaymentDays],
    [InternalComments],
    [PhoneNumber],
    [FaxNumber],
    [WebsiteURL],
    [DeliveryAddressLine1],
    [DeliveryAddressLine2],
    [DeliveryPostalCode],
    [DeliveryLocation],
    [PostalAddressLine1],
    [PostalAddressLine2],
    [PostalPostalCode],
    [LastEditedBy]--,
    --[ValidFrom],
    --[ValidTo]
) VALUES (
    N'Поставщик1', -- SupplierName
    7, -- SupplierCategoryID
    45, -- PrimaryContactPersonID
    46, -- AlternateContactPersonID
    --2, -- DeliveryMethodID
    30378, -- DeliveryCityID
    30378, -- PostalCityID
    '028034202', -- SupplierReference
    --'Имя банка', -- BankAccountName
    --'Отделение банка', -- BankAccountBranch
    --'Код банка', -- BankAccountCode
    --'Номер счета', -- BankAccountNumber
    --'Международный код', -- BankInternationalCode
    30, -- PaymentDays
    'InternalComments', -- InternalComments
    '+71234567890', -- PhoneNumber
    '+79876543210', -- FaxNumber
    'https://example.com', -- WebsiteURL
    N'Адрес доставки 1', -- DeliveryAddressLine1
    N'Адрес доставки 2', -- DeliveryAddressLine2
    '123456', -- DeliveryPostalCode
    0xE6100000010C529ACDE330E34240DFFB1BB4D79A5EC0, -- DeliveryLocation
    N'Почтовый адрес 1', -- PostalAddressLine1
    N'Почтовый адрес 2', -- PostalAddressLine2
    '654321', -- PostalPostalCode
    1--, -- LastEditedBy
);

INSERT INTO [Purchasing].[Suppliers](
    [SupplierName],
    [SupplierCategoryID],
    [PrimaryContactPersonID],
    [AlternateContactPersonID],
    [DeliveryMethodID],
    [DeliveryCityID],
    [PostalCityID],
    [SupplierReference],
    [BankAccountName],
    [BankAccountBranch],
    [BankAccountCode],
    [BankAccountNumber],
    [BankInternationalCode],
    [PaymentDays],
    [InternalComments],
    [PhoneNumber],
    [FaxNumber],
    [WebsiteURL],
    [DeliveryAddressLine1],
    [DeliveryAddressLine2],
    [DeliveryPostalCode],
    [DeliveryLocation],
    [PostalAddressLine1],
    [PostalAddressLine2],
    [PostalPostalCode],
    [LastEditedBy]--,
    --[ValidFrom],
    --[ValidTo]
) VALUES (
    N'Поставщик4', -- SupplierName
    7, -- SupplierCategoryID
    45, -- PrimaryContactPersonID
    46, -- AlternateContactPersonID
    2, -- DeliveryMethodID
    30378, -- DeliveryCityID
    30378, -- PostalCityID
    '028034202', -- SupplierReference
    N'Банк', -- BankAccountName
    N'Отделение банка', -- BankAccountBranch
    N'Код банка', -- BankAccountCode
    N'Номер счета', -- BankAccountNumber
    N'Международный код', -- BankInternationalCode
    30, -- PaymentDays
    'InternalComments', -- InternalComments
    '+71234567890', -- PhoneNumber
    '+79876543210', -- FaxNumber
    'https://example.com', -- WebsiteURL
    N'Адрес доставки 1', -- DeliveryAddressLine1
    N'Адрес доставки 2', -- DeliveryAddressLine2
    '123456', -- DeliveryPostalCode
    0xE6100000010C529ACDE330E34240DFFB1BB4D79A5EC0, -- DeliveryLocation
    N'Почтовый адрес 1', -- PostalAddressLine1
    N'Почтовый адрес 2', -- PostalAddressLine2
    '654321', -- PostalPostalCode
    1--, -- LastEditedBy
);
/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

DELETE FROM [Purchasing].[Suppliers]
WHERE SupplierID = 14;


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

UPDATE [Purchasing].[Suppliers]
SET 
    [SupplierName] = N'Новое название', 
    [PhoneNumber] = '+7999111111'
WHERE 
    [SupplierID] = 15; 

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

SELECT *
INTO #TempTable
FROM [Sales].[Customers]
WHERE CustomerID > 1059;

select * from #TempTable;
delete from #TempTable
where CustomerID = 1062;

INSERT INTO #TempTable (
    CustomerID,
    CustomerName,
    BillToCustomerID,
    CustomerCategoryID,
    BuyingGroupID,
    PrimaryContactPersonID,
    AlternateContactPersonID,
    DeliveryMethodID,
    DeliveryCityID,
    PostalCityID,
    CreditLimit,
    AccountOpenedDate,
    StandardDiscountPercentage,
    IsStatementSent,
    IsOnCreditHold,
    PaymentDays,
    PhoneNumber,
    FaxNumber,
    DeliveryRun,
    RunPosition,
    WebsiteURL,
    DeliveryAddressLine1,
    DeliveryAddressLine2,
    DeliveryPostalCode,
    DeliveryLocation,
    PostalAddressLine1,
    PostalAddressLine2,
    PostalPostalCode,
    LastEditedBy,
	ValidFrom,
	ValidTo
)
VALUES (
1062,
    N'Иванов Иван', -- CustomerName
    1044, -- BillToCustomerID
    3, -- CustomerCategoryID
    NULL, -- BuyingGroupID
    3244, -- PrimaryContactPersonID
    NULL, -- AlternateContactPersonID
    3, -- DeliveryMethodID
    21650, -- DeliveryCityID
    21650, -- PostalCityID
    5000.00, -- CreditLimit
    '2024-04-27', -- AccountOpenedDate
    5.000, -- StandardDiscountPercentage
    1, -- IsStatementSent (bit)
    0, -- IsOnCreditHold (bit)
    30, -- PaymentDays
    N'+777', -- PhoneNumber
    N'+78', -- FaxNumber
    N'R1', -- DeliveryRun
    N'P1', -- RunPosition
    N'http://example.com', -- WebsiteURL
    N'ул. Ленина, д. 1', -- DeliveryAddressLine1
    NULL, -- DeliveryAddressLine2
    N'123456', -- DeliveryPostalCode
    NULL, -- DeliveryLocation 
    N'ул. Ленина, д. 1', -- PostalAddressLine1
    NULL, -- PostalAddressLine2
    N'123456', -- PostalPostalCode
    1, -- LastEditedBy,
	'2016-05-07 00:00:00.0000000', --ValidFrom
	'2016-05-07 00:00:00.0000000' --ValidTo
);

UPDATE [Sales].[Customers]
SET 
    [FaxNumber] = '0000'
WHERE 
    [CustomerID] = 1060; 

MERGE INTO [Sales].[Customers] AS Target
USING #TempTable AS Source
ON Target.CustomerID = Source.CustomerID

WHEN MATCHED THEN
    UPDATE SET
        Target.CustomerName = Source.CustomerName,
        Target.BillToCustomerID = Source.BillToCustomerID,
        Target.CustomerCategoryID = Source.CustomerCategoryID,
        Target.BuyingGroupID = Source.BuyingGroupID,
        Target.PrimaryContactPersonID = Source.PrimaryContactPersonID,
        Target.AlternateContactPersonID = Source.AlternateContactPersonID,
        Target.DeliveryMethodID = Source.DeliveryMethodID,
        Target.DeliveryCityID = Source.DeliveryCityID,
        Target.PostalCityID = Source.PostalCityID,
        Target.CreditLimit = Source.CreditLimit,
        Target.AccountOpenedDate = Source.AccountOpenedDate,
        Target.StandardDiscountPercentage = Source.StandardDiscountPercentage,
        Target.IsStatementSent = Source.IsStatementSent,
        Target.IsOnCreditHold = Source.IsOnCreditHold,
        Target.PaymentDays = Source.PaymentDays,
        Target.PhoneNumber = Source.PhoneNumber,
        Target.FaxNumber = Source.FaxNumber,
        Target.DeliveryRun = Source.DeliveryRun,
        Target.RunPosition = Source.RunPosition,
        Target.WebsiteURL = Source.WebsiteURL,
        Target.DeliveryAddressLine1 = Source.DeliveryAddressLine1,
        Target.DeliveryAddressLine2 = Source.DeliveryAddressLine2,
        Target.DeliveryPostalCode = Source.DeliveryPostalCode,
        Target.PostalAddressLine1 = Source.PostalAddressLine1,
        Target.PostalAddressLine2 = Source.PostalAddressLine2,
        Target.PostalPostalCode = Source.PostalPostalCode,
        Target.LastEditedBy = Source.LastEditedBy

WHEN NOT MATCHED THEN
    INSERT (
        CustomerName,
        BillToCustomerID,
        CustomerCategoryID,
        BuyingGroupID,
        PrimaryContactPersonID,
        AlternateContactPersonID,
        DeliveryMethodID,
        DeliveryCityID,
        PostalCityID,
        CreditLimit,
        AccountOpenedDate,
        StandardDiscountPercentage,
        IsStatementSent,
        IsOnCreditHold,
        PaymentDays,
        PhoneNumber,
        FaxNumber,
        DeliveryRun,
        RunPosition,
        WebsiteURL,
        DeliveryAddressLine1,
        DeliveryAddressLine2,
        DeliveryPostalCode,
        DeliveryLocation,
        PostalAddressLine1,
        PostalAddressLine2,
        PostalPostalCode,
        LastEditedBy
    )
    VALUES (
        Source.CustomerName,
        Source.BillToCustomerID,
        Source.CustomerCategoryID,
        Source.BuyingGroupID,
        Source.PrimaryContactPersonID,
        Source.AlternateContactPersonID,
        Source.DeliveryMethodID,
        Source.DeliveryCityID,
        Source.PostalCityID,
        Source.CreditLimit,
        Source.AccountOpenedDate,
        Source.StandardDiscountPercentage,
        Source.IsStatementSent,
        Source.IsOnCreditHold,
        Source.PaymentDays,
        Source.PhoneNumber,
        Source.FaxNumber,
        Source.DeliveryRun,
        Source.RunPosition,
        Source.WebsiteURL,
        Source.DeliveryAddressLine1,
        Source.DeliveryAddressLine2,
        Source.DeliveryPostalCode,
        NULL, 
        Source.PostalAddressLine1,
        Source.PostalAddressLine2,
        Source.PostalPostalCode,
        Source.LastEditedBy
    );

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Warehouse.StockItemTransactions_bcp')
BEGIN
    SELECT * INTO WideWorldImporters.Warehouse.StockItemTransactions_bcp
    FROM WideWorldImporters.Warehouse.StockItemTransactions
    WHERE 1 = 1;

    ALTER TABLE Warehouse.StockItemTransactions_bcp
    ADD CONSTRAINT PK_Warehouse_StockItemTransactions_bcp PRIMARY KEY NONCLUSTERED
    (StockItemTransactionID ASC);
END;

--В консоль
bcp WideWorldImporters.Warehouse.StockItemTransactions_bcp out C:\Path\datafile5.csv -c -T

--bcp [WideWorldImporters].[Sales].[Customers] out "C:\Path\datafile.csv" -c -t, -T -S localhost

--Берем чисто схему
SELECT * INTO WideWorldImporters.Warehouse.StockItemTransactions_Copy
FROM WideWorldImporters.Warehouse.StockItemTransactions
WHERE 1 = 2;

BULK INSERT WideWorldImporters.Warehouse.StockItemTransactions_Copy
    FROM "C:\Path\datafile5.csv"
	WITH 
		(
		BATCHSIZE = 1000,
		DATAFILETYPE = 'char',
		FIELDTERMINATOR = '\t',
		ROWTERMINATOR ='\n',
		KEEPNULLS,
		TABLOCK
		);

		SELECT * 
FROM WideWorldImporters.Warehouse.StockItemTransactions_Copy;