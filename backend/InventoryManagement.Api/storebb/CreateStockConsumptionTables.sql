-- =============================================
-- Create Stock Consumption Tables
-- =============================================

USE InventoryManagementDB_SP;
GO

-- Drop existing tables if they exist
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'StockConsumptionDetails' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    DROP TABLE dbo.StockConsumptionDetails;
    PRINT 'Dropped existing table dbo.StockConsumptionDetails.';
END
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'StockConsumptions' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    DROP TABLE dbo.StockConsumptions;
    PRINT 'Dropped existing table dbo.StockConsumptions.';
END
GO

-- Create StockConsumptions table
CREATE TABLE dbo.StockConsumptions (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    StoreId UNIQUEIDENTIFIER NOT NULL,
    Type INT NOT NULL,
    BranchId UNIQUEIDENTIFIER NOT NULL,
    VoucherId UNIQUEIDENTIFIER NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedById UNIQUEIDENTIFIER NULL,
    CreatedOn DATETIME NOT NULL DEFAULT GETUTCDATE(),
    ModifiedById UNIQUEIDENTIFIER NULL,
    ModifiedOn DATETIME NULL,
    IsDeleted BIT NOT NULL DEFAULT 0,
    Remarks NVARCHAR(MAX) NULL
);

PRINT 'Table dbo.StockConsumptions created successfully.';
GO

-- Create StockConsumptionDetails table
CREATE TABLE dbo.StockConsumptionDetails (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    StoreId UNIQUEIDENTIFIER NOT NULL,
    MedicineId UNIQUEIDENTIFIER NULL,
    SubServiceId UNIQUEIDENTIFIER NULL,
    ItemId INT NOT NULL,
    Type INT NOT NULL,
    StockTypeId INT NOT NULL,
    Quantity DECIMAL(18,2) NOT NULL,
    BranchId UNIQUEIDENTIFIER NOT NULL,
    InventoryItemId UNIQUEIDENTIFIER NULL,
    SysBatchNo NVARCHAR(MAX) NULL,
    BatchNo NVARCHAR(MAX) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedById UNIQUEIDENTIFIER NULL,
    CreatedOn DATETIME NOT NULL DEFAULT GETUTCDATE(),
    ModifiedById UNIQUEIDENTIFIER NULL,
    ModifiedOn DATETIME NULL,
    IsDeleted BIT NOT NULL DEFAULT 0,
    StockConsumptionId UNIQUEIDENTIFIER NULL,
    CONSTRAINT FK_StockConsumptionDetails_StockConsumptions 
        FOREIGN KEY (StockConsumptionId) 
        REFERENCES dbo.StockConsumptions(Id)
);

-- Create indexes for better performance
CREATE INDEX IX_StockConsumptionDetails_StockConsumptionId 
    ON dbo.StockConsumptionDetails(StockConsumptionId);

CREATE INDEX IX_StockConsumptionDetails_ItemId 
    ON dbo.StockConsumptionDetails(ItemId);

PRINT 'Table dbo.StockConsumptionDetails created successfully.';
GO

PRINT 'Stock Consumption tables setup completed.';
GO
