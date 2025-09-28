-- Возможные отчеты, процедуры и функции, для которых понадобятся индексы:

---Процедуры :
--1. EventRegistrationProcedure - Регистрация участника на мероприятие
		--Принимает @ParticipantId, @EventId. Проверяет свободные места, статус мероприятия, создает запись в таблице Order со статусом "Зарегистрирован" и текущей датой
--2. CreateEventProcedure - Создание нового мероприятия со всеми зависимостями
		--Принимает параметры мероприятия, список организаторов, расписание. В рамках транзакции создает запись в Events, затем записи в EventOrganizers и Schedules.
--3. CloseEventProcedure - Завершение мероприятия
		--Принимает @EventId. Меняет статус мероприятия на "Завершено". Может запускать расчеты по оплате для тренеров и площадки.
--4. GetMasterSheduleProcedure - Получение раписания одного мастера 
		--Принимает @MasterId.

--Функции:
--1.fn_GetEventFreePlaces - Возвращает количество свободных мест на мероприятии
		--Принимает @EventId. Возвращает Events.MaxParticipants - COUNT(Order.OrderId).
--2.fn_CheckMasterAvailability - Проверяет доступность мастера в заданный период
		--Принимает @MasterId, @StartDate, @EndDate. Возвращает булево значение ДА/НЕТ

--Отчеты
--1. Отчет по мероприятиям (Статус, место, кол-во участников, выручка)
--2. Финансовый отчет по тренерам/спикерам
--3. Отчет по занятости площадок за период
--4. Список участников конкретного мероприятия с контактными данными
--5. Расписание мероприятия

USE [EventsBD];

-- Для отчетов по мероприятиям 
CREATE INDEX IX_Events_StatusId_Include_StartDate_EndDate_BasePrice ON [Events](StatusId) INCLUDE (StartDate, EndDate, BasePrice);
CREATE INDEX IX_Order_EventId_Include_FactPrice ON [Order](EventId) INCLUDE (FactPrice);

-- Для поиска мероприятий и участников по датам и контактам
CREATE INDEX IX_Events_StartDate_EndDate ON [Events](StartDate, EndDate);
CREATE INDEX IX_Events_StartDate_StatusId ON [Events](StartDate, StatusId);
CREATE INDEX IX_Participants_Email ON Participants(Email);
CREATE INDEX IX_Participants_PhoneNumber ON Participants(PhoneNumber);
CREATE INDEX IX_Events_EventName ON [Events](EventName);


-- Для запросов к расписанию
CREATE INDEX IX_Schedules_DateTimeStartClass_DateTimeEndClass_INCLUDE_ClassId_EventId 
ON Schedules(DateTimeStartClass, DateTimeEndClass) INCLUDE (ClassId, EventId);