-- =============================================
-- Create lookup tables for Items
-- =============================================
USE InventoryManagementDB_SP;
GO

-- Create Categories table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Categories' AND xtype='U')
BEGIN
    CREATE TABLE Categories (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX),
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    
    INSERT INTO Categories (Name, Description) VALUES 
    ('Medical Lab Equipment', 'Medical laboratory equipment and supplies'),
    ('Surgical Disposable', 'Surgical disposable items'),
    ('Medicine / Surgical disposable', 'Medicine and surgical disposables'),
    ('Wastage', 'Wastage items');
END
GO

-- Create SubCategories table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='SubCategories' AND xtype='U')
BEGIN
    CREATE TABLE SubCategories (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX),
        CategoryId INT,
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL,
        FOREIGN KEY (CategoryId) REFERENCES Categories(Id)
    );
    
    INSERT INTO SubCategories (Name, CategoryId) VALUES 
    ('Lab Reagents', 1),
    ('Surgical Instruments', 2),
    ('Disposable Syringes', 2),
    ('Other', 1);
END
GO

-- Create Prices table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Prices' AND xtype='U')
BEGIN
    CREATE TABLE Prices (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        RetailPrice DECIMAL(18,4) DEFAULT 0,
        SalePrice DECIMAL(18,4) DEFAULT 0,
        MarketPrice DECIMAL(18,4) DEFAULT 0,
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
END
GO

-- Create TaxRates table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='TaxRates' AND xtype='U')
BEGIN
    CREATE TABLE TaxRates (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Rate DECIMAL(5,2) NOT NULL,
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    
    INSERT INTO TaxRates (Name, Rate) VALUES 
    ('GST 18%', 18.00),
    ('GST 12%', 12.00),
    ('GST 5%', 5.00),
    ('No Tax', 0.00);
END
GO

-- Create TaxDescriptions table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='TaxDescriptions' AND xtype='U')
BEGIN
    CREATE TABLE TaxDescriptions (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX),
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    
    INSERT INTO TaxDescriptions (Name, Description) VALUES 
    ('Standard Rated', 'Standard tax rate applicable'),
    ('Zero Rated', 'Zero tax rate'),
    ('Exempt', 'Tax exempt');
END
GO

-- Create TaxTypes table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='TaxTypes' AND xtype='U')
BEGIN
    CREATE TABLE TaxTypes (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Description NVARCHAR(MAX),
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    
    INSERT INTO TaxTypes (Name, Description) VALUES 
    ('Sales Tax', 'Tax on sales'),
    ('Purchase Tax', 'Tax on purchases'),
    ('Both', 'Both sales and purchase tax');
END
GO

PRINT 'Lookup tables created successfully!';