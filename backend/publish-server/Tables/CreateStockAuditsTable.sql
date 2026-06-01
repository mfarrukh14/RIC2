-- =============================================
-- Create StockAudits Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockAudits')
BEGIN
    CREATE TABLE dbo.StockAudits (
        Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        StoreId UNIQUEIDENTIFIER NOT NULL,
        BranchId UNIQUEIDENTIFIER NOT NULL,
        StockAuditDate DATETIME NOT NULL,
        Remarks NVARCHAR(MAX),
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById UNIQUEIDENTIFIER,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById UNIQUEIDENTIFIER,
        ModifiedOn DATETIME,
        IsDeleted BIT
    );
    
    PRINT 'StockAudits table created successfully';
END
ELSE
BEGIN
    PRINT 'StockAudits table already exists';
END
GO
