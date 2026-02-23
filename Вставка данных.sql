
-- =============================================
-- Создание БД "Cash Orders" для MS SQL Server (таблицы на английском)
-- =============================================

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'CashOrders')
BEGIN
    DROP DATABASE CashOrders;
END
GO

CREATE DATABASE CashOrders;
GO

USE CashOrders;
GO

-- =============================================
-- СПРАВОЧНИКИ (Reference tables)
-- =============================================

-- FR-02.1 Справочник валют
IF OBJECT_ID('Currency', 'U') IS NOT NULL DROP TABLE Currency;
CREATE TABLE Currency (
    id INT IDENTITY(1,1) PRIMARY KEY,
    code NVARCHAR(3) NOT NULL UNIQUE,
    name NVARCHAR(50) NOT NULL
);

-- FR-02.2 Справочник статусов заказов
IF OBJECT_ID('OrderStatus', 'U') IS NOT NULL DROP TABLE OrderStatus;
CREATE TABLE OrderStatus (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(50) NOT NULL UNIQUE
);

-- FR-02.3 Справочник номиналов
IF OBJECT_ID('Nominals', 'U') IS NOT NULL DROP TABLE Nominals;
CREATE TABLE Nominals (
    id INT IDENTITY(1,1) PRIMARY KEY,
    currency_id INT NOT NULL FOREIGN KEY REFERENCES Currency(id),
    value DECIMAL(10,2) NOT NULL,
    available BIT NOT NULL DEFAULT 1 -- флаг доступности
);

-- =============================================
-- БАЗОВЫЕ СУЩНОСТИ (Core entities)
-- =============================================

-- FR-01 Клиенты + лимиты
IF OBJECT_ID('Client', 'U') IS NOT NULL DROP TABLE Client;
CREATE TABLE Client (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(200) NOT NULL,
	surname NVARCHAR(200) NOT NULL,
	middle_name NVARCHAR(200) NOT NULL,
    passport NVARCHAR(50) NOT NULL UNIQUE,
    phone NVARCHAR(20),
    daily_limit DECIMAL(15,2) DEFAULT 500000,
    weekly_limit DECIMAL(15,2) DEFAULT 1000000,
    commission_pct DECIMAL(5,2) DEFAULT 0.00
);

-- FR-09 Отделения банка
IF OBJECT_ID('Offices', 'U') IS NOT NULL DROP TABLE Offices;
CREATE TABLE Offices (
    id INT IDENTITY(1,1) PRIMARY KEY,
    title NVARCHAR(200) NOT NULL,
    address NVARCHAR(500) NOT NULL
);


-- FR-14 Счета клиентов
IF OBJECT_ID('Account', 'U') IS NOT NULL DROP TABLE Account;
CREATE TABLE Account (
    id INT IDENTITY(1,1) PRIMARY KEY,
    number NVARCHAR(50) NOT NULL UNIQUE,
    client_id INT NOT NULL FOREIGN KEY REFERENCES Client(id),
    balance DECIMAL(15,2) NOT NULL DEFAULT 0
);

-- =============================================
-- ОСНОВНЫЕ СУЩНОСТИ (Main entities)
-- =============================================

-- FR-03 Заказы
IF OBJECT_ID('Orders', 'U') IS NOT NULL DROP TABLE Orders;
CREATE TABLE Orders (
    id INT IDENTITY(1,1) PRIMARY KEY,
    client_id INT NOT NULL FOREIGN KEY REFERENCES Client(id),
    office_id INT NOT NULL FOREIGN KEY REFERENCES Offices(id),
    account_id INT NOT NULL FOREIGN KEY REFERENCES Account(id),
    status_id INT NOT NULL FOREIGN KEY REFERENCES OrderStatus(id),
    created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    issue_deadline DATETIME2 NOT NULL,
    total_sum DECIMAL(15,2) NOT NULL
);

-- FR-04 Состав заказа
IF OBJECT_ID('OrderItem', 'U') IS NOT NULL DROP TABLE OrderItem;
CREATE TABLE OrderItem (
    id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT NOT NULL FOREIGN KEY REFERENCES Orders(id) ON DELETE CASCADE,
    nominal_id INT NOT NULL FOREIGN KEY REFERENCES Nominals(id),
    quantity INT NOT NULL,
    sum DECIMAL(15,2) NOT NULL
);

