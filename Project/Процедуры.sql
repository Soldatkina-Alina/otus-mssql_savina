--USE [EventsBD];
-- ������� ����������� ���������
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
        
        -- ������� �����/�������� ���������
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
        
        -- �������� ����������� ����
        DECLARE @FreeSpaces INT;
        SELECT @FreeSpaces = dbo.fn_GetEventFreePlaces(@EventId)
        
        IF @FreeSpaces <= 0
        BEGIN
            RAISERROR('��� ��������� ����', 16, 1);
            RETURN;
        END
        
        -- �����������
        IF @Price IS NULL
            SELECT @Price = BasePrice FROM [Events] WHERE EventId = @EventId;
        
		IF @Price IS NULL
			INSERT INTO [Order] (ParticipantId, EventId, FactPrice, DateOrder, StatusId)
        VALUES (@ParticipantId, @EventId, @Price, GETDATE(), 7); -- ������ "��������"
		ELSE
			INSERT INTO [Order] (ParticipantId, EventId, FactPrice, DateOrder, StatusId)
        VALUES (@ParticipantId, @EventId, @Price, GETDATE(), 6); -- ������ "�������� ������������� ������"

		DECLARE @NewOrderId INT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
        
        -- ���������� ������� ����������
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


--������� �������� �����������
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
        
        -- 1. ������� ���������� ������������ �� ��������� ����
        DECLARE @FreeOrganizerId INT;
        
        SELECT TOP 1 @FreeOrganizerId = u.UserId
        FROM Users u
        WHERE u.IsActive = 1
          AND NOT EXISTS (
              -- ���������, ��� ����������� �� ����� � ��� ���� ������� �������������
              SELECT 1 
              FROM EventOrganizers eo
              JOIN Events e ON eo.EventId = e.EventId
              WHERE eo.UserId = u.UserId
                AND CAST(e.StartDate AS DATE) = CAST(@EventDate AS DATE)
                AND e.StatusId NOT IN (
                    SELECT StatusId FROM Statuses 
                    WHERE Name IN ('���������')
                )
          )
        ORDER BY u.PayPerHour ASC; 
        
        -- ���� ��������� ������������� ���, ����� ������ ���������
        IF @FreeOrganizerId IS NULL
        BEGIN
            SELECT TOP 1 @FreeOrganizerId = UserId
            FROM Users 
            WHERE IsActive = 1
            ORDER BY PayPerHour ASC;
        END
        
        -- 2. ��������� ����������� ������� �� ��������� ����
        IF EXISTS (
            SELECT 1 
            FROM MastersClasses mc
            JOIN Schedules s ON mc.ClassId = s.ClassId
            JOIN Events e ON s.EventId = e.EventId
            WHERE mc.MasterId = @MasterId
              AND CAST(e.StartDate AS DATE) = CAST(@EventDate AS DATE)
              AND e.StatusId NOT IN (
                  SELECT StatusId FROM Statuses 
                  WHERE Name IN ('���������')
              )
        )
        BEGIN
            RAISERROR('������ ����� � ��������� ����', 16, 1);
            RETURN;
        END
        
        -- 3. ��������� ����������� ����� �� ��������� ����
        IF EXISTS (
            SELECT 1 
            FROM Events e
            WHERE e.LocationId = @LocationId
              AND CAST(e.StartDate AS DATE) = CAST(@EventDate AS DATE)
              AND e.StatusId NOT IN (
                  SELECT StatusId FROM Statuses 
                  WHERE Name IN ('���������', '��������')
              )
        )
        BEGIN
            RAISERROR('����� ������ � ��������� ����', 16, 1);
            RETURN;
        END
        
        -- 4. �������� ID ������� "�����������"
        DECLARE @PlanningStatusId INT;
        SELECT @PlanningStatusId = StatusId 
        FROM Statuses 
        WHERE Name = '��������';
        
        
        -- 5. ������� �����������
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
            N'������������� ��������� �����������',
            @EventDate, -- ������ �����������
            DATEADD(HOUR, 4, @EventDate), -- ����� ����������� (+4 ����)
            @LocationId,
            @BasePrice,
            @PlanningStatusId
        );
        
        DECLARE @NewEventId INT = SCOPE_IDENTITY();
        
        -- 6. ������� ������-����� ��� �����������
        INSERT INTO Classes (Title, Description)
        VALUES (
            @EventName + N' - �������� ������-�����',
            N'������������� ��������� ������-�����'
        );
        
        DECLARE @NewClassId INT = SCOPE_IDENTITY();
        
        -- 7. ��������� ������� �� ������-�����
        INSERT INTO MastersClasses (ClassId, MasterId)
        VALUES (@NewClassId, @MasterId);
        
        -- 8. ������� ���������� ��� ������-������
        DECLARE @ScheduledStatusId INT;
        SELECT @ScheduledStatusId = StatusId 
        FROM Statuses 
        WHERE Name = '��������';
        
        INSERT INTO Schedules (EventId, ClassId, DateTimeStartClass, DateTimeEndClass, StatusId)
        VALUES (
            @NewEventId,
            @NewClassId,
            @EventDate, 
            NULL,
            @ScheduledStatusId
        );
        
        -- 9. ��������� ������������ �� �����������
        INSERT INTO EventOrganizers (EventId, UserId)
        VALUES (@NewEventId, @FreeOrganizerId);
        
        COMMIT TRANSACTION;
        
        -- 10. ���������� ���������
        SELECT 
            @NewEventId as EventId,
            @EventName as EventName,
            @EventDate as EventDate,
            @LocationId as LocationId,
            @BasePrice as BasePrice,
            @FreeOrganizerId as AssignedOrganizerId,
            (SELECT FirstName + ' ' + ISNULL(SecondName, '') FROM Users WHERE UserId = @FreeOrganizerId) as OrganizerName,
            (SELECT FirstName + ' ' + ISNULL(SecondName, '') FROM Masters WHERE MasterId = @MasterId) as MasterName,
            '����������� ������� �������' as Message;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        
        -- ���������������� ������
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;