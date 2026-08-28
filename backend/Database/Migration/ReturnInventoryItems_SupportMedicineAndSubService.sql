-- Inv.ReturnInventoryItems only ever had ItemId (NOT NULL) - it couldn't record
-- returning a Medicine- or Disposable-sourced GRN line, even though
-- Inv.InventoryDetails (what a GRN/Inventory line actually is) has always
-- supported all three product kinds via ItemId/MedicineId/SubServiceId (see
-- ProductKey.cs, the same three-way pattern used by StockAdjustmentDetails/
-- StockConsumptionDetails/DemandRequestItems). Needed for the batch "Return
-- Inventory" modal launched from Add Inventory, which must be able to return
-- any line on a GRN/Inventory, not just plain-Item ones.
SET NOCOUNT ON;

IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Inv.ReturnInventoryItems') AND name = 'ItemId' AND is_nullable = 0
)
BEGIN
    ALTER TABLE Inv.ReturnInventoryItems ALTER COLUMN ItemId INT NULL;
    PRINT 'Relaxed Inv.ReturnInventoryItems.ItemId to nullable';
END

IF COL_LENGTH('Inv.ReturnInventoryItems', 'MedicineId') IS NULL
BEGIN
    ALTER TABLE Inv.ReturnInventoryItems ADD MedicineId INT NULL;
    PRINT 'Added Inv.ReturnInventoryItems.MedicineId';
END

IF COL_LENGTH('Inv.ReturnInventoryItems', 'SubServiceId') IS NULL
BEGIN
    ALTER TABLE Inv.ReturnInventoryItems ADD SubServiceId INT NULL;
    PRINT 'Added Inv.ReturnInventoryItems.SubServiceId';
END

PRINT '=== ReturnInventoryItems Medicine/SubService support complete ===';
