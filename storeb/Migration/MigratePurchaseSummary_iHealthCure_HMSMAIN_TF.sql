-- =============================================================================
-- Migrate iHealthCure's purchase/GRN history (Inventories + InventoryItems)
-- into HMSMAIN_TF's Inv.GoodsReceivingNotes / Inv.GRNItems - the tables the
-- live "Purchase Summary" report (PurchaseSummary_GetAll) actually reads from.
--
-- Run AlterGRNTablesForPurchaseSummaryMigration.sql FIRST (adds the nullable
-- columns this script writes to). Run this ON HMSMAIN_TF, in ONE sqlcmd
-- invocation (temp tables must survive the whole script).
--
-- WHY THIS SCRIPT EXISTS (found during investigation, not assumed):
--   The general MigrateFromIHealthCure_HMSMAIN_TF.sql migration (Phase 5)
--   already copied Inventories/InventoryItems - but into a DIFFERENT,
--   legacy-shaped table pair (Inv.Inventories/Inv.InventoryItems) that nothing
--   in this app's Purchase Summary feature reads. That copy is also
--   incomplete: it INNER JOINs ItemId only, silently dropping any line whose
--   ItemId didn't match Inv.Items - which is 87% of all lines (Medicine/Fee
--   purchases, see below) - and it left UnitBuyingPrice/TotalBuyingPrice at 0
--   because the source Prices table (where the real per-unit price actually
--   lives) was explicitly out of scope for that migration.
--
--   This script instead reads iHealthCure directly and targets the correct
--   tables, fixing both gaps.
--
-- SCOPE: matches exactly what the OLD system's own Purchase Summary report
-- (USP_GetNetPurchaseSummary) showed - Inventories.IsFinalized = 1 and
-- InventoryItems.IsDeleted IS NULL OR 0. Draft/deleted rows were never part
-- of "the original purchase summary data" a user actually saw, so they are
-- not migrated either (44,787 of 45,885 total line items qualify).
--
-- THREE SOURCE TYPES PER LINE ITEM (old report UNIONed these):
--   - "Item"     (ItemId matches iHealthCure Items)      -  5,829 rows (13%)
--   - "Medicine" (MedicineId set, via BranchMedicines)    - 24,933 rows (55%)
--   - "Fee"      (SubServiceId set, via BranchFees)       - 14,019 rows (31%)
--   - unresolved (neither)                                -      6 rows
--
-- ID REMAPPING STRATEGY (verified before writing, not assumed):
--   - Items: Name-only match against Inv.Items. The sibling
--     MigratePharmacyMedicinesStocks_HMSMAIN_TF.sql script originally used
--     Name+CreatedOn and documented that as a clean 1:1 match at the time -
--     but Inv.Items/Pharmacy.PharmacyStores have since been refreshed (every
--     row's CreatedOn is now clustered on today's date, so CreatedOn is no
--     longer a usable discriminator at all). Re-verified immediately before
--     writing this script: Name-only is clean and zero-duplicate on both
--     sides (3224/3224 Items, 145/145 Stores) - safe to use alone.
--   - PharmacyStores: Name-only match against Pharmacy.PharmacyStores, same
--     re-verified reasoning as Items above (145/145, zero duplicates).
--   - PurchaseOrders: PONumber match (mirrors how Inv.PurchaseOrders.PONumber
--     was itself derived by the general migration:
--     ISNULL(PurchaseOrderNumber, CAST(Id AS NVARCHAR(50)))) - verified clean,
--     zero duplicate PONumbers in the target, 371/371 matched.
--   - Vendors / Manufacturers: Name+CreatedOn match was tried and rejected -
--     Vendors: only 302/915 matched due to datetime/datetime2 rounding drift
--     between the two DBs' CreatedOn values (source is `datetime`, ~3ms
--     granularity; target is `datetime2`, sub-millisecond - not always an
--     exact round-trip). Manufacturers: matched but with ~470 ambiguous
--     multi-row fan-outs (duplicate Name+CreatedOn pairs already present in
--     Pharmacy.Manufacturers). Misattributing a purchase's vendor/manufacturer
--     would be worse than not linking it, so these are NOT resolved to a
--     target ID at all - the name is read directly out of iHealthCure (same
--     database instance, zero ambiguity) and stored as plain text.
--   - Medicines / Fees: Pharmacy.Medicines (10,245 rows) and Account.Fees
--     (2,959 rows) are HMS's own native catalogs, NOT a migrated copy of
--     iHealthCure's BranchMedicines (12,213)/BranchFees (4,412) - row counts
--     don't correspond and there is no reliable match key. Names are stored
--     as plain text (DenormalizedItemName) instead of a live FK, same
--     reasoning as Vendors/Manufacturers above.
--   - StockTypes: iHealthCure.dbo.StockTypes.Id === Inv.StockTypes.Id exactly
--     (the general migration preserved these IDs via IDENTITY_INSERT) - no
--     remapping needed.
-- =============================================================================

