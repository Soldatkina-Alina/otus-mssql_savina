-- ��������� ������, ��������� � �������, ��� ������� ����������� �������

---��������� :
--1. EventRegistrationProcedure - ����������� ��������� �� �����������
		--��������� @ParticipantId, @EventId. ��������� ��������� �����, ������ �����������, ������� ������ � ������� Order �� �������� "���������������" � ������� �����
--2. CreateEventProcedure - �������� ������ ����������� �� ����� �������������:
		--��������� ��������� �����������, ������ �������������, ����������. � ������ ���������� ������� ������ � Events, ����� ������ � EventOrganizers � Schedules.
--3. CloseEventProcedure - ���������� �����������
		--��������� @EventId. ������ ������ ����������� �� "���������". ����� ��������� ������� �� ������ ��� �������� � ��������.

--�������:
--1.fn_GetEventFreePlaces - ���������� ���������� ��������� ���� �� �����������:
		--��������� @EventId. ���������� Events.MaxParticipants - COUNT(Order.OrderId).
--2.fn_GetMasterSchedule - ���������� ���������� ������� �� ������:
		--��������� @MasterId, @StartDate, @EndDate. ���������� ������� � ���������, �������� � ���������� �������, ��� ����� ������.

--������
--1. ����� �� ������������ (������, �����, ���-�� ����������, �������)
--2. ���������� ����� �� ��������/��������
--3. ����� �� ��������� �������� �� ������
--4. ������ ���������� ����������� ����������� � ����������� �������
--5. ���������� �����������

USE [EventsBD];

-- ��� ������� �� ������������ 
CREATE INDEX IX_Events_StatusId_Include_StartDate_EndDate_BasePrice ON [Events](StatusId) INCLUDE (StartDate, EndDate, BasePrice);
CREATE INDEX IX_Order_EventId_Include_FactPrice ON [Order](EventId) INCLUDE (FactPrice);

-- ��� ������ ����������� � ���������� �� ����� � ���������
CREATE INDEX IX_Events_StartDate_EndDate ON [Events](StartDate, EndDate);
CREATE INDEX IX_Participants_Email ON Participants(Email);
CREATE INDEX IX_Participants_PhoneNumber ON Participants(PhoneNumber);
CREATE INDEX IX_Events_EventName ON [Events](EventName);

-- ��� �������� � ����������
CREATE INDEX IX_Schedules_DateTimeStartClass_DateTimeEndClass_INCLUDE_ClassId_EventId 
ON Schedules(DateTimeStartClass, DateTimeEndClass) INCLUDE (ClassId, EventId);