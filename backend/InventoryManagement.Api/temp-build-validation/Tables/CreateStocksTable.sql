-- =============================================
-- Create Stocks Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Stocks')
BEGIN
    CREATE TABLE dbo.Stocks (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ItemId UNIQUEIDENTIFIER NOT NULL,
        TotalItems INT,
        MinimumPanicLevel INT,
        BranchId UNIQUEIDENTIFIER NOT NULL,
        StoreId UNIQUEIDENTIFIER NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById UNIQUEIDENTIFIER,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById UNIQUEIDENTIFIER,
        ModifiedOn DATETIME
    );
    
    PRINT 'Stocks table created successfully';
END
ELSE
BEGIN
    PRINT 'Stocks table already exists';
END
GO