SET NOCOUNT ON;
PRINT '=== Starting Purchase Summary (GRN) migration: iHealthCure -> HMSMAIN_TF ===';

-- =============================================================================
-- PHASE 0: Rebuild ID maps (verified-safe matches only - see header)
-- =============================================================================

PRINT 'Phase 0: Building ID maps';

CREATE TABLE #ItemMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
INSERT INTO #ItemMap (OldId, NewId)
SELECT src.Id, tgt.Id
FROM iHealthCure.dbo.Items src
JOIN Inv.Items tgt ON tgt.Name = src.Name;

CREATE TABLE #StoreMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
INSERT INTO #StoreMap (OldId, NewId)
SELECT src.Id, tgt.Id
FROM iHealthCure.dbo.PharmacyStores src
JOIN Pharmacy.PharmacyStores tgt ON tgt.Name = src.Name;

CREATE TABLE #POMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
INSERT INTO #POMap (OldId, NewId)
SELECT src.Id, tgt.PurchaseOrderId
FROM iHealthCure.dbo.PurchaseOrders src
JOIN Inv.PurchaseOrders tgt ON tgt.PONumber = ISNULL(src.PurchaseOrderNumber, CONVERT(NVARCHAR(50), src.Id));

PRINT 'Item map rows:';
SELECT COUNT(*) AS ItemMapRows FROM #ItemMap;
PRINT 'Store map rows:';
SELECT COUNT(*) AS StoreMapRows FROM #StoreMap;
PRINT 'PO map rows:';
SELECT COUNT(*) AS POMapRows FROM #POMap;

-- =============================================================================
-- PHASE 1: Inv.GoodsReceivingNotes <- iHealthCure.dbo.Inventories
-- Only IsFinalized = 1 (matches the scope the old report itself ever showed).
-- =============================================================================

PRINT 'Phase 1: GoodsReceivingNotes';

CREATE TABLE #GRNMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);

MERGE INTO Inv.GoodsReceivingNotes AS tgt
USING (
    SELECT
        ins.Id AS OldId,
        poMap.NewId AS PurchaseOrderId,
        ins.InvoiceNo,
        ins.PurchaseOrderNumber AS PONumber,
        ins.StockTypeId,
        ins.CreatedOn AS DateAndTime,
        ins.VendorInvoiceNumber AS VendorInvoiceNo,
        ins.VendorInvoiceTimestamp AS VendorInvoiceDate,
        storeMap.NewId AS StoreId,
        vendor.Name AS DenormalizedVendorName,
        ins.IsActive,
        ins.CreatedOn,
        ins.ModifiedOn
    FROM iHealthCure.dbo.Inventories ins
    LEFT JOIN #POMap poMap ON poMap.OldId = ins.PurchaseOrderId
    LEFT JOIN #StoreMap storeMap ON storeMap.OldId = ins.StoreId
    LEFT JOIN iHealthCure.dbo.Vendors vendor ON vendor.Id = ins.VendorId
    WHERE ins.IsFinalized = 1
) AS s
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (
        PurchaseOrderId, InvoiceNo, PONumber, StockTypeId, DateAndTime,
        VendorInvoiceNo, VendorInvoiceDate, StoreId, DenormalizedVendorName,
        IsActive, CreatedById, CreatedOn, ModifiedById, ModifiedOn
    )
    VALUES (
        s.PurchaseOrderId, s.InvoiceNo, s.PONumber, s.StockTypeId, s.DateAndTime,
        s.VendorInvoiceNo, s.VendorInvoiceDate, s.StoreId, s.DenormalizedVendorName,
        s.IsActive, NULL, s.CreatedOn, NULL, s.ModifiedOn
    )
OUTPUT s.OldId, inserted.Id INTO #GRNMap(OldId, NewId);

PRINT 'GoodsReceivingNotes rows inserted:';
SELECT COUNT(*) AS GRNRowsInserted FROM #GRNMap;

-- =============================================================================
-- PHASE 2: Inv.GRNItems <- iHealthCure.dbo.InventoryItems
-- Scoped to lines under a Phase-1-migrated header, excluding deleted lines.
-- Real per-unit price resolved via Prices (InventoryItems.UnitBuyingPriceId ->
-- Prices.Id -> Prices.Amount) - the piece the original migration skipped.
-- Discount/RetailCharges/GSTCharges amounts computed with the same formula as
-- the old report (USP_GetNetPurchaseSummary): DiscountType = 2 means Discount
-- is a PERCENTAGE of Amount, otherwise it is already an absolute amount.
-- =============================================================================

PRINT 'Phase 2: GRNItems';

