/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.
������� "02 - �������� SELECT � ������� �������, GROUP BY, HAVING".

������� ����������� � �������������� ���� ������ WideWorldImporters.

����� �� ����� ������� ������:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
����� WideWorldImporters-Full.bak

�������� WideWorldImporters �� Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- ������� - �������� ������� ��� ��������� ��������� ���� ������.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. ��������� ������� ���� ������, ����� ����� ������� �� �������.
�������:
* ��� ������� (��������, 2015)
* ����� ������� (��������, 4)
* ������� ���� �� ����� �� ���� �������
* ����� ����� ������ �� �����

������� �������� � ������� Sales.Invoices � ��������� ��������.
*/

SELECT DATENAME(year, Orders.OrderDate) as ���, DATENAME(month, Orders.OrderDate) as �����, AVG(UnitPrice) as AvgUnitPrice, SUM(UnitPrice) as SumUnitPrice
FROM Sales.OrderLines
LEFT JOIN Sales.Orders on Orders.OrderID = OrderLines.OrderID
GROUP BY year(Orders.OrderDate), DATENAME(year, Orders.OrderDate),month(Orders.OrderDate), DATENAME(month, Orders.OrderDate)
ORDER BY year(Orders.OrderDate), month(Orders.OrderDate) asc;

--+����� �� �����
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
2. ���������� ��� ������, ��� ����� ����� ������ ��������� 4 600 000

�������:
* ��� ������� (��������, 2015)
* ����� ������� (��������, 4)
* ����� ����� ������

������� �������� � ������� Sales.Invoices � ��������� ��������.
*/

SELECT year(Orders.PickingCompletedWhen), month(Orders.PickingCompletedWhen), AVG(UnitPrice) as AvgUnitPrice, SUM(UnitPrice) as SumUnitPrice
FROM Sales.OrderLines
LEFT JOIN Sales.Orders on Orders.OrderID = OrderLines.OrderID
GROUP BY Rollup( year(Orders.PickingCompletedWhen),
month(Orders.PickingCompletedWhen))
HAVING SUM(UnitPrice) > 46000
ORDER BY year(Orders.PickingCompletedWhen), month(Orders.PickingCompletedWhen) asc;
/*
3. ������� ����� ������, ���� ������ �������
� ���������� ���������� �� �������, �� �������,
������� ������� ����� 50 �� � �����.
����������� ������ ���� �� ����,  ������, ������.

�������:
* ��� �������
* ����� �������
* ������������ ������
* ����� ������
* ���� ������ �������
* ���������� ����������

������� �������� � ������� Sales.Invoices � ��������� ��������.
*/
SELECT year(Orders.OrderDate) ���,
month(Orders.OrderDate) �����, StockItemName, SUM(OrderLines.UnitPrice) as AvgUnitPrice ,  MIN (Orders.OrderDate) ������_�������, SUM(Quantity) as Quantity
FROM Sales.OrderLines
LEFT JOIN Sales.Orders on Orders.OrderID = OrderLines.OrderID
LEFT JOIN Warehouse.StockItems on StockItems.StockItemID = OrderLines.StockItemID
GROUP BY  Rollup(year(Orders.OrderDate),
month(Orders.OrderDate), StockItemName)
HAVING SUM(Quantity) > 50
ORDER BY ���, ����� desc

-- ---------------------------------------------------------------------------
-- �����������
-- ---------------------------------------------------------------------------
/*
�������� ������� 2-3 ���, ����� ���� � �����-�� ������ �� ���� ������,
�� ���� ����� ����� ����������� �� � �����������, �� ��� ���� ����.
*/
