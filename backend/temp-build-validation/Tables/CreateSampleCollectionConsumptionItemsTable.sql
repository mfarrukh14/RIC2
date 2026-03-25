-- Create SampleCollectionConsumptionItems table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SampleCollectionConsumptionItems')
BEGIN
    CREATE TABLE dbo.SampleCollectionConsumptionItems (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ItemId INT NOT NULL,
        MedicineId INT NULL,
        FeeId INT NULL,
        DepartmentId INT NOT NULL,
        BranchId INT NOT NULL,
        Quantity INT NOT NULL,
        CreatedById NVARCHAR(450) NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById NVARCHAR(450) NULL,
        ModifiedOn DATETIME NULL,
        IsDeleted BIT NOT NULL DEFAULT 0,
        IsActive BIT NOT NULL DEFAULT 1,
        CONSTRAINT FK_SampleCollectionConsumptionItems_dbo_Items FOREIGN KEY (ItemId) REFERENCES dbo.Items(Id),
        CONSTRAINT FK_SampleCollectionConsumptionItems_dbo_Branches_BranchId FOREIGN KEY (BranchId) REFERENCES dbo.Branches(Id),
        CONSTRAINT FK_SampleCollectionConsumptionItems_dbo_Departments_DepartmentId FOREIGN KEY (DepartmentId) REFERENCES dbo.Departments(Id)
    );

    PRINT 'SampleCollectionConsumptionItems table created successfully.';
END
ELSE
BEGIN
    PRINT 'SampleCollectionConsumptionItems table already exists.';
END
GO