INSERT INTO Inv.GRNItems (
    GRNId, ItemId, ManufacturerId, MfgDate, ExpiryDate, RegistrationNumber,
    LotNo, BatchNo, NoOfBoxes, NoOfPackets, ItemPerPacket, TotalItem,
    ReceivedQuantity, RemainingQuantity, TotalBuyingPrice, UnitBuyingPrice,
    AdvanceTaxPercentage, AdvanceTaxAmount, Discount, DiscountAmount,
    RetailCharges, RetailChargesAmount, GSTCharges, GSTChargesAmount,
    MedicineId, SubServiceId, SourceType, DenormalizedItemName,
    DenormalizedManufacturerName
)
SELECT
    grn.NewId,
    itemMap.NewId,
    NULL, -- ManufacturerId: not safely resolvable (see header) - name carried as text instead
    src.ManufacturingDate,
    src.ExpiryDate,
    src.RegistrationNumber,
    src.LotNumber,
    src.Batch,
    src.NumberOfBoxes,
    src.NumberOfPackets,
    src.ItemsPerPacket,
    src.TotalItems,
    src.TotalItems AS ReceivedQuantity, -- matches how PurchaseSummary_GetAll reads "Quantity"
    src.BalanceTotalItems,
    ISNULL(src.TotalItems, 0) * ISNULL(price.Amount, 0) AS TotalBuyingPrice,
    price.Amount AS UnitBuyingPrice, -- the real per-unit price, resolved through Prices (see header)
    src.AdvanceTaxPercentage,
    src.AdvanceTaxCalculatedAmount,
    CASE WHEN ISNULL(src.Discount, 0) <> 0 THEN 1 ELSE 0 END,
    CASE WHEN src.DiscountType = 2 THEN (ISNULL(src.Discount, 0) * ISNULL(src.Amount, 0)) / 100.0
         ELSE ISNULL(src.Discount, 0) END,
    CASE WHEN ISNULL(src.RetailCharges, 0) <> 0 THEN 1 ELSE 0 END,
    src.RetailChargesCalculatedAmount,
    CASE WHEN ISNULL(src.GSTCharges, 0) <> 0 THEN 1 ELSE 0 END,
    src.GSTChargesCalculatedAmount,
    NULL, -- MedicineId: not safely resolvable (see header) - name carried as text instead
    NULL, -- SubServiceId: not safely resolvable (see header) - name carried as text instead
    CASE
        WHEN itemMap.NewId IS NOT NULL THEN 'Item'
        WHEN src.MedicineId IS NOT NULL THEN 'Medicine'
        WHEN src.SubServiceId IS NOT NULL THEN 'Fee'
        ELSE 'Unknown'
    END,
    COALESCE(itemMap.SourceName, med.MedicineFullName, fee.Name, 'Unknown Item'),
    mfr.Name
FROM iHealthCure.dbo.InventoryItems src
JOIN #GRNMap grn ON grn.OldId = src.InventoryId
JOIN iHealthCure.dbo.Inventories ins ON ins.Id = src.InventoryId
LEFT JOIN (
    SELECT im.OldId, im.NewId, i.Name AS SourceName
    FROM #ItemMap im
    JOIN iHealthCure.dbo.Items i ON i.Id = im.OldId
) itemMap ON itemMap.OldId = src.ItemId
LEFT JOIN iHealthCure.dbo.Prices price ON price.Id = src.UnitBuyingPriceId
-- BranchMedicines/BranchFees hold one row PER BRANCH per medicine/fee (not
-- globally unique by MedicineId/FeeId alone) - constraining to the purchase's
-- own originating branch (mirrors the old report's own
-- "AND bm.BranchId = @BranchId" / "AND bf.BranchId = @BranchId" scoping,
-- just using each row's actual branch instead of a single report-time filter
-- value) avoids a fan-out that would otherwise multiply rows for every branch
-- that happens to stock the same medicine/fee.
LEFT JOIN iHealthCure.dbo.BranchMedicines med ON med.MedicineId = src.MedicineId AND med.BranchId = ins.BranchId
LEFT JOIN iHealthCure.dbo.BranchFees fee ON fee.FeeId = src.SubServiceId AND fee.BranchId = ins.BranchId
LEFT JOIN iHealthCure.dbo.Manufacturers mfr ON mfr.Id = src.ManufacturerId
WHERE src.IsDeleted IS NULL OR src.IsDeleted = 0;

PRINT 'GRNItems rows inserted:';
SELECT @@ROWCOUNT AS GRNItemRowsInserted;

PRINT 'Breakdown by SourceType:';
SELECT gi.SourceType, COUNT(*) AS Cnt
FROM Inv.GRNItems gi
JOIN #GRNMap grn ON grn.NewId = gi.GRNId
GROUP BY gi.SourceType
ORDER BY gi.SourceType;

-- =============================================================================
-- Cleanup
-- =============================================================================
DROP TABLE IF EXISTS #ItemMap, #StoreMap, #POMap, #GRNMap;

PRINT '=== Purchase Summary (GRN) migration complete ===';
