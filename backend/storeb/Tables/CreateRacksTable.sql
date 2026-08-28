-- =============================================
-- Create Racks Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Racks')
BEGIN
    CREATE TABLE dbo.Racks (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX),
        Description NVARCHAR(MAX),
        Location NVARCHAR(MAX),
        NumberOfRows INT NOT NULL,
        NumberOfCols INT NOT NULL,
        NumberOfDraws INT NOT NULL,
        StoreId UNIQUEIDENTIFIER NOT NULL,
        BranchId UNIQUEIDENTIFIER NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById UNIQUEIDENTIFIER,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById UNIQUEIDENTIFIER,
        ModifiedOn DATETIME
    );
    
    PRINT 'Racks table created successfully';
END
ELSE
BEGIN
    PRINT 'Racks table already exists';
END
GO
