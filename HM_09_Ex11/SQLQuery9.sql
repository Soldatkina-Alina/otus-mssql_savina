/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/

DECLARE @xml NVARCHAR(MAX);
SELECT @xml = BulkColumn
FROM OPENROWSET(BULK 'C:\Path\StockItems-188-1fb5df.xml', SINGLE_CLOB) AS x;

DECLARE @docHandle INT;
-- Создаем временную структуру для OPENXML
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xml;

--Только запрос на получение данных
--SELECT *
--FROM OPENXML(@docHandle, 'StockItems/Item/Package')
--WITH 
--(
--[SupplierID] INT '../SupplierID',
--[ItemName] NVARCHAR(255) '../@Name',
--[LeadTimeDays] INT '../LeadTimeDays',
--[IsChillerStock] BIT '../IsChillerStock',
--[TaxRate] DECIMAL(5,3) '../TaxRate',
--[UnitPrice] DECIMAL(10,6) '../UnitPrice',
--UnitPackageID int 'UnitPackageID',
--OuterPackageID INT 'OuterPackageID',
--QuantityPerOuter int 'QuantityPerOuter',
--TypicalWeightPerUnit [decimal](18, 3) 'TypicalWeightPerUnit'

--);

MERGE INTO Warehouse.StockItems AS TargetTable
USING (
SELECT *
FROM OPENXML(@docHandle, 'StockItems/Item/Package')
WITH 
(
[SupplierID] INT '../SupplierID',
[ItemName] NVARCHAR(255) '../@Name',
[LeadTimeDays] INT '../LeadTimeDays',
[IsChillerStock] BIT '../IsChillerStock',
[TaxRate] DECIMAL(5,3) '../TaxRate',
[UnitPrice] DECIMAL(10,6) '../UnitPrice',
UnitPackageID int 'UnitPackageID',
OuterPackageID INT 'OuterPackageID',
QuantityPerOuter int 'QuantityPerOuter',
TypicalWeightPerUnit [decimal](18, 3) 'TypicalWeightPerUnit'
)
) AS Source
ON TargetTable.StockItemName = Source.ItemName
WHEN MATCHED THEN
    UPDATE SET
        SupplierID = Source.SupplierID,
        UnitPackageID = Source.UnitPackageID,
        OuterPackageID = Source.OuterPackageID,
        QuantityPerOuter = Source.QuantityPerOuter,
        TypicalWeightPerUnit = Source.TypicalWeightPerUnit,
        LeadTimeDays = Source.LeadTimeDays,
        IsChillerStock = Source.IsChillerStock,
        TaxRate = Source.TaxRate,
        UnitPrice = Source.UnitPrice

WHEN NOT MATCHED THEN
    INSERT (StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice, LastEditedBy)
    VALUES (Source.ItemName, Source.SupplierID, Source.UnitPackageID, Source.OuterPackageID, Source.QuantityPerOuter, Source.TypicalWeightPerUnit, Source.LeadTimeDays, Source.IsChillerStock, Source.TaxRate, Source.UnitPrice,1);


-- Освобождение документа
EXEC sp_xml_removedocument @docHandle;


-----------------------------------------------------
-----------------------------------------------------
-----------------------------------------------------


--Через XQuery
DECLARE @xml XML;
SELECT @xml = CAST(BulkColumn AS XML)
FROM OPENROWSET(BULK 'C:\Path\StockItems-188-1fb5df.xml', SINGLE_CLOB) AS x;
-- Вставка или обновление данных
MERGE INTO Warehouse.StockItems AS TargetTable
USING (
SELECT
    T.Item.value('@Name', 'VARCHAR(255)') AS ItemName,
    T.Item.value('SupplierID[1]', 'INT') AS SupplierID,
    T.Item.value('LeadTimeDays[1]', 'INT') AS LeadTimeDays,
    T.Item.value('IsChillerStock[1]', 'BIT') AS IsChillerStock,
    T.Item.value('TaxRate[1]', 'DECIMAL(5,3)') AS TaxRate,
    T.Item.value('UnitPrice[1]', 'DECIMAL(10,6)') AS UnitPrice,
    P.value('UnitPackageID[1]', 'INT') AS UnitPackageID,
    P.value('OuterPackageID[1]', 'INT') AS OuterPackageID,
    P.value('QuantityPerOuter[1]', 'INT') AS QuantityPerOuter,
    P.value('TypicalWeightPerUnit[1]', 'DECIMAL(10,3)') AS TypicalWeightPerUnit
FROM
    @xml.nodes('/StockItems/Item') AS T(Item)
	CROSS APPLY
    T.Item.nodes('Package') AS P(P)
) AS Source
ON TargetTable.StockItemName = Source.ItemName
WHEN MATCHED THEN
    UPDATE SET
        SupplierID = Source.SupplierID,
        UnitPackageID = Source.UnitPackageID,
        OuterPackageID = Source.OuterPackageID,
        QuantityPerOuter = Source.QuantityPerOuter,
        TypicalWeightPerUnit = Source.TypicalWeightPerUnit,
        LeadTimeDays = Source.LeadTimeDays,
        IsChillerStock = Source.IsChillerStock,
        TaxRate = Source.TaxRate,
        UnitPrice = Source.UnitPrice

