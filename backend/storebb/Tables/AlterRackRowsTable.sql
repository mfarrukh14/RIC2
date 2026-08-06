-- =============================================
-- Alter RackRows Table to match new schema
-- =============================================

-- Check if we need to update the RackRows table
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.RackRows') AND name = 'RackRowId')
BEGIN
    PRINT 'Updating RackRows table schema...';
    
    -- Drop foreign key constraint from RackDrawers if it exists
    IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_RackDrawers_RackRows')
    BEGIN
        ALTER TABLE dbo.RackDrawers DROP CONSTRAINT FK_RackDrawers_RackRows;
        PRINT 'Dropped FK_RackDrawers_RackRows constraint';
    END

    -- Drop foreign key constraints from old RackRows table
    IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_RackRows_Racks')
    BEGIN
        ALTER TABLE dbo.RackRows DROP CONSTRAINT FK_RackRows_Racks;
        PRINT 'Dropped FK_RackRows_Racks constraint';
    END

    IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_RackRows_Stores')
    BEGIN
        ALTER TABLE dbo.RackRows DROP CONSTRAINT FK_RackRows_Stores;
        PRINT 'Dropped FK_RackRows_Stores constraint';
    END

    -- Create a temporary table with the new schema
    CREATE TABLE dbo.RackRows_New (
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
    
    PRINT 'Created temporary RackRows_New table';

    -- Migrate existing data
    INSERT INTO dbo.RackRows_New (Id, Name, RackId, IsActive, CreatedOn, ModifiedOn, StoreId, Description)
    SELECT 
        RackRowId AS Id,
        Name,
        RackId,
        IsActive,
        CreatedOn,
        ModifiedOn,
        1 AS StoreId, -- Default to first store, update as needed
        NULL AS Description
    FROM dbo.RackRows;
    
    PRINT 'Migrated data from old RackRows table';

    -- Update RackDrawers to use new column name
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.RackDrawers') AND name = 'RackRowId')
    BEGIN
        -- RackDrawers still uses RackRowId, keep it for now
        PRINT 'RackDrawers.RackRowId column exists - will maintain compatibility';
    END

    -- Drop old table
    DROP TABLE dbo.RackRows;
    PRINT 'Dropped old RackRows table';

    -- Rename new table
    EXEC sp_rename 'dbo.RackRows_New', 'RackRows';
    PRINT 'Renamed RackRows_New to RackRows';

    -- Recreate foreign key constraint in RackDrawers
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.RackDrawers') AND name = 'RackRowId')
    BEGIN
        ALTER TABLE dbo.RackDrawers 
        ADD CONSTRAINT FK_RackDrawers_RackRows 
        FOREIGN KEY (RackRowId) REFERENCES dbo.RackRows(Id);
        
        PRINT 'Recreated FK_RackDrawers_RackRows constraint';
    END

    PRINT 'RackRows table schema updated successfully';
END
ELSE
BEGIN
    PRINT 'RackRows table already has new schema (Id column exists)';
END
GO
