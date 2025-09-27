USE [EventsBD];
-- 1. Справочники
CREATE TABLE Directions (
    DirectionId INT IDENTITY(1,1) PRIMARY KEY,
    Title NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    DirectionParentId INT NULL,
    CONSTRAINT FK_Directions_DirectionParentId FOREIGN KEY (DirectionParentId) REFERENCES Directions(DirectionId)
);

CREATE TABLE StatusType (
    StatusTypeId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL
);

CREATE TABLE Statuses (
    StatusId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(200) NOT NULL,
    StatusTypeId INT NOT NULL,
    CONSTRAINT FK_Statuses_StatusTypeId FOREIGN KEY (StatusTypeId) REFERENCES StatusType(StatusTypeId)
);

-- 2. Люди
CREATE TABLE Users (
    UserId INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(200) NOT NULL,
    SecondName NVARCHAR(200) NULL,
    Gender INT NULL,
    PhoneNumber NVARCHAR(20) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    IsActive BIT NULL,
    PayPerHour DECIMAL(18,2) NULL,
    CONSTRAINT CHK_Users_Gender CHECK (Gender IN (0, 1, 2)),
    CONSTRAINT CHK_Users_Email CHECK (Email LIKE '%_@__%.__%'),
    CONSTRAINT CHK_Users_PayPerHour CHECK (PayPerHour >= 0)
);

CREATE TABLE Masters (
    MasterId INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(200) NOT NULL,
    SecondName NVARCHAR(200) NULL,
    Gender INT NULL,
    PhoneNumber NVARCHAR(20) NULL,
    Email NVARCHAR(100) NULL,
    PayPerHour DECIMAL(18,2) NULL,
    Description NVARCHAR(MAX) NULL,
    CONSTRAINT CHK_Masters_Gender CHECK (Gender IN (0, 1, 2)),
    CONSTRAINT CHK_Masters_Email CHECK (Email LIKE '%_@__%.__%' OR Email IS NULL),
    CONSTRAINT CHK_Masters_PayPerHour CHECK (PayPerHour >= 0)
);

CREATE TABLE Participants (
    ParticipantId INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(200) NOT NULL,
    SecondName NVARCHAR(200) NULL,
    Gender INT NULL,
    PhoneNumber NVARCHAR(20) NULL,
    Email NVARCHAR(100) NOT NULL,
    TelegrammNickname NVARCHAR(100) NULL,
    SpecialNeeds NVARCHAR(MAX) NULL,
    CONSTRAINT CHK_Participants_Gender CHECK (Gender IN (0, 1, 2)),
    CONSTRAINT CHK_Participants_Email CHECK (Email LIKE '%_@__%.__%')
);

-- 3. Наполнение (Contents)
CREATE TABLE Classes (
    ClassId INT IDENTITY(1,1) PRIMARY KEY,
    Title NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    MaxParticipants INT NULL,
    MinParticipants INT NULL,
    DirectionId INT NULL,
    CONSTRAINT FK_Classes_DirectionId FOREIGN KEY (DirectionId) REFERENCES Directions(DirectionId),
    CONSTRAINT CHK_Classes_MaxParticipants CHECK (MaxParticipants > 0),
    CONSTRAINT CHK_Classes_MinParticipants CHECK (MinParticipants >= 0),
    CONSTRAINT CHK_Classes_MaxMinParticipants CHECK (MaxParticipants >= MinParticipants)
);

CREATE TABLE MastersClasses (
    MastersClassesId INT IDENTITY(1,1) PRIMARY KEY,
    ClassId INT NOT NULL,
    MasterId INT NOT NULL,
    CONSTRAINT FK_MastersClasses_ClassId FOREIGN KEY (ClassId) REFERENCES Classes(ClassId),
    CONSTRAINT FK_MastersClasses_MasterId FOREIGN KEY (MasterId) REFERENCES Masters(MasterId),
    CONSTRAINT UQ_MastersClasses_ClassId_MasterId UNIQUE (ClassId, MasterId)
);

-- 4. Основные (Main) - создаем сначала Locations и Events, так как на них есть ссылки
CREATE TABLE Locations (
    LocationId INT IDENTITY(1,1) PRIMARY KEY,
    LocationName NVARCHAR(200) NOT NULL,
    [Address] NVARCHAR(500) NULL,
    PayPerHour DECIMAL(18,2) NULL,
    ContactPerson NVARCHAR(200) NULL,
    ContactPhone NVARCHAR(50) NULL,
    ContactEmail NVARCHAR(100) NULL,
    Capacity INT NULL,
    Facilities NVARCHAR(MAX) NULL,
    CONSTRAINT CHK_Locations_Capacity CHECK (Capacity > 0),
    CONSTRAINT CHK_Locations_PayPerHour CHECK (PayPerHour >= 0)
);

