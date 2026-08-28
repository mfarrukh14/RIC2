-- =============================================================================
-- Add MedicineId/SubServiceId to the detail tables that didn't already have
-- them, matching the pattern already present on InventoryItems/
-- StockAdjustmentDetails/StockConsumptionDetails. These let a transaction
-- line reference a real Inv.Items row, OR a Pharmacy.Medicines row, OR an
-- Account.Fees row (Disposable-typed) - exactly one populated per row -
-- mirroring how the original iHealthCure system treats items/medicines/
-- disposables as one unified pick-list while keeping them in separate
-- tables. See Item_GetAllWithMedicines for the unified lookup this feeds.
-- =============================================================================

IF COL_LENGTH('dbo.InventoryDetails', 'MedicineId') IS NULL
BEGIN
    ALTER TABLE dbo.InventoryDetails ADD MedicineId INT NULL;
END
GO

IF COL_LENGTH('dbo.InventoryDetails', 'SubServiceId') IS NULL
BEGIN
    ALTER TABLE dbo.InventoryDetails ADD SubServiceId INT NULL;
END
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.InventoryDetails') AND name = 'ItemId' AND is_nullable = 0)
BEGIN
    ALTER TABLE dbo.InventoryDetails ALTER COLUMN ItemId INT NULL;
END
GO

IF COL_LENGTH('dbo.GRNItems', 'MedicineId') IS NULL
BEGIN
    ALTER TABLE dbo.GRNItems ADD MedicineId INT NULL;
END
GO

IF COL_LENGTH('dbo.GRNItems', 'SubServiceId') IS NULL
BEGIN
    ALTER TABLE dbo.GRNItems ADD SubServiceId INT NULL;
END
GO

IF COL_LENGTH('dbo.DemandRequestItems', 'MedicineId') IS NULL
BEGIN
    ALTER TABLE dbo.DemandRequestItems ADD MedicineId INT NULL;
END
GO

IF COL_LENGTH('dbo.DemandRequestItems', 'SubServiceId') IS NULL
BEGIN
    ALTER TABLE dbo.DemandRequestItems ADD SubServiceId INT NULL;
END
GO

IF COL_LENGTH('dbo.PurchaseOrderItems', 'MedicineId') IS NULL
BEGIN
    ALTER TABLE dbo.PurchaseOrderItems ADD MedicineId INT NULL;
END
GO

IF COL_LENGTH('dbo.PurchaseOrderItems', 'SubServiceId') IS NULL
BEGIN
    ALTER TABLE dbo.PurchaseOrderItems ADD SubServiceId INT NULL;
END
GO

IF COL_LENGTH('dbo.PurchaseRequisitionItems', 'MedicineId') IS NULL
BEGIN
    ALTER TABLE dbo.PurchaseRequisitionItems ADD MedicineId INT NULL;
END
GO

IF COL_LENGTH('dbo.PurchaseRequisitionItems', 'SubServiceId') IS NULL
BEGIN
    ALTER TABLE dbo.PurchaseRequisitionItems ADD SubServiceId INT NULL;
END
GO

IF COL_LENGTH('dbo.Stocks', 'MedicineId') IS NULL
BEGIN
    ALTER TABLE dbo.Stocks ADD MedicineId INT NULL;
END
GO

IF COL_LENGTH('dbo.Stocks', 'SubServiceId') IS NULL
BEGIN
    ALTER TABLE dbo.Stocks ADD SubServiceId INT NULL;
END
GO

-- ItemId itself must also become nullable on these - a line can now identify
-- its product via MedicineId or SubServiceId instead, with no ItemId at all.
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.DemandRequestItems') AND name = 'ItemId' AND is_nullable = 0)
BEGIN
    ALTER TABLE dbo.DemandRequestItems ALTER COLUMN ItemId INT NULL;
END
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.GRNItems') AND name = 'ItemId' AND is_nullable = 0)
BEGIN
    ALTER TABLE dbo.GRNItems ALTER COLUMN ItemId INT NULL;
END
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.PurchaseOrderItems') AND name = 'ItemId' AND is_nullable = 0)
BEGIN
    ALTER TABLE dbo.PurchaseOrderItems ALTER COLUMN ItemId INT NULL;
END
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.StockAdjustmentDetails') AND name = 'ItemId' AND is_nullable = 0)
BEGIN
    ALTER TABLE dbo.StockAdjustmentDetails ALTER COLUMN ItemId INT NULL;
END
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.StockConsumptionDetails') AND name = 'ItemId' AND is_nullable = 0)
BEGIN
    ALTER TABLE dbo.StockConsumptionDetails ALTER COLUMN ItemId INT NULL;
END
GO
