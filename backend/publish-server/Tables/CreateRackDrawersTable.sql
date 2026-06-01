-- =============================================
-- Create RackRows Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RackRows')
BEGIN
    CREATE TABLE dbo.RackRows (
        Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        Name NVARCHAR(255) NOT NULL,
        Description NVARCHAR(MAX),
        StoreId INT NOT NULL,
        RackId INT NOT NULL,
        BranchId UNIQUEIDENTIFIER,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById UNIQUEIDENTIFIER,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById UNIQUEIDENTIFIER,
        ModifiedOn DATETIME,
        CONSTRAINT FK_RackRows_Stores FOREIGN KEY (StoreId) REFERENCES dbo.Stores(StoreId),
        CONSTRAINT FK_RackRows_Racks FOREIGN KEY (RackId) REFERENCES dbo.Racks(Id)
    );
    
    PRINT 'RackRows table created successfully';
END
ELSE
BEGIN
    PRINT 'RackRows table already exists';
END
GO

-- =============================================
-- Create RackColumns Table  
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RackColumns')
BEGIN
    CREATE TABLE dbo.RackColumns (
        Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        Name NVARCHAR(255) NOT NULL,
        Description NVARCHAR(MAX),
        StoreId INT NOT NULL,
        RackId INT NOT NULL,
        BranchId UNIQUEIDENTIFIER,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById UNIQUEIDENTIFIER,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById UNIQUEIDENTIFIER,
        ModifiedOn DATETIME,
        CONSTRAINT FK_RackColumns_Stores FOREIGN KEY (StoreId) REFERENCES dbo.Stores(StoreId),
        CONSTRAINT FK_RackColumns_Racks FOREIGN KEY (RackId) REFERENCES dbo.Racks(Id)
    );
    
    PRINT 'RackColumns table created successfully';
END
ELSE
BEGIN
    PRINT 'RackColumns table already exists';
END
GO

-- =============================================
-- Create RackDrawers Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RackDrawers')
BEGIN
    CREATE TABLE dbo.RackDrawers (
        Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        Name NVARCHAR(255) NOT NULL,
        Description NVARCHAR(MAX),
        StoreId INT NOT NULL,
        RackId INT NOT NULL,
        RackRowId UNIQUEIDENTIFIER,
        RackColumnId UNIQUEIDENTIFIER,
        BranchId UNIQUEIDENTIFIER,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById UNIQUEIDENTIFIER,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById UNIQUEIDENTIFIER,
        ModifiedOn DATETIME,
        CONSTRAINT FK_RackDrawers_Stores FOREIGN KEY (StoreId) REFERENCES dbo.Stores(StoreId),
        CONSTRAINT FK_RackDrawers_Racks FOREIGN KEY (RackId) REFERENCES dbo.Racks(Id),
        CONSTRAINT FK_RackDrawers_RackRows FOREIGN KEY (RackRowId) REFERENCES dbo.RackRows(RackRowId),
        CONSTRAINT FK_RackDrawers_RackColumns FOREIGN KEY (RackColumnId) REFERENCES dbo.RackColumns(Id)
    );
    
    PRINT 'RackDrawers table created successfully';
END
ELSE
BEGIN
    PRINT 'RackDrawers table already exists';
END
GO
