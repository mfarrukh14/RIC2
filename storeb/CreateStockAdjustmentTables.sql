-- =============================================
-- Create Stock Adjustment Tables
-- Idempotent: only creates the tables if missing. Must never unconditionally
-- drop/recreate these - on a live database that destroys real adjustment
-- data on every app restart.
-- =============================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockAdjustments' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.StockAdjustments (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        StoreId INT NOT NULL,
        Type INT NOT NULL, -- 1 = Less/Decrease, 2 = Issue
        VoucherId INT NULL,
        BranchId INT NOT NULL,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETUTCDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        IsDeleted BIT NOT NULL DEFAULT 0
    );

    PRINT 'Table dbo.StockAdjustments created successfully.';
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockAdjustmentDetails' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.StockAdjustmentDetails (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        StockAdjustmentId INT NOT NULL,
        MedicineId INT NULL,
        SubServiceId INT NULL,
        ItemId INT NOT NULL,
        Type INT NOT NULL, -- 1 = Less/Decrease, 2 = Issue
        StockTypeId INT NOT NULL,
        Quantity DECIMAL(18,2) NOT NULL,
        BranchId INT NOT NULL,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETUTCDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        IsDeleted BIT NOT NULL DEFAULT 0,
        InventoryItemId INT NULL,
        SysBatchNo NVARCHAR(255) NULL,
        BatchNo NVARCHAR(255) NULL,
        StockAdjustmentId2 INT NULL,
        PurchaseValue DECIMAL(18,2) NULL,
        SaleValue DECIMAL(18,2) NULL
    );

    CREATE INDEX IX_StockAdjustmentDetails_StockAdjustmentId
        ON dbo.StockAdjustmentDetails(StockAdjustmentId);

    CREATE INDEX IX_StockAdjustmentDetails_ItemId
        ON dbo.StockAdjustmentDetails(ItemId);

    PRINT 'Table dbo.StockAdjustmentDetails created successfully.';
END
GO

PRINT 'Stock Adjustment tables setup completed.';
GO