WHEN NOT MATCHED THEN
    INSERT (StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice, LastEditedBy)
    VALUES (Source.ItemName, Source.SupplierID, Source.UnitPackageID, Source.OuterPackageID, Source.QuantityPerOuter, Source.TypicalWeightPerUnit, Source.LeadTimeDays, Source.IsChillerStock, Source.TaxRate, Source.UnitPrice,1);
/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

--Создание и вывод xml без сохранения в файл
SELECT
    (
        SELECT
            si.StockItemName AS '@Name',
            si.SupplierID,
            si.LeadTimeDays,
            si.IsChillerStock,
            si.TaxRate,
            si.UnitPrice,
            (
                SELECT
                    si.UnitPackageID AS 'UnitPackageID',
                    si.OuterPackageID AS 'OuterPackageID',
                    si.QuantityPerOuter AS 'QuantityPerOuter',
                    si.TypicalWeightPerUnit AS 'TypicalWeightPerUnit'
                FOR XML PATH('Package'), TYPE
            )
        FOR XML PATH('Item'), TYPE
    )
FROM Warehouse.StockItems si
FOR XML PATH('StockItems'), ROOT('StockItems'), TYPE;

--Сохранение в файл через cmd
bcp "SELECT (SELECT si.StockItemName AS '@Name', si.SupplierID, si.LeadTimeDays, si.IsChillerStock, si.TaxRate, si.UnitPrice, (SELECT si.UnitPackageID AS 'UnitPackageID', si.OuterPackageID AS 'OuterPackageID', si.QuantityPerOuter AS 'QuantityPerOuter', si.TypicalWeightPerUnit AS 'TypicalWeightPerUnit' FOR XML PATH('Package'), TYPE) FOR XML PATH('Item'), TYPE) FROM Warehouse.StockItems si FOR XML PATH('StockItems'), ROOT('StockItems'), TYPE;" queryout "C:\Path\file3.xml" -c -T -S localhost -d WideWorldImporters -t ";" -r "\n"

/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/


SELECT 
    StockItemID,
    JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture,
    JSON_VALUE(CustomFields, '$.Tags[0]') AS FirstTag
FROM 
    [Warehouse].[StockItems]
WHERE 
    ISJSON(CustomFields) = 1
    AND JSON_VALUE(CustomFields, '$.CountryOfManufacture') IS NOT NULL
    AND JSON_QUERY(CustomFields, '$.Tags') IS NOT NULL;


-- + все теги через запятую
SELECT 
    StockItemID,
    JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture,
    STRING_AGG(t.value, ',') AS AllTags
FROM 
    [Warehouse].[StockItems]
CROSS APPLY OPENJSON(JSON_QUERY(CustomFields, '$.Tags')) AS t
WHERE 
    ISJSON(CustomFields) = 1
	AND JSON_QUERY(CustomFields, '$.Tags') IS NOT NULL
GROUP BY
    StockItemID,
    JSON_VALUE(CustomFields, '$.CountryOfManufacture');

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/


SELECT 
    StockItemID,
    JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture,
    STRING_AGG(tag.value, ', ') AS AllTags
FROM 
    [Warehouse].[StockItems] 
CROSS APPLY OPENJSON(JSON_QUERY(CustomFields, '$.Tags')) AS tag
WHERE 
    ISJSON(CustomFields) = 1
    AND JSON_QUERY(CustomFields, '$.Tags') IS NOT NULL
    AND EXISTS (
        SELECT 1 
        FROM OPENJSON(JSON_QUERY(CustomFields, '$.Tags')) AS vintage_check
        WHERE vintage_check.value = 'Vintage'
    )
GROUP BY
    StockItemID,
    JSON_VALUE(CustomFields, '$.CountryOfManufacture');
