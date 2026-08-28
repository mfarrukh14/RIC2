-- =============================================
-- Fix: Create RackDrawers and SpaceAllocations Tables
-- =============================================

USE InventoryManagementDB_SP;
GO

-- =============================================
-- 1. Create RackDrawers Table (corrected foreign keys)
-- =============================================
PRINT 'Creating RackDrawers table...';
GO

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
        CONSTRAINT FK_RackDrawers_RackRows FOREIGN KEY (RackRowId) REFERENCES dbo.RackRows(Id),
        CONSTRAINT FK_RackDrawers_RackColumns FOREIGN KEY (RackColumnId) REFERENCES dbo.RackColumns(Id)
    );
    
    PRINT '✓ RackDrawers table created successfully';
END
ELSE
BEGIN
    PRINT '✓ RackDrawers table already exists';
END
GO

-- =============================================
-- 2. Create SpaceAllocations Table
-- =============================================
PRINT 'Creating SpaceAllocations table...';
GO

-- Drop if exists to recreate with correct structure
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'SpaceAllocations')
BEGIN
    DROP TABLE dbo.SpaceAllocations;
    PRINT 'Dropped existing SpaceAllocations table';
END
GO

CREATE TABLE dbo.SpaceAllocations (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    StoreId INT NOT NULL,
    ItemId UNIQUEIDENTIFIER NOT NULL,
    FeeId UNIQUEIDENTIFIER,
    RackId INT NOT NULL,
    RackRowId UNIQUEIDENTIFIER,
    RackColumnId UNIQUEIDENTIFIER,
    RackDrawerId UNIQUEIDENTIFIER,
    MedicineId UNIQUEIDENTIFIER,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedById UNIQUEIDENTIFIER,
    CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
    ModifiedById UNIQUEIDENTIFIER,
    ModifiedOn DATETIME,
    CONSTRAINT FK_SpaceAllocations_Stores FOREIGN KEY (StoreId) REFERENCES dbo.Stores(StoreId),
    CONSTRAINT FK_SpaceAllocations_Racks FOREIGN KEY (RackId) REFERENCES dbo.Racks(Id),
    CONSTRAINT FK_SpaceAllocations_RackRows FOREIGN KEY (RackRowId) REFERENCES dbo.RackRows(Id),
    CONSTRAINT FK_SpaceAllocations_RackColumns FOREIGN KEY (RackColumnId) REFERENCES dbo.RackColumns(Id),
    CONSTRAINT FK_SpaceAllocations_RackDrawers FOREIGN KEY (RackDrawerId) REFERENCES dbo.RackDrawers(Id)
);

PRINT '✓ SpaceAllocations table created successfully';
GO

-- =============================================
-- 3. Verify Tables
-- =============================================
PRINT '';
PRINT 'Verifying tables...';
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'RackDrawers')
    PRINT '✓ RackDrawers table exists';
ELSE
    PRINT '✗ RackDrawers table MISSING!';

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'SpaceAllocations')
    PRINT '✓ SpaceAllocations table exists';
ELSE
    PRINT '✗ SpaceAllocations table MISSING!';

PRINT '';
PRINT '=============================================';
PRINT 'Setup completed! Restart your API.';
PRINT '=============================================';
GO
