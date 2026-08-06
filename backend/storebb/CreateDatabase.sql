-- =============================================
-- Create Database and Tables for Inventory Management
-- Based on the provided database schema
-- =============================================

USE master;
GO

-- Create database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'InventoryManagementDB_SP')
BEGIN
    CREATE DATABASE InventoryManagementDB_SP;
END
GO

USE InventoryManagementDB_SP;
GO

-- Create Countries table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Countries' AND xtype='U')
BEGIN
    CREATE TABLE Countries (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Code NVARCHAR(10),
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    
    -- Insert sample countries
    INSERT INTO Countries (Name, Code) VALUES 
    ('Pakistan', 'PK'),
    ('United States', 'US'),
    ('United Kingdom', 'UK'),
    ('China', 'CN'),
    ('India', 'IN');
END
GO

-- Create StateOrProvinces table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='StateOrProvinces' AND xtype='U')
BEGIN
    CREATE TABLE StateOrProvinces (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        CountryId INT NOT NULL,
        Code NVARCHAR(10),
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL,
        FOREIGN KEY (CountryId) REFERENCES Countries(Id)
    );
    
    -- Insert sample states/provinces
    INSERT INTO StateOrProvinces (Name, CountryId, Code) VALUES 
    ('Sindh', 1, 'SD'),
    ('Punjab', 1, 'PB'),
    ('California', 2, 'CA'),
    ('New York', 2, 'NY'),
    ('Beijing', 4, 'BJ');
END
GO

-- Create Cities table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Cities' AND xtype='U')
BEGIN
    CREATE TABLE Cities (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        StateOrProvinceId INT NOT NULL,
        Code NVARCHAR(10),
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL,
        FOREIGN KEY (StateOrProvinceId) REFERENCES StateOrProvinces(Id)
    );
    
    -- Insert sample cities
    INSERT INTO Cities (Name, StateOrProvinceId) VALUES 
    ('Karachi', 1),
    ('Shahzadpur', 1),
    ('Lahore', 2),
    ('San Francisco', 3),
    ('New York City', 4),
    ('Beijing', 5);
END
GO

-- Create Branches table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Branches' AND xtype='U')
BEGIN
    CREATE TABLE Branches (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Code NVARCHAR(20),
        Address NVARCHAR(500),
        CityId INT,
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL,
        FOREIGN KEY (CityId) REFERENCES Cities(Id)
    );
    
    -- Insert sample branches
    INSERT INTO Branches (Name, Code) VALUES 
    ('Main Branch', 'MAIN'),
    ('Secondary Branch', 'SEC');
END
GO

-- Create TaxPayerCategories table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='TaxPayerCategories' AND xtype='U')
BEGIN
    CREATE TABLE TaxPayerCategories (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Code NVARCHAR(20),
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    
    -- Insert sample tax payer categories
    INSERT INTO TaxPayerCategories (Name, Code) VALUES 
    ('Individual', 'IND'),
    ('Company', 'COM'),
    ('Partnership', 'PAR');
END
GO

-- Create AccountCOAs table (Chart of Accounts)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='AccountCOAs' AND xtype='U')
BEGIN
    CREATE TABLE AccountCOAs (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Code NVARCHAR(20),
        AccountType NVARCHAR(50),
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    
    -- Insert sample accounts
    INSERT INTO AccountCOAs (Name, Code, AccountType) VALUES 
    ('Accounts Payable', 'AP', 'Liability'),
    ('Accounts Receivable', 'AR', 'Asset'),
    ('Cash', 'CASH', 'Asset');
END
GO

-- Create Vendors table (main table)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Vendors' AND xtype='U')
BEGIN
    CREATE TABLE Vendors (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        Email NVARCHAR(MAX) NULL,
        CNo NVARCHAR(MAX) NULL,
        Address NVARCHAR(MAX) NULL,
        NTN NVARCHAR(MAX) NULL,
        STN NVARCHAR(MAX) NULL,
        CPName1 NVARCHAR(MAX) NULL,
        CPEmail1 NVARCHAR(MAX) NULL,
        CPContactNumber1 NVARCHAR(MAX) NULL,
        CPName2 NVARCHAR(MAX) NULL,
        CPEmail2 NVARCHAR(MAX) NULL,
        CPContactNumber2 NVARCHAR(MAX) NULL,
        CountryId INT NULL,
        StateOrProvinceId INT NULL,
        CityId INT NULL,
        BranchId INT NULL,
        IsActive BIT DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME2 NULL,
        Code NVARCHAR(MAX) NULL,
        VendorOrCustomer INT NULL,
        IncomeTaxStatus INT NULL,
        VendorType INT NULL,
        TaxPayerCategoryId INT NULL,
        TaxPayerStatus INT NULL,
        SaleTaxType INT NULL,
        ExemptUnderSRO NVARCHAR(MAX) NULL,
        AccountPayableId INT NULL,
        AccountReceivableId INT NULL,
        CreditStatus INT NULL,
        NetDueDays INT NULL,
        CreditLimit INT NULL,
        FaxNo NVARCHAR(MAX) NULL,
        IsVerified BIT DEFAULT 0,
        
        -- Foreign Key Constraints
        FOREIGN KEY (CountryId) REFERENCES Countries(Id),
        FOREIGN KEY (StateOrProvinceId) REFERENCES StateOrProvinces(Id),
        FOREIGN KEY (CityId) REFERENCES Cities(Id),
        FOREIGN KEY (BranchId) REFERENCES Branches(Id),
        FOREIGN KEY (TaxPayerCategoryId) REFERENCES TaxPayerCategories(Id),
        FOREIGN KEY (AccountPayableId) REFERENCES AccountCOAs(Id),
        FOREIGN KEY (AccountReceivableId) REFERENCES AccountCOAs(Id)
    );
END
GO

PRINT 'Database and tables created successfully!';