-- =============================================
-- ОПЕРАЦИИ С НАЛИЧНЫМИ (Cash operations)
-- =============================================

-- FR-06 Баланс офиса
IF OBJECT_ID('Balance_office', 'U') IS NOT NULL DROP TABLE Balance_office;
CREATE TABLE Balance_office (
    id INT IDENTITY(1,1) PRIMARY KEY,
    office_id INT NOT NULL FOREIGN KEY REFERENCES Offices(id),
    balance_date DATE NOT NULL,
    currency_id INT NOT NULL FOREIGN KEY REFERENCES Currency(id),
    nominal_id INT NOT NULL FOREIGN KEY REFERENCES Nominals(id),
    quantity INT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
);

-- FR-07 Инкассация
IF OBJECT_ID('CashTransit', 'U') IS NOT NULL DROP TABLE CashTransit;
CREATE TABLE CashTransit (
    id INT IDENTITY(1,1) PRIMARY KEY,
    office_id INT NOT NULL FOREIGN KEY REFERENCES Offices(id),
    operation_date DATETIME2 NOT NULL DEFAULT GETDATE(),
    inkassator_fio NVARCHAR(200),
    currency_id INT NOT NULL FOREIGN KEY REFERENCES Currency(id),
    nominal_id INT NOT NULL FOREIGN KEY REFERENCES Nominals(id),
    quantity INT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    type NVARCHAR(20) NOT NULL -- 'поступление', 'изъятие'
);

-- FR-08 Выдача
IF OBJECT_ID('CashIssue', 'U') IS NOT NULL DROP TABLE CashIssue; -- добавить в заказ не можем, а то нарушим 3нф)
CREATE TABLE CashIssue (
    id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT NOT NULL FOREIGN KEY REFERENCES Orders(id) ON DELETE CASCADE,
    issue_date DATETIME2 NOT NULL DEFAULT GETDATE(),
    client_signature NVARCHAR(500)
);



USE CashOrders;
GO

-- 1. Currency (валюты)
INSERT Currency (code, name) VALUES
('RUB', 'Российский рубль'),
('USD', 'Доллар США'),
('EUR', 'Евро'),
('GBP', 'Фунт стерлингов'),
('CNY', 'Китайский юань'),
('JPY', 'Японская иена'),
('CHF', 'Швейцарский франк'),
('CAD', 'Канадский доллар'),
('AUD', 'Австралийский доллар'),
('SEK', 'Шведская крона');
GO

-- 2. OrderStatus (статусы заказов)
INSERT OrderStatus (name) VALUES
('Новый'),
('Подтвержден'),
('В процессе'),
('Готов к выдаче'),
('Выдан'),
('Отменен'),
('Отказан по лимиту'),
('Отказан по остаткам'),
('Просрочен'),
('Возврат');
GO

-- 3. Nominals (номиналы по валютам)
INSERT Nominals (currency_id, value, available) VALUES
(1, 50.00, 1),      -- 50 RUB
(1, 100.00, 1),     -- 100 RUB  
(1, 500.00, 1),     -- 500 RUB
(1, 1000.00, 1),    -- 1000 RUB
(1, 5000.00, 1),    -- 5000 RUB
(2, 1.00, 1),       -- 1 USD
(2, 5.00, 1),       -- 5 USD
(2, 10.00, 1),      -- 10 USD
(2, 20.00, 1),      -- 20 USD
(2, 100.00, 1);     -- 100 USD
GO

