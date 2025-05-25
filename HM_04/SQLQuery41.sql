--��������� ������
SELECT
Invoices.InvoiceDate,
Invoices.InvoiceID,

(SELECT People.FullName
 FROM Application.People
 WHERE People.PersonID = Invoices.SalespersonPersonID
) AS SalesPersonName,
SalesTotals.TotalSumm AS TotalSummByInvoice,

(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
 FROM Sales.OrderLines
 WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
     FROM Sales.Orders
     WHERE Orders.PickingCompletedWhen IS NOT NULL    
         AND Orders.OrderId = Invoices.OrderId)    
) AS TotalSummForPickedItems

FROM Sales.Invoices
JOIN
(SELECT InvoiceId, SUM(Quantity * UnitPrice) AS TotalSumm
FROM Sales.InvoiceLines
GROUP BY InvoiceId
HAVING SUM(Quantity * UnitPrice) > 27000) AS SalesTotals
 ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC;


SELECT
--���������� ���������
Invoices.InvoiceID,
Invoices.InvoiceDate,
People.FullName,
SUM(InvoiceLines.Quantity * InvoiceLines.UnitPrice) AS TotalSumm,
TotalSummForPickedItems.TotalSummForPickedItems

FROM Sales.Invoices
LEFT JOIN Application.People on People.PersonID = Invoices.SalespersonPersonID
lEFT JOIN Sales.InvoiceLines on Invoices.InvoiceID = InvoiceLines.InvoiceID
lEFT JOIN (SELECT Orders.OrderId, SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice) TotalSummForPickedItems
 FROM Sales.OrderLines
 JOIN Sales.Orders on OrderLines.OrderId  = Orders.OrderID and Orders.PickingCompletedWhen IS NOT NULL  
 group by Orders.OrderId) as TotalSummForPickedItems on TotalSummForPickedItems.OrderID = Sales.Invoices.OrderID

GROUP BY Invoices.InvoiceId, Invoices.InvoiceDate, People.FullName, TotalSummForPickedItems.TotalSummForPickedItems
HAVING SUM(Quantity * UnitPrice) > 27000;
--ORDER BY TotalSumm DESC;

--����� �������� ������, �������� ���������� �� ������ ���������� �����
SELECT
--���������� �� ���������
Invoices.InvoiceID,
SUM(InvoiceLines.Quantity * InvoiceLines.UnitPrice) AS TotalSumm,
TotalSummForPickedItems.TotalSummForPickedItems

FROM Sales.Invoices
LEFT JOIN Application.People on People.PersonID = Invoices.SalespersonPersonID
lEFT JOIN Sales.InvoiceLines on Invoices.InvoiceID = InvoiceLines.InvoiceID
lEFT JOIN (SELECT Orders.OrderId, SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice) TotalSummForPickedItems
 FROM Sales.OrderLines
 JOIN Sales.Orders on OrderLines.OrderId  = Orders.OrderID and Orders.PickingCompletedWhen IS NOT NULL  
 group by Orders.OrderId) as TotalSummForPickedItems on TotalSummForPickedItems.OrderID = Sales.Invoices.OrderID

GROUP BY Invoices.InvoiceId, TotalSummForPickedItems.TotalSummForPickedItems
HAVING SUM(Quantity * UnitPrice) > 27000;

--���������� � CTE
;with TotalSummForPickedItems as (SELECT Orders.OrderId, SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice) sum
 FROM Sales.OrderLines
 JOIN Sales.Orders on OrderLines.OrderId  = Orders.OrderID and Orders.PickingCompletedWhen IS NOT NULL  
 group by Orders.OrderId
)
SELECT
Invoices.InvoiceID,
Invoices.InvoiceDate,
People.FullName,
SUM(InvoiceLines.Quantity * InvoiceLines.UnitPrice) AS TotalSumm,
TotalSummForPickedItems.sum
FROM Sales.Invoices
LEFT JOIN Application.People on People.PersonID = Invoices.SalespersonPersonID
lEFT JOIN Sales.InvoiceLines on Invoices.InvoiceID = InvoiceLines.InvoiceID
lEFT JOIN TotalSummForPickedItems on TotalSummForPickedItems.OrderID = Sales.Invoices.OrderID
GROUP BY Invoices.InvoiceId, Invoices.InvoiceDate, People.FullName, TotalSummForPickedItems.sum
HAVING SUM(Quantity * UnitPrice) > 27000
ORDER BY TotalSumm DESC;