-- 1. �����������
-- �����������
USE [EventsBD];

INSERT INTO Directions (Title, Description, DirectionParentId)
VALUES 
    (N'������', N'������� ������������� �� ������������', NULL),
    (N'����', N'������� �� ��������', 1),
	(N'���� � ���������', N'������� �� ��������. ��������� �������� ��������� �������', 2),
	(N'�������� ��������', N'�������� ��������', NULL),
	(N'�������� � ����������', N'������ ������������ �� ������������� ��������������', 4),
	(N'��������������� ������ ������', N'������ ���������� ��������� � ����������', 5),
	(N'�����', NULL, NULL),
	(N'���������� �����', NULL, 7),
	(N'�����������', NULL, NULL),
	(N'�������� ��', NULL, 9);

-- ���� ��������
INSERT INTO StatusType (Name)
VALUES 
    (N'�����������'),
    (N'�����'),
	(N'����������');

-- �������
INSERT INTO Statuses (Name, StatusTypeId)
VALUES 
    (N'��������', 1),
    (N'�����������', 1),
	(N'������� �����������', 1),
	(N'� ��������', 1),
	(N'���������', 1),
	(N'�������� ������������� ������', 2),
	(N'��������', 2),
	(N'�������', 2),
	(N'��������', 3),
	(N'�������', 3);

-- 2. ����
-- ������������
INSERT INTO Users (FirstName, SecondName, Gender, PhoneNumber, Email, IsActive, PayPerHour)
VALUES 
    (N'����', N'������', 1, N'+79991234567', N'ivi@example.com', 1, 1000.00);

-- �������/�������
INSERT INTO Masters (FirstName, SecondName, Gender, PhoneNumber, Email, PayPerHour, Description)
VALUES 
    (N'����', N'�������', 1, N'+79991234567', N'master@example.com', 2000.00, N'������. ���� ��'),
    (N'�������', NULL, 1, NULL, N'master@example.com', 1500.00, N'��������');

-- ���������
INSERT INTO Participants (FirstName, SecondName, Gender, PhoneNumber, Email, TelegrammNickname, SpecialNeeds)
VALUES 
    (N'��������', NULL, 2, NULL, N'participant2@example.com', NULL, NULL),
	(NULL, NULL, NULL, NULL, N'participant3@example.com', NULL, NULL);

-- 3. ���������� (Contents)
-- ������-������
INSERT INTO Classes (Title, Description, MaxParticipants, MinParticipants, DirectionId)
VALUES 
    (N'������������ ������', N'������� � ��������� ����', 16, 4, 6),
	(N'������ � ��', NULL, 50, NULL, 10),
	(N'���� ������', NULL, 20, 2, 10);

-- ����� ������-�������
INSERT INTO MastersClasses (ClassId, MasterId)
VALUES 
    (2, 1),
	(1, 2),
	(3, 1);


-- 4. �������� (Main)
-- ����� ����������
INSERT INTO Locations (LocationName, Address, PayPerHour, ContactPerson, ContactPhone, ContactEmail, Capacity, Facilities)
VALUES 
    (N'����������-���', N'���, ��.������, � 6', 5000.00, N'������', N'+79991234567', N'location@example.com', 50, N'��������� ���, ��������, ������������'),
	(N'���� ��������', N'���, ��.������, � 12, ���� 3', NULL, N'������', N'+79991234512', N'location1@example.com', 30, N'��������, ������, �����, ���');

-- �����������
INSERT INTO Events (EventName, Description, StartDate, EndDate, LocationId, BasePrice, MaxParticipants, StatusId)
VALUES 
    (N'������� � ���������� ����� �����', NULL, '2026-01-10 18:00:00', '2026-01-10 22:00:00', 2, 500.00, NULL, 3),
	(N'�� � ����� �����', NULL, '2025-11-10 18:00:00', '2025-11-10 22:00:00', 1, NULL, 40, 2);

-- 3. ������� Finance
-- ������
INSERT INTO [Order] (ParticipantId, EventId, FactPrice, DateOrder, StatusId)
VALUES 
    (1, 1, 500.00, '2025-09-09 09:00:00', 6),
	(2, 1, 500.00, '2025-09-09 10:00:00', 7),
	(3, 2, 0, '2025-09-10 10:00:00', 7);

-- ����������
INSERT INTO Schedules (EventId, ClassId, DateTimeStartClass, DateTimeEndClass, StatusId)
VALUES 
(1, 1, '2026-01-10 18:00:00', '2026-01-10 22:00:00', 10),
    (2, 2, '2025-11-10 18:00:00', '2025-11-10 19:30:00', 9),
	(2, 3, '2025-11-10 20:00:00', '2025-11-10 21:50:00', 9);

-- ������������ �����������
INSERT INTO EventOrganizers (EventId, UserId)
VALUES 
    (1, 1),
	(2, 1);