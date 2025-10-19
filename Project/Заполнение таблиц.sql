-- 1. Справочники
-- Направления
USE [EventsBD];

INSERT INTO Directions (Title, Description, DirectionParentId)
VALUES 
    (N'Фитнес', N'Занятия направлаенные на оздоровление', NULL),
    (N'Йога', N'Занятие на ковриках', 1),
	(N'Йога с собачками', N'Занятие на ковриках. Участвуют домашние маленькие собачки', 2),
	(N'Духовные практики', N'Духовное развитие', NULL),
	(N'Разговор с психологом', N'Беседа направленная на эмоциональное восстановление', 4),
	(N'Психологический анализ фильма', N'Разбор кинофильма совместно с психологом', 5),
	(N'Танцы', NULL, NULL),
	(N'Социальные танцы', NULL, 7),
	(N'Конференции', NULL, NULL),
	(N'Развитие ИИ', NULL, 9);

-- Типы статусов
INSERT INTO StatusType (Name)
VALUES 
    (N'Мероприятие'),
    (N'Заказ'),
	(N'Расписание');

-- Статусы
INSERT INTO Statuses (Name, StatusTypeId)
VALUES 
    (N'Черновик', 1),
    (N'Планируется', 1),
	(N'Открыта регистрации', 1),
	(N'В процессе', 1),
	(N'Завершено', 1),
	(N'Ожидание подтверждения оплаты', 2),
	(N'Оплачено', 2),
	(N'Возврат', 2),
	(N'Черновик', 3),
	(N'Активно', 3);

-- 2. Люди
-- Организаторы
INSERT INTO Users (FirstName, SecondName, Gender, PhoneNumber, Email, IsActive, PayPerHour)
VALUES 
    (N'Иван', N'Иванов', 1, N'+79991234567', N'ivi@example.com', 1, 1000.00);

-- Тренера/спикеры
INSERT INTO Masters (FirstName, SecondName, Gender, PhoneNumber, Email, PayPerHour, Description)
VALUES 
    (N'Анна', N'Семнова', 1, N'+79991234567', N'master@example.com', 2000.00, N'Спикер. Тема ИИ'),
    (N'Аркадий', NULL, 1, NULL, N'master@example.com', 1500.00, N'Психолог');

-- Участники
INSERT INTO Participants (FirstName, SecondName, Gender, PhoneNumber, Email, TelegrammNickname, SpecialNeeds)
VALUES 
    (N'Кристина', NULL, 2, NULL, N'participant2@example.com', NULL, NULL),
	(NULL, NULL, NULL, NULL, N'participant3@example.com', NULL, NULL);

-- 3. Наполнение (Contents)
-- Мастер-классы
INSERT INTO Classes (Title, Description, MaxParticipants, MinParticipants, DirectionId)
VALUES 
    (N'Кинопросмотр фильма', N'Смотрим и обсуждаем кино', 16, 4, 6),
	(N'Лекция о ИИ', NULL, 50, NULL, 10),
	(N'Вайб кодинг', NULL, 20, 2, 10);

-- Связь тренер-тренинг
INSERT INTO MastersClasses (ClassId, MasterId)
VALUES 
    (2, 1),
	(1, 2),
	(3, 1);


-- 4. Основные (Main)
-- Места проведения
INSERT INTO Locations (LocationName, Address, PayPerHour, ContactPerson, ContactPhone, ContactEmail, Capacity, Facilities)
VALUES 
    (N'Конференец-зал', N'Мск, ул.Ленина, д 6', 5000.00, N'Леонид', N'+79991234567', N'location@example.com', 50, N'Обеденный зал, проектор, кондиционеры'),
	(N'Кафе Ласточка', N'Спб, ул.Ленина, д 12, корп 3', NULL, N'Ксения', N'+79991234512', N'location1@example.com', 30, N'Проектор, кресла, столы, еда');

-- Мероприятия
INSERT INTO Events (EventName, Description, StartDate, EndDate, LocationId, BasePrice, MaxParticipants, StatusId)
VALUES 
    (N'Смотрим с психологом фильм Амели', NULL, '2026-01-10 18:00:00', '2026-01-10 22:00:00', 2, 500.00, NULL, 3),
	(N'ИИ в нашей жизни', NULL, '2025-11-10 18:00:00', '2025-11-10 22:00:00', 1, NULL, 40, 2);

-- 3. Финансы Finance
-- Заказы
INSERT INTO [Order] (ParticipantId, EventId, FactPrice, DateOrder, StatusId)
VALUES 
    (1, 1, 500.00, '2025-09-09 09:00:00', 6),
	(2, 1, 500.00, '2025-09-09 10:00:00', 7),
	(3, 2, 0, '2025-09-10 10:00:00', 7);

-- Расписание
INSERT INTO Schedules (EventId, ClassId, DateTimeStartClass, DateTimeEndClass, StatusId)
VALUES 
(1, 1, '2026-01-10 18:00:00', '2026-01-10 22:00:00', 10),
    (2, 2, '2025-11-10 18:00:00', '2025-11-10 19:30:00', 9),
	(2, 3, '2025-11-10 20:00:00', '2025-11-10 21:50:00', 9);

-- Организаторы мероприятий
INSERT INTO EventOrganizers (EventId, UserId)
VALUES 
    (1, 1),
	(2, 1);