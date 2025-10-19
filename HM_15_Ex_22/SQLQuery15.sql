
--1. Создание таблицы для хранения отчетов по клиентам
USE [WideWorldImporters];
CREATE TABLE dbo.ClientReports (
    -- Уникальный идентификатор отчета
    ReportID INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Идентификатор клиента (связь с таблицей Clients)
    CustomerID INT NOT NULL,
    
    -- Начало периода отчета
    PeriodStart DATE NOT NULL,
    
    -- Конец периода отчета
    PeriodEnd DATE NOT NULL,
    
    -- Количество заказов за период
    OrdersCount INT NOT NULL,
    
    -- Дата и время создания отчета
    ReportCreated DATETIME2 DEFAULT SYSDATETIME(),
    
    -- Обеспечиваем, чтобы дата окончания была не раньше даты начала
    CONSTRAINT CHK_PeriodDates CHECK (PeriodEnd >= PeriodStart),
    
    -- Количество заказов не может быть отрицательным
    CONSTRAINT CHK_OrdersCount CHECK (OrdersCount >= 0)
);

select * from ClientReports;

--2. Настройка брокера отправки сообщения

select name, is_broker_enabled
from sys.databases;

--Включить брокер
USE master
ALTER DATABASE WideWorldImporters
SET ENABLE_BROKER  WITH ROLLBACK IMMEDIATE; --NO WAIT --prod (в однопользовательском режиме!!! На проде так не нужно)

--Включаем техническую учтеку для управления БД
ALTER AUTHORIZATION    
   ON DATABASE::WideWorldImporters TO [sa];

--Включите это чтобы доверять сервисам без использования сертификатов когда работаем между различными 
--БД и инстансами(фактически говорим серверу, что этой БД можно доверять)
--Если мы открепим БД и вновь ее прикрепим, то это свойство сбросится в OFF
ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON;

