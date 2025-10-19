
--1. �������� ������� ��� �������� ������� �� ��������
USE [WideWorldImporters];
CREATE TABLE dbo.ClientReports (
    -- ���������� ������������� ������
    ReportID INT IDENTITY(1,1) PRIMARY KEY,
    
    -- ������������� ������� (����� � �������� Clients)
    CustomerID INT NOT NULL,
    
    -- ������ ������� ������
    PeriodStart DATE NOT NULL,
    
    -- ����� ������� ������
    PeriodEnd DATE NOT NULL,
    
    -- ���������� ������� �� ������
    OrdersCount INT NOT NULL,
    
    -- ���� � ����� �������� ������
    ReportCreated DATETIME2 DEFAULT SYSDATETIME(),
    
    -- ������������, ����� ���� ��������� ���� �� ������ ���� ������
    CONSTRAINT CHK_PeriodDates CHECK (PeriodEnd >= PeriodStart),
    
    -- ���������� ������� �� ����� ���� �������������
    CONSTRAINT CHK_OrdersCount CHECK (OrdersCount >= 0)
);

select * from ClientReports;

--2. ��������� ������� �������� ���������

select name, is_broker_enabled
from sys.databases;

--�������� ������
USE master
ALTER DATABASE WideWorldImporters
SET ENABLE_BROKER  WITH ROLLBACK IMMEDIATE; --NO WAIT --prod (� �������������������� ������!!! �� ����� ��� �� �����)

--�������� ����������� ������ ��� ���������� ��
ALTER AUTHORIZATION    
   ON DATABASE::WideWorldImporters TO [sa];

--�������� ��� ����� �������� �������� ��� ������������� ������������ ����� �������� ����� ���������� 
--�� � ����������(���������� ������� �������, ��� ���� �� ����� ��������)
--���� �� �������� �� � ����� �� ���������, �� ��� �������� ��������� � OFF
ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON;

CREATE MESSAGE TYPE
[//WWI/SB/RequestMessage]
VALIDATION=WELL_FORMED_XML; --������ ������������� ��� ��������, ��� ������ ������������� ���� XML(�� ����� ����� ���)

CREATE MESSAGE TYPE
[//WWI/SB/ReplyMessage]
VALIDATION=WELL_FORMED_XML; --������ ������������� ��� ��������, ��� ������ ������������� ���� XML(�� ����� ����� ���) 

--������� ��������(���������� ����� ��������� � ������ ����� ��������� ���������)
CREATE CONTRACT [//WWI/SB/Contract]
      ([//WWI/SB/RequestMessage]
         SENT BY INITIATOR,
       [//WWI/SB/ReplyMessage]
         SENT BY TARGET
      );


--������� ������� ������� � ������ ������� MAX_QUEUE_READERS = 0
CREATE QUEUE TargetQueueWWI WITH STATUS = ON 
                                       ,RETENTION = OFF 
									   ,POISON_MESSAGE_HANDLING (STATUS = OFF)
									   ,ACTIVATION (STATUS = ON 
									               ,PROCEDURE_NAME = dbo.ConfirmRequest
												   ,MAX_QUEUE_READERS = 0
												   ,EXECUTE AS OWNER 
												   ) ;
--� ������ �������
CREATE SERVICE [//WWI/SB/TargetService]
       ON QUEUE TargetQueueWWI
       ([//WWI/SB/Contract]);

--�� �� ��� ����������
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
--3. ������ ������������
----
EXEC dbo.SendRequest
		@CustomerID = 832,
    @PeriodStart = '2013-01-01',
    @PeriodEnd = '2013-05-01';

-- ����� ��������� � �������
SELECT CAST(message_body AS XML),*
FROM dbo.TargetQueueWWI;

--������� ����� ������ �� �������
EXEC dbo.GetReportOrder;

--����� ��������� � �������
select * from [dbo].[ClientReports];

--������ �������, ����� ������ � ����������
SELECT CAST(message_body AS XML),*
FROM dbo.InitiatorQueueWWI;

--������ ��������
--6E3BEC7D-03AD-F011-AFB6-90E8684B199C	1	//WWI/SB/InitiatorService	//WWI/SB/TargetService	//WWI/SB/Contract	DISCONNECTED_INBOUND
--713BEC7D-03AD-F011-AFB6-90E8684B199C	0	//WWI/SB/TargetService	//WWI/SB/InitiatorService	//WWI/SB/Contract	CLOSED
SELECT conversation_handle, is_initiator, s.name as 'local service', 
far_service, sc.name 'contract', ce.state_desc
FROM sys.conversation_endpoints ce --������������� ��������(���������� ���������) ����� �� �� ����������� - --������ ��������� ������ �� �������� ������� ���������
LEFT JOIN sys.services s
ON ce.service_id = s.service_id
LEFT JOIN sys.service_contracts sc
ON ce.service_contract_id = sc.service_contract_id
ORDER BY conversation_handle;


----
--4. ������������������ ������������
----

--������ �������� 1 ��� �������(������� ������ ������� ��� ��������� ���������)
ALTER QUEUE [dbo].[InitiatorQueueWWI] WITH STATUS = ON --OFF=������� �� ��������(������ ���� ���������� ��������)
                                          ,RETENTION = OFF --ON=��� ����������� ��������� �������� � ������� �� ��������� �������
										  ,POISON_MESSAGE_HANDLING (STATUS = OFF) --ON=����� 5 ������ ������� ����� ���������
	                                      ,ACTIVATION (STATUS = ON --OFF=������� �� ���������� ��(� PROCEDURE_NAME)(������ �� ����� ����������� ��, �� � ������� ���������)  
										              ,PROCEDURE_NAME = dbo.ConfirmRequest
													  ,MAX_QUEUE_READERS = 1 --���������� �������(�� ������������ ���������) ��� ��������� ���������(0-32767)
													                         --(0=���� �� ��������� ���������)(������ �� ����� ����������� ��, ��� ������ ���������) 
													  ,EXECUTE AS OWNER --������ �� ����� ������� ���������� ��
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


	--����� ��������� � �������
select * from [dbo].[ClientReports];

--1	832	2013-01-01	2013-05-01	9	2025-10-19 18:53:21.0944137
--2	803	2013-01-01	2013-05-01	17	2025-10-19 19:00:03.2062146

--������ ��������
--713BEC7D-03AD-F011-AFB6-90E8684B199C	0	//WWI/SB/TargetService	//WWI/SB/InitiatorService	//WWI/SB/Contract	CLOSED
--0D15C1AB-04AD-F011-AFB6-90E8684B199C	0	//WWI/SB/TargetService	//WWI/SB/InitiatorService	//WWI/SB/Contract	CLOSED

