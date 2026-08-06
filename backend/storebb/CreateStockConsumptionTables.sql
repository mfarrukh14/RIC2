-- =============================================
-- Create Stock Consumption Tables
-- Idempotent: only creates the tables if missing. Must never unconditionally
-- drop/recreate these - on a live database that destroys real consumption
-- data on every app restart. Int-typed to match the Inv schema convention
-- (Inv.StockConsumptions/StockConsumptionDetails on the reference database).
-- =============================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockConsumptions' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.StockConsumptions (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        StoreId INT NOT NULL,
        Type INT NOT NULL,
        BranchId INT NOT NULL,
        VoucherId INT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETUTCDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL,
        IsDeleted BIT NOT NULL DEFAULT 0,
        Remarks NVARCHAR(MAX) NULL
    );

    PRINT 'Table dbo.StockConsumptions created successfully.';
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockConsumptionDetails' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.StockConsumptionDetails (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        StoreId INT NOT NULL,
        MedicineId INT NULL,
        SubServiceId INT NULL,
        ItemId INT NOT NULL,
        Type INT NOT NULL,
        StockTypeId INT NOT NULL,
        Quantity DECIMAL(18,2) NOT NULL,
        BranchId INT NOT NULL,
        InventoryItemId INT NULL,
        SysBatchNo NVARCHAR(MAX) NULL,
        BatchNo NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETUTCDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL,
        IsDeleted BIT NOT NULL DEFAULT 0,
        StockConsumptionId INT NULL
    );

    CREATE INDEX IX_StockConsumptionDetails_StockConsumptionId
        ON dbo.StockConsumptionDetails(StockConsumptionId);

    CREATE INDEX IX_StockConsumptionDetails_ItemId
        ON dbo.StockConsumptionDetails(ItemId);

    PRINT 'Table dbo.StockConsumptionDetails created successfully.';
END
GO

PRINT 'Stock Consumption tables setup completed.';
GO
