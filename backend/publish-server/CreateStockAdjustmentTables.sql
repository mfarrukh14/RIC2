-- =============================================
-- Create Stock Adjustment Tables
-- =============================================

USE InventoryManagementDB_SP;
GO

-- Drop existing tables if they exist
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'StockAdjustmentDetails' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    DROP TABLE dbo.StockAdjustmentDetails;
    PRINT 'Dropped existing table dbo.StockAdjustmentDetails.';
END
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'StockAdjustments' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    DROP TABLE dbo.StockAdjustments;
    PRINT 'Dropped existing table dbo.StockAdjustments.';
END
GO

-- Create StockAdjustments table
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
GO

-- Create StockAdjustmentDetails table
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
    SaleValue DECIMAL(18,2) NULL,
    CONSTRAINT FK_StockAdjustmentDetails_StockAdjustments 
        FOREIGN KEY (StockAdjustmentId) 
        REFERENCES dbo.StockAdjustments(Id)
);

-- Create indexes for better performance
CREATE INDEX IX_StockAdjustmentDetails_StockAdjustmentId 
    ON dbo.StockAdjustmentDetails(StockAdjustmentId);

CREATE INDEX IX_StockAdjustmentDetails_ItemId 
    ON dbo.StockAdjustmentDetails(ItemId);

PRINT 'Table dbo.StockAdjustmentDetails created successfully.';
GO

PRINT 'Stock Adjustment tables setup completed.';
GO