-- 4. Client (клиенты)
INSERT Client (name, surname, middle_name, passport, phone, daily_limit, weekly_limit, commission_pct) VALUES
('Иван', 'Петров', 'Сергеевич', '4509 123456', '+7(900)123-45-67', 100000, 500000, 0.50),
('Мария', 'Сидорова', 'Алексеевна', '4510 234567', '+7(900)234-56-78', 300000, 1000000, 0.30),
('Алексей', 'Иванов', 'Петрович', '4511 345678', '+7(900)345-67-89', 500000, 2000000, 0.00),
('Елена', 'Козлова', 'Викторовна', '4512 456789', '+7(900)456-78-90', 200000, 800000, 0.40),
('Дмитрий', 'Смирнов', 'Олегович', '4513 567890', '+7(900)567-89-01', 150000, 600000, 0.60),
('Анна', 'Васильева', 'Михайловна', '4514 678901', '+7(900)678-90-12', 250000, 900000, 0.25),
('Сергей', 'Морозов', 'Андреевич', '4515 789012', '+7(900)789-01-23', 400000, 1500000, 0.10),
('Ольга', 'Новикова', 'Дмитриевна', '4516 890123', '+7(900)890-12-34', 100000, 400000, 0.70),
('Михаил', 'Федоров', 'Николаевич', '4517 901234', '+7(900)901-23-45', 600000, 2500000, 0.00),
('Татьяна', 'Михеева', 'Владимировна', '4518 012345', '+7(900)012-34-56', 350000, 1200000, 0.35);
GO

-- 5. Offices (отделения)
INSERT Offices (title, address) VALUES
('Отделение №1', 'г. Москва, ул. Ленина, д.1'),
('Отделение №2', 'г. Москва, ул. Пушкина, д.10'),
('Отделение №3', 'г. Москва, пр-т Мира, д.25'),
('Отделение №4', 'г. Москва, ул. Гагарина, д.5'),
('Отделение №5', 'г. Москва, ул. Советская, д.15'),
('Отделение №6', 'г. Москва, пр-т Вернадского, д.30'),
('Отделение №7', 'г. Москва, ул. Профсоюзная, д.12'),
('Отделение №8', 'г. Москва, ул. Тверская, д.8'),
('Отделение №9', 'г. Москва, пр-т Ленинский, д.20'),
('Отделение №10', 'г. Москва, ул. Арбат, д.3');
GO

-- 6. Account (счета)
INSERT Account (number, client_id, balance) VALUES
('40817810000000012345', 1, 1000000.00),
('40817810000000023456', 2, 2500000.00),
('40817810000000034567', 3, 5000000.00),
('40817810000000045678', 4, 1800000.00),
('40817810000000056789', 5, 1200000.00),
('40817810000000067890', 6, 3000000.00),
('40817810000000078901', 7, 4500000.00),
('40817810000000089012', 8, 800000.00),
('40817810000000090123', 9, 7500000.00),
('40817810000000101234', 10, 2200000.00);
GO

-- 7. Orders (заказы)
INSERT Orders (client_id, office_id, account_id, status_id, created_at, issue_deadline, total_sum) VALUES
(1, 1, 1, 1, '2026-02-20 10:00', '2026-02-22 18:00', 50000.00),
(2, 2, 2, 2, '2026-02-20 11:30', '2026-02-23 17:00', 150000.00),
(3, 3, 3, 3, '2026-02-20 14:15', '2026-02-24 16:00', 300000.00),
(4, 4, 4, 4, '2026-02-20 09:45', '2026-02-22 19:00', 75000.00),
(5, 5, 5, 1, '2026-02-21 13:20', '2026-02-23 18:00', 120000.00),
(6, 1, 6, 5, '2026-02-19 16:10', '2026-02-21 17:00', 200000.00),
(7, 6, 7, 2, '2026-02-21 08:50', '2026-02-24 15:00', 250000.00),
(8, 7, 8, 6, '2026-02-20 12:30', '2026-02-22 18:00', 40000.00),
(9, 8, 9, 3, '2026-02-21 15:40', '2026-02-25 17:00', 450000.00),
(10, 9, 10, 1, '2026-02-22 10:25', '2026-02-24 16:00', 180000.00);
GO

-- 8. OrderItem (состав заказов)
INSERT OrderItem (order_id, nominal_id, quantity, sum) VALUES
(1, 4, 50, 50000.00),  -- 1000р x 50
(1, 5, 30, 150000.00), -- 5000р x 30
(2, 5, 30, 150000.00), -- 5000р x 30
(3, 3, 600, 300000.00), -- 500р x 600
(4, 2, 750, 75000.00), -- 100р x 750
(5, 4, 120, 120000.00), -- 1000р x 120
(6, 5, 40, 200000.00), -- 5000р x 40
(7, 4, 250, 250000.00), -- 1000р x 250
(8, 1, 800, 40000.00), -- 50р x 800
(9, 5, 90, 450000.00), -- 5000р x 90
(10, 3, 360, 180000.00); -- 500р x 360
GO

