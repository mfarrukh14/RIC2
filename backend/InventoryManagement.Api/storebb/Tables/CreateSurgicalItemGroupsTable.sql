-- Create SurgicalItemGroups table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SurgicalItemGroups')
BEGIN
    CREATE TABLE dbo.SurgicalItemGroups (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NULL,
        Description NVARCHAR(MAX) NULL,
        BranchId INT NOT NULL,
        SubServiceId NVARCHAR(450) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById NVARCHAR(450) NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById NVARCHAR(450) NULL,
        ModifiedOn DATETIME NULL,
        IsDeleted BIT NOT NULL DEFAULT 0,
        CONSTRAINT FK_dbo_SurgicalItemGroups_dbo_Branches_BranchId FOREIGN KEY (BranchId) REFERENCES dbo.Branches(Id)
    );

    PRINT 'SurgicalItemGroups table created successfully.';
END
ELSE
BEGIN
    PRINT 'SurgicalItemGroups table already exists.';
END
GO
