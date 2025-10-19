USE [EventsBD];
--Проверяет доступность мастера в заданный период
CREATE OR ALTER FUNCTION fn_CheckMasterAvailability(
    @MasterId INT,
    @StartTime DATETIME2,
    @EndTime DATETIME2
)
RETURNS BIT
AS
BEGIN
    DECLARE @IsAvailable BIT = 1;
    
    IF EXISTS (
        SELECT 1 
        FROM Schedules s
        JOIN MastersClasses mc ON s.ClassId = mc.ClassId
        WHERE mc.MasterId = @MasterId
          AND ((s.DateTimeStartClass BETWEEN @StartTime AND @EndTime)
            OR (s.DateTimeEndClass BETWEEN @StartTime AND @EndTime)
            OR (@StartTime BETWEEN s.DateTimeStartClass AND s.DateTimeEndClass))
    )
    SET @IsAvailable = 0;
    
    RETURN @IsAvailable;
END;

--Возвращает количество свободных мест на мероприятие
CREATE FUNCTION dbo.fn_GetEventFreePlaces
(
    @EventId INT
)
RETURNS INT
AS
BEGIN
    DECLARE @FreePlaces INT;

    SELECT @FreePlaces = 
        e.MaxParticipants - 
        ISNULL((
            SELECT COUNT(*) 
            FROM [Order] o 
            WHERE o.EventId = e.EventId 
            AND o.StatusId IN (1
            )
        ), 0)
    FROM [Events] e
    WHERE e.EventId = @EventId;
    
    -- Защита от отрицательных значений и NULL
    RETURN CASE 
        WHEN @FreePlaces IS NULL THEN 0 
        WHEN @FreePlaces < 0 THEN 0 
        ELSE @FreePlaces 
    END;
END;

--Расчет стоимости мероприятия (опционально)
CREATE FUNCTION fn_CalculateEventCost(
    @EventId INT
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @TotalCost DECIMAL(18,2) = 0;
    
    -- Стоимость площадки
    SELECT @TotalCost = ISNULL(l.PayPerHour * DATEDIFF(HOUR, e.StartDate, e.EndDate), 0)
    FROM [Events] e
    LEFT JOIN Locations l ON e.LocationId = l.LocationId
    WHERE e.EventId = @EventId;
    
    -- Стоимость тренеров
    SELECT @TotalCost = @TotalCost + ISNULL(SUM(
        m.PayPerHour * DATEDIFF(HOUR, s.DateTimeStartClass, s.DateTimeEndClass)
    ), 0)
    FROM Schedules s
    JOIN MastersClasses mc ON s.ClassId = mc.ClassId
    JOIN Masters m ON mc.MasterId = m.MasterId
    WHERE s.EventId = @EventId;
    
    -- Стоимость организаторов
    SELECT @TotalCost = @TotalCost + ISNULL(SUM(
        u.PayPerHour * DATEDIFF(HOUR, e.StartDate, e.EndDate)
    ), 0)
    FROM EventOrganizers eo
    JOIN Users u ON eo.UserId = u.UserId
    JOIN [Events] e ON eo.EventId = e.EventId
    WHERE eo.EventId = @EventId AND u.IsActive = 1;
    
    RETURN @TotalCost;
END;