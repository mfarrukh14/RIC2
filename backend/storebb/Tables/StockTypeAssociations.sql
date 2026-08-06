-- =============================================
-- Create StockTypeAssociations Table
-- =============================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockTypeAssociations')
BEGIN
    CREATE TABLE dbo.StockTypeAssociations (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PharmacyStoreId INT NOT NULL,
        StockTypes INT NOT NULL,
        PatientTypes INT NOT NULL,
        BranchId UNIQUEIDENTIFIER NULL,
        CreatedById UNIQUEIDENTIFIER NOT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById UNIQUEIDENTIFIER NULL,
        ModifiedOn DATETIME NULL,
        IsDeleted BIT NOT NULL DEFAULT 0,
        IsActive INT NOT NULL DEFAULT 1
    );

    PRINT 'Table StockTypeAssociations created successfully.';
END
ELSE
BEGIN
    PRINT 'Table StockTypeAssociations already exists.';
END
GO