-- 9. Balance_office (остатки)
INSERT Balance_office (office_id, balance_date, currency_id, nominal_id, quantity, amount) VALUES
(1, '2026-02-22', 1, 4, 2000, 2000000.00),
(2, '2026-02-22', 1, 5, 800, 4000000.00),
(3, '2026-02-22', 1, 3, 1500, 750000.00),
(4, '2026-02-22', 1, 2, 3000, 300000.00),
(5, '2026-02-22', 1, 4, 1200, 1200000.00),
(6, '2026-02-22', 1, 5, 600, 3000000.00),
(7, '2026-02-22', 1, 4, 900, 900000.00),
(8, '2026-02-22', 1, 1, 2500, 125000.00),
(9, '2026-02-22', 1, 5, 1100, 5500000.00),
(10, '2026-02-22', 1, 3, 800, 400000.00);
GO

-- 10. CashTransit (инкассация)
INSERT CashTransit (office_id, operation_date, inkassator_fio, currency_id, nominal_id, quantity, amount, type) VALUES
(1, '2026-02-21 09:00', 'Иванов И.И.', 1, 4, 1000, 1000000.00, 'поступление'),
(2, '2026-02-21 10:30', 'Петров П.П.', 1, 5, 500, 2500000.00, 'поступление'),
(3, '2026-02-21 11:15', 'Сидоров С.С.', 1, 3, 800, 400000.00, 'поступление'),
(4, '2026-02-21 14:00', 'Козлова К.К.', 1, 2, 2000, 200000.00, 'поступление'),
(5, '2026-02-21 13:45', 'Смирнов С.С.', 1, 4, 700, 700000.00, 'поступление'),
(6, '2026-02-22 08:20', 'Васильева В.В.', 1, 5, 400, 2000000.00, 'поступление'),
(7, '2026-02-22 09:50', 'Морозов М.М.', 1, 4, 500, 500000.00, 'поступление'),
(8, '2026-02-22 12:10', 'Новикова Н.Н.', 1, 1, 1500, 75000.00, 'поступление'),
(9, '2026-02-22 15:30', 'Федоров Ф.Ф.', 1, 5, 600, 3000000.00, 'поступление'),
(10, '2026-02-22 16:45', 'Михеева М.М.', 1, 3, 400, 200000.00, 'изъятие');
GO

-- 11. CashIssue (выдачи)
INSERT CashIssue (order_id, issue_date, client_signature) VALUES
(6, '2026-02-21 14:30', 'Иванов А.П. 21.02.2026 14:30'),
(2, '2026-02-22 16:45', 'Сидорова М.А. 22.02.2026 16:45'),
(7, '2026-02-22 11:20', 'Морозов С.А. 22.02.2026 11:20'),
(4, '2026-02-22 17:15', 'Козлова Е.В. 22.02.2026 17:15'),
(1, '2026-02-22 18:30', 'Петров И.С. 22.02.2026 18:30');
GO



-- 7. Orders (заказы марта)
INSERT Orders (client_id, office_id, account_id, status_id, created_at, issue_deadline, total_sum) VALUES
(1, 1, 1, 1, '2026-03-01 09:15', '2026-03-03 18:00', 85000.00),
(2, 2, 2, 3, '2026-03-01 11:45', '2026-03-04 17:00', 240000.00),
(3, 3, 3, 2, '2026-03-01 14:30', '2026-03-05 16:00', 420000.00),
(4, 4, 4, 4, '2026-03-02 10:20', '2026-03-04 19:00', 95000.00),
(5, 5, 5, 1, '2026-03-02 13:10', '2026-03-05 18:00', 175000.00),
(6, 6, 6, 5, '2026-03-01 16:40', '2026-03-03 17:00', 310000.00),
(7, 7, 7, 3, '2026-03-02 08:55', '2026-03-06 15:00', 360000.00),
(8, 8, 8, 6, '2026-03-01 12:25', '2026-03-03 18:00', 55000.00),
(9, 9, 9, 2, '2026-03-02 15:35', '2026-03-07 17:00', 520000.00),
(10, 10, 10, 1, '2026-03-03 11:05', '2026-03-05 16:00', 210000.00);
GO

