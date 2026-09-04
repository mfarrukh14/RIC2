-- Create ItemTypeSaleLevels table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ItemTypeSaleLevels')
BEGIN
    CREATE TABLE dbo.ItemTypeSaleLevels (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ItemTypeId INT NOT NULL,
        FastRunningLevel INT NOT NULL,
        SlowMovingLevel INT NOT NULL,
        DeadLevel INT NOT NULL,
        BranchId INT NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById NVARCHAR(450) NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById NVARCHAR(450) NULL,
        ModifiedOn DATETIME NULL,
        IsDeleted BIT NOT NULL DEFAULT 0,
        CONSTRAINT FK_dbo_ItemTypeSaleLevels_dbo_Branches_BranchId FOREIGN KEY (BranchId) REFERENCES dbo.Branches(Id),
        CONSTRAINT FK_dbo_ItemTypeSaleLevels_dbo_ItemTypes_ItemTypeId FOREIGN KEY (ItemTypeId) REFERENCES dbo.ItemTypes(Id)
    );

    PRINT 'ItemTypeSaleLevels table created successfully.';
END
ELSE
BEGIN
    PRINT 'ItemTypeSaleLevels table already exists.';
END
GO