CREATE TABLE [Events] (
    EventId INT IDENTITY(1,1) PRIMARY KEY,
    EventName NVARCHAR(200) NOT NULL,
    [Description] NVARCHAR(MAX) NULL,
    StartDate DATETIME2 NULL,
    EndDate DATETIME2 NULL,
    LocationId INT NULL,
    BasePrice DECIMAL(18,2) NULL,
    MaxParticipants INT NULL,
    StatusId INT NOT NULL,
    CONSTRAINT FK_Events_LocationId FOREIGN KEY (LocationId) REFERENCES Locations(LocationId),
    CONSTRAINT FK_Events_StatusId FOREIGN KEY (StatusId) REFERENCES Statuses(StatusId),
    CONSTRAINT CHK_Events_EndDateAfterStartDate CHECK (EndDate > StartDate),
    CONSTRAINT CHK_Events_BasePrice CHECK (BasePrice >= 0),
    CONSTRAINT CHK_Events_MaxParticipants CHECK (MaxParticipants > 0)
);

CREATE TABLE Schedules (
    ScheduleId INT IDENTITY(1,1) PRIMARY KEY,
    EventId INT NOT NULL,
    ClassId INT NOT NULL,
    DateTimeStartClass DATETIME2 NOT NULL,
    DateTimeEndClass DATETIME2 NULL,
    StatusId INT NOT NULL,
    CONSTRAINT FK_Schedules_EventId FOREIGN KEY (EventId) REFERENCES [Events] (EventId),
    CONSTRAINT FK_Schedules_ClassId FOREIGN KEY (ClassId) REFERENCES Classes(ClassId),
    CONSTRAINT FK_Schedules_StatusId FOREIGN KEY (StatusId) REFERENCES Statuses(StatusId),
    CONSTRAINT CHK_Schedules_DateTimeEndClassAfterStart CHECK (DateTimeEndClass > DateTimeStartClass)
);

CREATE TABLE EventOrganizers (
    EventOrganizersId INT IDENTITY(1,1) PRIMARY KEY,
    EventId INT NOT NULL,
    UserId INT NOT NULL,
    CONSTRAINT FK_EventOrganizers_EventId FOREIGN KEY (EventId) REFERENCES [Events] (EventId),
    CONSTRAINT FK_EventOrganizers_UserId FOREIGN KEY (UserId) REFERENCES Users(UserId),
    CONSTRAINT UQ_EventOrganizers_EventId_UserId UNIQUE (EventId, UserId)
);

-- 5.Финансы Finance (создаем после Events)
CREATE TABLE [Order] (
    OrderId INT IDENTITY(1,1) PRIMARY KEY,
    ParticipantId INT NOT NULL,
    EventId INT NOT NULL,
    FactPrice DECIMAL(18,2) NOT NULL,
    DateOrder DATETIME2 NOT NULL,
    StatusId INT NOT NULL,
    CONSTRAINT FK_Order_ParticipantId FOREIGN KEY (ParticipantId) REFERENCES Participants(ParticipantId),
    CONSTRAINT FK_Order_EventId FOREIGN KEY (EventId) REFERENCES [Events] (EventId),
    CONSTRAINT FK_Order_StatusId FOREIGN KEY (StatusId) REFERENCES Statuses(StatusId),
    CONSTRAINT CHK_Order_FactPrice CHECK (FactPrice >= 0)
);


-- Индексы для внешних ключей
CREATE INDEX FK_Directions_DirectionParentId ON Directions(DirectionParentId);
CREATE INDEX FK_Statuses_StatusTypeId ON Statuses(StatusTypeId);
CREATE INDEX FK_Classes_DirectionId ON Classes(DirectionId);
CREATE INDEX FK_MastersClasses_ClassId ON MastersClasses(ClassId);
CREATE INDEX FK_MastersClasses_MasterId ON MastersClasses(MasterId);
CREATE INDEX FK_Order_ParticipantId ON [Order](ParticipantId);
CREATE INDEX FK_Order_EventId ON [Order](EventId);
CREATE INDEX FK_Order_StatusId ON [Order](StatusId);
CREATE INDEX FK_Events_LocationId ON [Events](LocationId);
CREATE INDEX FK_Events_StatusId ON [Events](StatusId);
CREATE INDEX FK_Schedules_EventId ON Schedules(EventId);
CREATE INDEX FK_Schedules_ClassId ON Schedules(ClassId);
CREATE INDEX FK_Schedules_StatusId ON Schedules(StatusId);

--Лучше сделать составным, так как будут использоваться всегда в связке
CREATE INDEX FK_EventOrganizers_EventId ON EventOrganizers(EventId, UserId);
