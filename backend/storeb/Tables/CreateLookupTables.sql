-- Create FinancialYears table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FinancialYears')
BEGIN
    CREATE TABLE dbo.FinancialYears (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        StartDate DATETIME NOT NULL,
        EndDate DATETIME NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById NVARCHAR(450) NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById NVARCHAR(450) NULL,
        ModifiedOn DATETIME NULL
    );

    -- Insert default financial year
    INSERT INTO dbo.FinancialYears (Name, StartDate, EndDate, IsActive, CreatedOn)
    VALUES ('2025-2026', '2025-07-01', '2026-06-30', 1, GETDATE());

    PRINT 'FinancialYears table created successfully.';
END
ELSE
BEGIN
    PRINT 'FinancialYears table already exists.';
END
GO

-- Create PurchaseOrderTypes table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PurchaseOrderTypes')
BEGIN
    CREATE TABLE dbo.PurchaseOrderTypes (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById NVARCHAR(450) NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById NVARCHAR(450) NULL,
        ModifiedOn DATETIME NULL
    );

    -- Insert default types
    INSERT INTO dbo.PurchaseOrderTypes (Name, IsActive, CreatedOn)
    VALUES 
        ('Direct Purchase', 1, GETDATE()),
        ('Tender', 1, GETDATE()),
        ('Emergency', 1, GETDATE());

    PRINT 'PurchaseOrderTypes table created successfully.';
END
ELSE
BEGIN
    PRINT 'PurchaseOrderTypes table already exists.';
END
GO
