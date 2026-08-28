-- Adds the linkage needed for the "Return Inventory" modal launched from Add
-- Inventory's row action: a return batch now records which Inv.Inventories
-- row it was returned against, and each return line records which
-- Inv.InventoryDetails row (the received GRN/inventory line) it came from -
-- so "how much of this line has already been returned" can be computed by
-- summing prior returns instead of guessed at. All columns are nullable and
-- purely additive - safe on the live shared DB, does not affect any existing
-- row or any other consumer of these tables (mirrors the pattern used
-- throughout this Migration folder, e.g. AlterGRNTablesForPurchaseSummaryMigration.sql).
SET NOCOUNT ON;

IF COL_LENGTH('Inv.ReturnInventory', 'SourceInventoryId') IS NULL
BEGIN
    ALTER TABLE Inv.ReturnInventory ADD SourceInventoryId INT NULL;
    PRINT 'Added Inv.ReturnInventory.SourceInventoryId';
END

IF COL_LENGTH('Inv.ReturnInventory', 'AdjustmentAmount') IS NULL
BEGIN
    ALTER TABLE Inv.ReturnInventory ADD AdjustmentAmount DECIMAL(18,2) NULL;
    PRINT 'Added Inv.ReturnInventory.AdjustmentAmount';
END

IF COL_LENGTH('Inv.ReturnInventory', 'AdjustmentRemarks') IS NULL
BEGIN
    ALTER TABLE Inv.ReturnInventory ADD AdjustmentRemarks NVARCHAR(MAX) NULL;
    PRINT 'Added Inv.ReturnInventory.AdjustmentRemarks';
END

IF COL_LENGTH('Inv.ReturnInventoryItems', 'SourceInventoryDetailId') IS NULL
BEGIN
    ALTER TABLE Inv.ReturnInventoryItems ADD SourceInventoryDetailId INT NULL;
    PRINT 'Added Inv.ReturnInventoryItems.SourceInventoryDetailId';
END

PRINT '=== ReturnInventory source-linkage columns complete ===';
