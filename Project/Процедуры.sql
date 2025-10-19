--USE [EventsBD];
-- Быстрая регистрация участника
CREATE OR ALTER PROCEDURE FastParticipantRegistrationProcedure
    @Email NVARCHAR(100),
    @EventId INT,
    @Price DECIMAL(18,2) = NULL
	
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
        BEGIN TRANSACTION;
        
        -- Быстрый поиск/создание участника
        DECLARE @ParticipantId INT;

        SELECT @ParticipantId = ParticipantId 
        FROM Participants WITH (INDEX(IX_Participants_Email))
        WHERE Email = @Email;

        IF @ParticipantId IS NULL
        BEGIN
            INSERT INTO Participants (Email)
            VALUES (@Email);
            SET @ParticipantId = SCOPE_IDENTITY();
        END
        
        -- Проверка доступности мест
        DECLARE @FreeSpaces INT;
        SELECT @FreeSpaces = dbo.fn_GetEventFreePlaces(@EventId)
        
        IF @FreeSpaces <= 0
        BEGIN
            RAISERROR('Нет свободных мест', 16, 1);
            RETURN;
        END
        
        -- Регистрация
        IF @Price IS NULL
            SELECT @Price = BasePrice FROM [Events] WHERE EventId = @EventId;
        
		IF @Price IS NULL
			INSERT INTO [Order] (ParticipantId, EventId, FactPrice, DateOrder, StatusId)
        VALUES (@ParticipantId, @EventId, @Price, GETDATE(), 7); -- Статус "Оплачено"
		ELSE
			INSERT INTO [Order] (ParticipantId, EventId, FactPrice, DateOrder, StatusId)
        VALUES (@ParticipantId, @EventId, @Price, GETDATE(), 6); -- Статус "Ожидание подтверждения оплаты"

		DECLARE @NewOrderId INT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
        
        -- Мгновенный возврат результата
        SELECT 
            'SUCCESS' as Result,
			@NewOrderId as NewOrderId,
            @ParticipantId as ParticipantId,
            @FreeSpaces - 1 as RemainingSpaces;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;


--Быстрое создание мероприятия
CREATE OR ALTER PROCEDURE dbo.CreateEventProcedure
    @EventName NVARCHAR(200),
    @EventDate DATETIME2,
    @MasterId INT,
    @LocationId INT,
    @BasePrice DECIMAL(18,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- 1. Находим свободного организатора на указанную дату
        DECLARE @FreeOrganizerId INT;
        
        SELECT TOP 1 @FreeOrganizerId = u.UserId
        FROM Users u
        WHERE u.IsActive = 1
          AND NOT EXISTS (
              -- Проверяем, что организатор не занят в эту дату другими мероприятиями
              SELECT 1 
              FROM EventOrganizers eo
              JOIN Events e ON eo.EventId = e.EventId
              WHERE eo.UserId = u.UserId
                AND CAST(e.StartDate AS DATE) = CAST(@EventDate AS DATE)
                AND e.StatusId NOT IN (
                    SELECT StatusId FROM Statuses 
                    WHERE Name IN ('Завершено')
                )
          )
        ORDER BY u.PayPerHour ASC; 
        
        -- Если свободных организаторов нет, берем любого активного
        IF @FreeOrganizerId IS NULL
        BEGIN
            SELECT TOP 1 @FreeOrganizerId = UserId
            FROM Users 
            WHERE IsActive = 1
            ORDER BY PayPerHour ASC;
        END
        
        -- 2. Проверяем доступность мастера на указанную дату
        IF EXISTS (
            SELECT 1 
            FROM MastersClasses mc
            JOIN Schedules s ON mc.ClassId = s.ClassId
            JOIN Events e ON s.EventId = e.EventId
            WHERE mc.MasterId = @MasterId
              AND CAST(e.StartDate AS DATE) = CAST(@EventDate AS DATE)
              AND e.StatusId NOT IN (
                  SELECT StatusId FROM Statuses 
                  WHERE Name IN ('Завершено')
              )
        )
        BEGIN
            RAISERROR('Мастер занят в указанную дату', 16, 1);
            RETURN;
        END
        
        -- 3. Проверяем доступность места на указанную дату
        IF EXISTS (
            SELECT 1 
            FROM Events e
            WHERE e.LocationId = @LocationId
              AND CAST(e.StartDate AS DATE) = CAST(@EventDate AS DATE)
              AND e.StatusId NOT IN (
                  SELECT StatusId FROM Statuses 
                  WHERE Name IN ('Завершено', 'Отменено')
              )
        )
        BEGIN
            RAISERROR('Место занято в указанную дату', 16, 1);
            RETURN;
        END
        
        -- 4. Получаем ID статуса "Планируется"
        DECLARE @PlanningStatusId INT;
        SELECT @PlanningStatusId = StatusId 
        FROM Statuses 
        WHERE Name = 'Черновик';
        
        
        -- 5. Создаем мероприятие
        INSERT INTO Events (
            EventName, 
            Description, 
            StartDate, 
            EndDate, 
            LocationId, 
            BasePrice, 
            StatusId
        )
        VALUES (
            @EventName,
            N'Автоматически созданное мероприятие',
            @EventDate, -- Начало мероприятия
            DATEADD(HOUR, 4, @EventDate), -- Конец мероприятия (+4 часа)
            @LocationId,
            @BasePrice,
            @PlanningStatusId
        );
        
        DECLARE @NewEventId INT = SCOPE_IDENTITY();
        
        -- 6. Создаем мастер-класс для мероприятия
        INSERT INTO Classes (Title, Description)
        VALUES (
            @EventName + N' - Основной мастер-класс',
            N'Автоматически созданный мастер-класс'
        );
        
        DECLARE @NewClassId INT = SCOPE_IDENTITY();
        
        -- 7. Назначаем мастера на мастер-класс
        INSERT INTO MastersClasses (ClassId, MasterId)
        VALUES (@NewClassId, @MasterId);
        
        -- 8. Создаем расписание для мастер-класса
        DECLARE @ScheduledStatusId INT;
        SELECT @ScheduledStatusId = StatusId 
        FROM Statuses 
        WHERE Name = 'Черновик';
        
        INSERT INTO Schedules (EventId, ClassId, DateTimeStartClass, DateTimeEndClass, StatusId)
        VALUES (
            @NewEventId,
            @NewClassId,
            @EventDate, 
            NULL,
            @ScheduledStatusId
        );
        
        -- 9. Назначаем организатора на мероприятие
        INSERT INTO EventOrganizers (EventId, UserId)
        VALUES (@NewEventId, @FreeOrganizerId);
        
        COMMIT TRANSACTION;
        
        -- 10. Возвращаем результат
        SELECT 
            @NewEventId as EventId,
            @EventName as EventName,
            @EventDate as EventDate,
            @LocationId as LocationId,
            @BasePrice as BasePrice,
            @FreeOrganizerId as AssignedOrganizerId,
            (SELECT FirstName + ' ' + ISNULL(SecondName, '') FROM Users WHERE UserId = @FreeOrganizerId) as OrganizerName,
            (SELECT FirstName + ' ' + ISNULL(SecondName, '') FROM Masters WHERE MasterId = @MasterId) as MasterName,
            'Мероприятие успешно создано' as Message;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        
        -- Детализированная ошибка
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;