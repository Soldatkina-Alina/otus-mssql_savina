--1. Процедкра для отправки сообщения
CREATE OR ALTER PROCEDURE dbo.SendRequest
	@CustomerID INT,
    @PeriodStart DATE,
    @PeriodEnd DATE
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @InitDlgHandle UNIQUEIDENTIFIER;
	DECLARE @RequestMessage NVARCHAR(4000);
	
	BEGIN TRAN --на всякий случай в транзакции, т.к. это еще не относится к транзакции ПЕРЕДАЧИ сообщения

	--Формируем XML с корнем ReportRequest
	SELECT @RequestMessage =( SELECT 
					@CustomerID as CustomerID,
					@PeriodStart as PeriodStart,
					@PeriodEnd as PeriodEnd
				FOR XML PATH('ReportRequest')); 
	
	
	--Создаем диалог
	BEGIN DIALOG @InitDlgHandle
	FROM SERVICE
	[//WWI/SB/InitiatorService] --от этого сервиса(это сервис текущей БД, поэтому он НЕ строка)
	TO SERVICE
	'//WWI/SB/TargetService'    --к этому сервису(это сервис который может быть где-то, поэтому строка)
	ON CONTRACT
	[//WWI/SB/Contract]         --в рамках этого контракта
	WITH ENCRYPTION=OFF;        --не шифрованный

	--отправляем одно наше подготовленное сообщение, но можно отправить и много сообщений, которые будут обрабатываться строго последовательно)
	SEND ON CONVERSATION @InitDlgHandle 
	MESSAGE TYPE
	[//WWI/SB/RequestMessage]
	(@RequestMessage);
	
	--Это для визуализации - на проде это не нужно
	SELECT @RequestMessage AS SentRequestMessage;
	
	COMMIT TRAN 
END;


--2. Процедура для создания отчета

CREATE OR ALTER PROCEDURE dbo.GetReportOrder --будет получать сообщение на таргете
AS
BEGIN

	DECLARE @TargetDlgHandle UNIQUEIDENTIFIER,
			@Message NVARCHAR(4000),
			@MessageType Sysname,
			@ReplyMessage NVARCHAR(4000),
			@ReplyMessageName Sysname,
			@CustomerID INT,
			@PeriodStart DATE,
			@PeriodEnd DATE,
			@xml XML; 
	
	BEGIN TRAN; 

	--Получаем сообщение от инициатора которое находится у таргета
	RECEIVE TOP(1) --обычно одно сообщение, но можно пачкой
		@TargetDlgHandle = Conversation_Handle, --ИД диалога
		@Message = Message_Body, --само сообщение
		@MessageType = Message_Type_Name --тип сообщения( в зависимости от типа можно по разному обрабатывать) обычно два - запрос и ответ
	FROM dbo.TargetQueueWWI; --имя очереди которую мы ранее создавали

	SELECT @Message; --не для прода

	SET @xml = CAST(@Message AS XML);

	--достали всё из xml
	SELECT @CustomerID = @xml.value('(/ReportRequest/CustomerID )[1]', 'INT');
	SELECT @PeriodStart = @xml.value('(/ReportRequest/PeriodStart)[1]', 'DATE');
	SELECT @PeriodEnd = @xml.value('(/ReportRequest/PeriodEnd)[1]', 'DATE');

	IF EXISTS (SELECT * FROM Sales.Invoices WHERE CustomerID = @CustomerID)
	BEGIN
		 INSERT INTO dbo.ClientReports (CustomerID, PeriodStart, PeriodEnd, OrdersCount)
            SELECT 
                @CustomerID,
                @PeriodStart,
                @PeriodEnd,
                COUNT(*) 
            FROM Sales.Invoices 
            WHERE CustomerID = @CustomerID 
                AND InvoiceDate BETWEEN @PeriodStart AND @PeriodEnd;
	END;
	
	SELECT @Message AS ReceivedRequestMessage, @MessageType; --не для прода
	
	-- Confirm and Send a reply
	IF @MessageType=N'//WWI/SB/RequestMessage' --если наш тип сообщения
	BEGIN
		SET @ReplyMessage =N'<ReplyMessage> Message received</ReplyMessage>'; --ответ
	    --отправляем сообщение нами придуманное, что все прошло хорошо
		SEND ON CONVERSATION @TargetDlgHandle
		MESSAGE TYPE
		[//WWI/SB/ReplyMessage]
		(@ReplyMessage);
		END CONVERSATION @TargetDlgHandle; --А вот и завершение диалога!!! - оно двухстороннее(пока-пока) ЭТО первый ПОКА
		                                   --НЕЛЬЗЯ ЗАВЕРШАТЬ ДИАЛОГ ДО ОТПРАВКИ ПЕРВОГО СООБЩЕНИЯ
	END 
	
	SELECT @ReplyMessage AS SentReplyMessage; --не для прода - это для теста

	COMMIT TRAN;
END

--3. Процедура для подтверждения сообщения

CREATE OR ALTER PROCEDURE dbo.ConfirmRequest
AS
BEGIN
	--Receiving Reply Message from the Target.	
	DECLARE @InitiatorReplyDlgHandle UNIQUEIDENTIFIER,
			@ReplyReceivedMessage NVARCHAR(1000) 
	
	BEGIN TRAN; 

	    --Получаем сообщение от таргета которое находится у инициатора
		RECEIVE TOP(1)
			@InitiatorReplyDlgHandle=Conversation_Handle
			,@ReplyReceivedMessage=Message_Body
		FROM dbo.InitiatorQueueWWI; 
		
		END CONVERSATION @InitiatorReplyDlgHandle; --ЭТО второй ПОКА
		
		SELECT @ReplyReceivedMessage AS ReceivedRepliedMessage; --не для прода

	COMMIT TRAN; 
END