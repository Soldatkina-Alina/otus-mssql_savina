/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "13 - CLR".
*/

Варианты ДЗ (сделать любой один):

1) Взять готовую dll, подключить ее и продемонстрировать использование. 
Например, https://sqlsharp.com

2) Взять готовые исходники из какой-нибудь статьи, скомпилировать, подключить dll, продемонстрировать использование.
Например, 
https://www.sqlservercentral.com/articles/xlsexport-a-clr-procedure-to-export-proc-results-to-excel

https://www.mssqltips.com/sqlservertip/1344/clr-string-sort-function-in-sql-server/

https://habr.com/ru/post/88396/

3) Написать полностью свое (что-то одно):
* Тип: JSON с валидацией, IP / MAC - адреса, ...
* Функция: работа с JSON, ...
* Агрегат: аналог STRING_AGG, ...
* (любой ваш вариант)

Результат ДЗ:
* исходники (если они есть), желательно проект Visual Studio
* откомпилированная сборка dll
* скрипт подключения dll
* демонстрация использования


--ДЗ
--Взян код из https://habr.com/ru/post/88396/

exec sp_configure 'show advanced options', 1;
GO
reconfigure;

-- Проверить, включена ли CLR
SELECT name, value_in_use  
FROM sys.configurations  
WHERE name = 'clr enabled';

-- Включить CLR (если выключен)
EXEC sp_configure 'clr enabled', 1;
RECONFIGURE;

--Проверить уровень безопасности
SELECT name, value_in_use  
FROM sys.configurations  
WHERE name = 'clr strict security';

exec sp_configure 'clr strict security', 0 ;
RECONFIGURE;

--Подлкючение сборки
CREATE ASSEMBLY ClassLibrary1
FROM 'C:\Path\SplitStringLibrary.dll'
WITH PERMISSION_SET = SAFE;

GO

--Создание функции
CREATE OR ALTER FUNCTION [dbo].SplitStringCLR(@text [nvarchar](max), @delimiter [nchar](1))
RETURNS TABLE (
part nvarchar(max),
ID_ODER int
) WITH EXECUTE AS CALLER

AS 

EXTERNAL NAME ClassLibrary1.[SplitStringLibrary.UserDefinedFunctions].SplitString


--Использование
select * from SplitStringCLR('11,22,33,44', ',');
select part from [dbo].SplitStringCLR('11,22,33,44', ',');