-- 8. OrderItem (состав заказов марта)
INSERT OrderItem (order_id, nominal_id, quantity, sum) VALUES
(12, 4, 85, 85000.00),    -- 1000р x 85
(13, 5, 48, 240000.00),   -- 5000р x 48
(14, 4, 420, 420000.00),  -- 1000р x 420
(15, 3, 190, 95000.00),   -- 500р x 190
(16, 4, 175, 175000.00),  -- 1000р x 175
(17, 5, 62, 310000.00),   -- 5000р x 62
(18, 4, 360, 360000.00),  -- 1000р x 360
(19, 2, 550, 55000.00),   -- 100р x 550
(20, 5, 104, 520000.00),  -- 5000р x 104
(21, 3, 420, 210000.00);  -- 500р x 420
GO

-- 9. Balance_office (остатки марта)
INSERT Balance_office (office_id, balance_date, currency_id, nominal_id, quantity, amount) VALUES
(1, '2026-03-03', 1, 4, 2500, 2500000.00),
(2, '2026-03-03', 1, 5, 950, 4750000.00),
(3, '2026-03-03', 1, 4, 1800, 1800000.00),
(4, '2026-03-03', 1, 3, 2200, 1100000.00),
(5, '2026-03-03', 1, 4, 1400, 1400000.00),
(6, '2026-03-03', 1, 5, 750, 3750000.00),
(7, '2026-03-03', 1, 4, 1100, 1100000.00),
(8, '2026-03-03', 1, 2, 3800, 380000.00),
(9, '2026-03-03', 1, 5, 1350, 6750000.00),
(10, '2026-03-03', 1, 3, 950, 475000.00);
GO

-- 10. CashTransit (инкассация марта)
INSERT CashTransit (office_id, operation_date, inkassator_fio, currency_id, nominal_id, quantity, amount, type) VALUES
(1, '2026-03-02 08:45', 'Кузнецов К.Д.', 1, 4, 1200, 1200000.00, 'поступление'),
(2, '2026-03-02 10:15', 'Попова П.С.', 1, 5, 650, 3250000.00, 'поступление'),
(3, '2026-03-02 11:40', 'Соловьев С.В.', 1, 4, 900, 900000.00, 'поступление'),
(4, '2026-03-02 14:25', 'Лебедева Л.А.', 1, 3, 1300, 650000.00, 'поступление'),
(5, '2026-03-02 13:30', 'Зайцев З.М.', 1, 4, 850, 850000.00, 'поступление'),
(6, '2026-03-03 09:10', 'Белова Б.И.', 1, 5, 550, 2750000.00, 'поступление'),
(7, '2026-03-03 10:35', 'Орлов О.В.', 1, 4, 700, 700000.00, 'поступление'),
(8, '2026-03-03 12:55', 'Громова Г.С.', 1, 2, 2200, 220000.00, 'поступление'),
(9, '2026-03-03 16:20', 'Марков М.Е.', 1, 5, 750, 3750000.00, 'поступление'),
(10, '2026-03-03 17:40', 'Данилова Д.А.', 1, 3, 550, 275000.00, 'изъятие');
GO

-- 11. CashIssue (выдачи марта)
INSERT CashIssue (order_id, issue_date, client_signature) VALUES
(16, '2026-03-03 15:25', 'Белова С.И. 03.03.2026 15:25'),
(12, '2026-03-03 17:50', 'Попова Е.С. 03.03.2026 17:50'),
(17, '2026-03-03 14:10', 'Орлов Р.В. 03.03.2026 14:10'),
(14, '2026-03-03 18:45', 'Лебедева В.А. 03.03.2026 18:45'),
(13, '2026-03-03 16:20', 'Кузнецов А.Д. 03.03.2026 16:20');
GO