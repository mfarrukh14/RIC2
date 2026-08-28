-- =============================================================================
-- Additive schema changes needed before migrating iHealthCure purchase/GRN
-- history into Inv.GoodsReceivingNotes / Inv.GRNItems (see
-- MigratePurchaseSummary_iHealthCure_HMSMAIN_TF.sql, which depends on this).
--
-- All columns are nullable and purely additive - safe on the live shared DB,
-- does not affect any existing row or any other consumer of these tables.
--
-- WHY EACH COLUMN EXISTS:
--   - Inv.GoodsReceivingNotes.StoreId: the OLD iHealthCure Inventories table had
--     its own direct StoreId FK. The current GoodsReceivingNotes table only
--     resolves a store indirectly via its linked PurchaseOrder - which fails for
--     any GRN with no PO attached (the old system's "Inventory" ReportType).
--     This column preserves that direct link for migrated rows so Store
--     filtering/display doesn't silently break for them. PurchaseSummary_GetAll
--     is updated to fall back to this column when there is no PO.
--   - Inv.GoodsReceivingNotes.DenormalizedVendorName /
--     Inv.GRNItems.DenormalizedManufacturerName: iHealthCure's Vendors/
--     Manufacturers tables do NOT have a safe, unambiguous ID match against
--     this DB's Inv.Vendors/Pharmacy.Manufacturers (Name+CreatedOn matching -
--     the technique already proven safe elsewhere in this migration for
--     Items/Stores/PurchaseOrders - produces duplicate/ambiguous matches here:
--     see investigation notes in MigratePurchaseSummary_iHealthCure_HMSMAIN_TF.sql).
--     Rather than risk mis-attributing a purchase to the wrong vendor/
--     manufacturer, the name is carried over as plain text, read directly out
--     of iHealthCure at migration time (zero ambiguity - no matching involved).
--   - Inv.GRNItems.SourceType / DenormalizedItemName: iHealthCure's purchase
--     line items are one of three source types - real Items, Medicines
--     (BranchMedicines), or clinical Fees/services (BranchFees) - unioned
--     together in the old report. Only the "Item" case (13% of rows) has a
--     safe FK match into this DB's Inv.Items. Medicine/Fee purchases (87% of
--     rows) are preserved with their name as text and SourceType='Medicine'/
--     'Fee' so they still show up in Purchase Summary, just without a live
--     item-catalog link.
-- =============================================================================

SET NOCOUNT ON;

IF COL_LENGTH('Inv.GoodsReceivingNotes', 'StoreId') IS NULL
BEGIN
    ALTER TABLE Inv.GoodsReceivingNotes ADD StoreId INT NULL;
    PRINT 'Added Inv.GoodsReceivingNotes.StoreId';
END

IF COL_LENGTH('Inv.GoodsReceivingNotes', 'DenormalizedVendorName') IS NULL
BEGIN
    ALTER TABLE Inv.GoodsReceivingNotes ADD DenormalizedVendorName NVARCHAR(255) NULL;
    PRINT 'Added Inv.GoodsReceivingNotes.DenormalizedVendorName';
END

IF COL_LENGTH('Inv.GRNItems', 'SourceType') IS NULL
BEGIN
    ALTER TABLE Inv.GRNItems ADD SourceType NVARCHAR(20) NULL;
    PRINT 'Added Inv.GRNItems.SourceType';
END

IF COL_LENGTH('Inv.GRNItems', 'DenormalizedItemName') IS NULL
BEGIN
    ALTER TABLE Inv.GRNItems ADD DenormalizedItemName NVARCHAR(500) NULL;
    PRINT 'Added Inv.GRNItems.DenormalizedItemName';
END

IF COL_LENGTH('Inv.GRNItems', 'DenormalizedManufacturerName') IS NULL
BEGIN
    ALTER TABLE Inv.GRNItems ADD DenormalizedManufacturerName NVARCHAR(255) NULL;
    PRINT 'Added Inv.GRNItems.DenormalizedManufacturerName';
END

-- iHealthCure's InventoryItems.LotNumber holds up to 431 chars in practice
-- (some rows pack a comma-separated list of multiple lot numbers into one
-- field) - GRNItems.LotNo was only NVARCHAR(100), which would silently
-- truncate real data during migration. Widened rather than truncated.
IF (SELECT CHARACTER_MAXIMUM_LENGTH FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'Inv' AND TABLE_NAME = 'GRNItems' AND COLUMN_NAME = 'LotNo') < 500
BEGIN
    ALTER TABLE Inv.GRNItems ALTER COLUMN LotNo NVARCHAR(500) NULL;
    PRINT 'Widened Inv.GRNItems.LotNo to NVARCHAR(500)';
END

-- Inv.GRNItems had no index on GRNId at all (only its own Id PK) before this
-- migration made the table large (81,000+ rows). PurchaseSummaryInvoice_GetAll
-- does a correlated OUTER APPLY ... WHERE gi.GRNId = g.Id per GoodsReceivingNotes
-- row (30,000+ of them) - without this index that's a full table scan repeated
-- per row, which took 60+ seconds (observed hanging/appearing as "no data" in
-- the UI, since the request never completed). With the index: ~5 seconds.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Inv.GRNItems') AND name = 'IX_GRNItems_GRNId')
BEGIN
    CREATE NONCLUSTERED INDEX IX_GRNItems_GRNId ON Inv.GRNItems (GRNId);
    PRINT 'Created index IX_GRNItems_GRNId on Inv.GRNItems(GRNId)';
END

PRINT '=== GRN table alterations complete ===';
