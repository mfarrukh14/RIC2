-- =============================================
-- Create SpaceAllocations Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SpaceAllocations')
BEGIN
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
    
    PRINT 'SpaceAllocations table created successfully';
END
ELSE
BEGIN
    PRINT 'SpaceAllocations table already exists';
END
GO
