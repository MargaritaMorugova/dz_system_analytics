
-- =============================================
-- Создание БД "Cash Orders" для MS SQL Server
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


-- Справочник валют
IF OBJECT_ID('Currency', 'U') IS NOT NULL DROP TABLE Currency;
CREATE TABLE Currency (
    id INT IDENTITY(1,1) PRIMARY KEY,
    code NVARCHAR(3) NOT NULL UNIQUE,
    name NVARCHAR(50) NOT NULL
);

-- Справочник статусов заказов
IF OBJECT_ID('OrderStatus', 'U') IS NOT NULL DROP TABLE OrderStatus;
CREATE TABLE OrderStatus (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(50) NOT NULL UNIQUE
);

-- Справочник номиналов
IF OBJECT_ID('Nominals', 'U') IS NOT NULL DROP TABLE Nominals;
CREATE TABLE Nominals (
    id INT IDENTITY(1,1) PRIMARY KEY,
    currency_id INT NOT NULL FOREIGN KEY REFERENCES Currency(id),
    value DECIMAL(10,2) NOT NULL,
    available BIT NOT NULL DEFAULT 1 -- флаг доступности
);

-- Клиенты c лимитами
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

-- Отделения банка
IF OBJECT_ID('Offices', 'U') IS NOT NULL DROP TABLE Offices;
CREATE TABLE Offices (
    id INT IDENTITY(1,1) PRIMARY KEY,
    title NVARCHAR(200) NOT NULL,
    address NVARCHAR(500) NOT NULL
);


-- Счета клиентов
IF OBJECT_ID('Account', 'U') IS NOT NULL DROP TABLE Account;
CREATE TABLE Account (
    id INT IDENTITY(1,1) PRIMARY KEY,
    number NVARCHAR(50) NOT NULL UNIQUE,
    client_id INT NOT NULL FOREIGN KEY REFERENCES Client(id),
    balance DECIMAL(15,2) NOT NULL DEFAULT 0
);

-- Заказы
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

-- Состав заказа
IF OBJECT_ID('OrderItem', 'U') IS NOT NULL DROP TABLE OrderItem;
CREATE TABLE OrderItem (
    id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT NOT NULL FOREIGN KEY REFERENCES Orders(id) ON DELETE CASCADE,
    nominal_id INT NOT NULL FOREIGN KEY REFERENCES Nominals(id),
    quantity INT NOT NULL,
    sum DECIMAL(15,2) NOT NULL
);


-- Баланс офиса
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

-- Инкассация
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

-- Выдача денег
IF OBJECT_ID('CashIssue', 'U') IS NOT NULL DROP TABLE CashIssue; -- добавить в заказ не можем, а то нарушим 3нф)
CREATE TABLE CashIssue (
    id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT NOT NULL FOREIGN KEY REFERENCES Orders(id) ON DELETE CASCADE,
    issue_date DATETIME2 NOT NULL DEFAULT GETDATE(),
    client_signature NVARCHAR(500)
);