CREATE MESSAGE TYPE
[//WWI/SB/RequestMessage]
VALIDATION=WELL_FORMED_XML; --служит исключительно для проверки, что данные соответствуют типу XML(но можно любой тип)

CREATE MESSAGE TYPE
[//WWI/SB/ReplyMessage]
VALIDATION=WELL_FORMED_XML; --служит исключительно для проверки, что данные соответствуют типу XML(но можно любой тип) 

--Создаем контракт(определяем какие сообщения в рамках этого контракта допустимы)
CREATE CONTRACT [//WWI/SB/Contract]
      ([//WWI/SB/RequestMessage]
         SENT BY INITIATOR,
       [//WWI/SB/ReplyMessage]
         SENT BY TARGET
      );


--Создаем ОЧЕРЕДЬ таргета с ручным режимом MAX_QUEUE_READERS = 0
CREATE QUEUE TargetQueueWWI WITH STATUS = ON 
                                       ,RETENTION = OFF 
									   ,POISON_MESSAGE_HANDLING (STATUS = OFF)
									   ,ACTIVATION (STATUS = ON 
									               ,PROCEDURE_NAME = dbo.ConfirmRequest
												   ,MAX_QUEUE_READERS = 0
												   ,EXECUTE AS OWNER 
												   ) ;
--и сервис таргета
CREATE SERVICE [//WWI/SB/TargetService]
       ON QUEUE TargetQueueWWI
       ([//WWI/SB/Contract]);

--то же для ИНИЦИАТОРА
CREATE QUEUE InitiatorQueueWWI WITH STATUS = ON 
                                       ,RETENTION = OFF 
									   ,POISON_MESSAGE_HANDLING (STATUS = OFF)
									   ,ACTIVATION (STATUS = ON 
									               ,PROCEDURE_NAME = dbo.GetReportOrder
												   ,MAX_QUEUE_READERS = 0
												   ,EXECUTE AS OWNER 
												   ) ;

CREATE SERVICE [//WWI/SB/InitiatorService]
       ON QUEUE InitiatorQueueWWI
       ([//WWI/SB/Contract]);



----
--3. Ручное тестирование
----
EXEC dbo.SendRequest
		@CustomerID = 832,
    @PeriodStart = '2013-01-01',
    @PeriodEnd = '2013-05-01';

-- Видим сообщение в таргете
SELECT CAST(message_body AS XML),*
FROM dbo.TargetQueueWWI;

--Вручную берем запрос из очереди
EXEC dbo.GetReportOrder;

--Видим результат в таблице
select * from [dbo].[ClientReports];

--Таргет опустел, видим строки в инициаторе
SELECT CAST(message_body AS XML),*
FROM dbo.InitiatorQueueWWI;

--Список диалогов
--6E3BEC7D-03AD-F011-AFB6-90E8684B199C	1	//WWI/SB/InitiatorService	//WWI/SB/TargetService	//WWI/SB/Contract	DISCONNECTED_INBOUND
--713BEC7D-03AD-F011-AFB6-90E8684B199C	0	//WWI/SB/TargetService	//WWI/SB/InitiatorService	//WWI/SB/Contract	CLOSED
SELECT conversation_handle, is_initiator, s.name as 'local service', 
far_service, sc.name 'contract', ce.state_desc
FROM sys.conversation_endpoints ce --представление диалогов(постепенно очищается) чтобы ее не переполнять - --НЕЛЬЗЯ ЗАВЕРШАТЬ ДИАЛОГ ДО ОТПРАВКИ ПЕРВОГО СООБЩЕНИЯ
LEFT JOIN sys.services s
ON ce.service_id = s.service_id
LEFT JOIN sys.service_contracts sc
ON ce.service_contract_id = sc.service_contract_id
ORDER BY conversation_handle;


----
--4. Полуавтоматическое тестирование
----

--Теперь поставим 1 для ридеров(очередь должна вызвать все процедуры автоматом)
ALTER QUEUE [dbo].[InitiatorQueueWWI] WITH STATUS = ON --OFF=очередь НЕ доступна(ставим если глобальные проблемы)
                                          ,RETENTION = OFF --ON=все завершенные сообщения хранятся в очереди до окончания диалога
										  ,POISON_MESSAGE_HANDLING (STATUS = OFF) --ON=после 5 ошибок очередь будет отключена
	                                      ,ACTIVATION (STATUS = ON --OFF=очередь не активирует ХП(в PROCEDURE_NAME)(ставим на время исправления ХП, но с потерей сообщений)  
										              ,PROCEDURE_NAME = dbo.ConfirmRequest
													  ,MAX_QUEUE_READERS = 1 --количество потоков(ХП одновременно вызванных) при обработке сообщений(0-32767)
													                         --(0=тоже не позовется процедура)(ставим на время исправления ХП, без потери сообщений) 
													  ,EXECUTE AS OWNER --учетка от имени которой запустится ХП
													  ) ;


ALTER QUEUE [dbo].[TargetQueueWWI] WITH STATUS = ON 
                                       ,RETENTION = OFF 
									   ,POISON_MESSAGE_HANDLING (STATUS = OFF)
									   ,ACTIVATION (STATUS = ON 
									               ,PROCEDURE_NAME = dbo.GetReportOrder
												   ,MAX_QUEUE_READERS = 1
												   ,EXECUTE AS OWNER 
												   ) ;

EXEC dbo.SendRequest
		@CustomerID = 803,
    @PeriodStart = '2013-01-01',
    @PeriodEnd = '2013-05-01';


	--Видим результат в таблице
select * from [dbo].[ClientReports];

--1	832	2013-01-01	2013-05-01	9	2025-10-19 18:53:21.0944137
--2	803	2013-01-01	2013-05-01	17	2025-10-19 19:00:03.2062146

--Список диалогов
--713BEC7D-03AD-F011-AFB6-90E8684B199C	0	//WWI/SB/TargetService	//WWI/SB/InitiatorService	//WWI/SB/Contract	CLOSED
--0D15C1AB-04AD-F011-AFB6-90E8684B199C	0	//WWI/SB/TargetService	//WWI/SB/InitiatorService	//WWI/SB/Contract	CLOSED

