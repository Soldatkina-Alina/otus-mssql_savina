
--Для орагизотора
--1. Создание мероприятия → 2. Назначение организаторов → 3.Определение места → 4. Назначение тренеров →  5. Определение мастер-классов → 
--6. Формирование расписания → 6. Открытие регистрации → 
--7. Управление регистрациями → 8. Проведение мероприятия → 9. Завершение и отчет

--Для пользователя
--1. Выбор мероприятия по дате и направлению → 2. Проверка свободных мест → 3. Заполнение данных → 
--4. Оплата → 5. Подтверждение → 6. Получение информации о мероприятии

--select @@version

USE [EventsBD];
--Для организаторов

--Быстрое создание мероприятия
EXEC dbo.CreateEventProcedure 
    @EventName = N'Тестовое мероприятие',
    @EventDate = '2025-11-03 14:00:01',
    @MasterId = 1,
    @LocationId = 1,
    @BasePrice = 100;

	EXEC dbo.CreateEventProcedure 
    @EventName = N'Тестовое мероприятие_2',
    @EventDate = '2025-12-01 14:00:00',
    @MasterId = 1,
    @LocationId = 1,
    @BasePrice = NULL;

-- Пример выполнения полного цикла для участника

--Получаем направления
SELECT * FROM dbo.fn_GetAllChildDirections(4);

--Выбор мероприятия
DECLARE @SearchDate DATE = '2026-01-10';
DECLARE @DirectionId INT = 4; 

SELECT 
    e.EventId,
    e.EventName,
    e.StartDate,
    e.EndDate,
    e.BasePrice,
    l.LocationName
FROM [Events] e
INNER JOIN Locations l ON e.LocationId = l.LocationId
INNER JOIN Schedules s ON e.EventId = s.EventId
INNER JOIN Classes c ON s.ClassId = c.ClassId
LEFT JOIN dbo.fn_GetAllChildDirections(@DirectionId) d ON c.DirectionId = d.DirectionId
WHERE CAST(e.StartDate AS DATE) = CAST(@SearchDate AS DATE)
  AND 
  e.StatusId IN (
      SELECT StatusId FROM Statuses 
      WHERE Name IN ('Планируется', 'Открыта регистрация')
  );

--Количество свободных мест
SELECT dbo.fn_GetEventFreePlaces(1) as FreePlaces;

--Быстрая регистрация и оплата
DECLARE @Result NVARCHAR(20);
DECLARE @ParticipantId INT;
DECLARE @RemainingSpaces INT;

drop table #RegistrationResult
CREATE TABLE #RegistrationResult (
    Result NVARCHAR(20),
	NewOrderId INT,
    ParticipantId INT,
    RemainingSpaces INT

);

INSERT INTO #RegistrationResult (Result,NewOrderId, ParticipantId, RemainingSpaces)
EXEC FastParticipantRegistrationProcedure
@Email = 'mailUser5@mail.ru',
@EventId = 1,
@Price = 500;

        --SELECT ParticipantId 
        --FROM Participants WITH (INDEX(IX_Participants_Email))
        --WHERE Email = 'mailUser5@mail.ru';

DECLARE @NewOrderId INT;
SELECT @NewOrderId = NewOrderId FROM #RegistrationResult;
select RemainingSpaces from #RegistrationResult;
--Оплата, то есть изменение статуса
UPDATE [dbo].[Order]  SET [StatusId] = 7 WHERE OrderId = @NewOrderId and StatusId = 6

--Вывод расписания
DECLARE @EventId int = 1;

SELECT 
    s.ScheduleId,
    c.Title as ClassTitle,
    c.Description as ClassDescription,
    m.FirstName + ' ' + ISNULL(m.SecondName, '') as MasterName,
    s.DateTimeStartClass,
    s.DateTimeEndClass,
    DATEDIFF(MINUTE, s.DateTimeStartClass, s.DateTimeEndClass) as DurationMinutes,
    st.Name as StatusName,
    d.Title as DirectionName
FROM Schedules s
INNER JOIN Classes c ON s.ClassId = c.ClassId
INNER JOIN MastersClasses mc ON c.ClassId = mc.ClassId
INNER JOIN Masters m ON mc.MasterId = m.MasterId
INNER JOIN Statuses st ON s.StatusId = st.StatusId
LEFT JOIN Directions d ON c.DirectionId = d.DirectionId
WHERE s.EventId = @EventId
ORDER BY s.DateTimeStartClass;




