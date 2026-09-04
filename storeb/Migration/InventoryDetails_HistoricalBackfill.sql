-- =============================================================================
-- Inv.InventoryDetails ("Add Inventory" line items) was never historically
-- migrated - it had only 15 rows (created live today) vs 45,885 rows in
-- iHealthCure.dbo.InventoryItems. Its parent header table Inv.Inventories WAS
-- migrated 1:1 (31148 rows) and just got QID backfilled
-- (Inventories_AddQidAndBackfill.sql). This script inserts the missing
-- historical line items under their correct (now QID-resolvable) header.
--
-- Scope matches what the OLD system's own reports ever showed (same
-- convention already established in MigratePurchaseSummary_iHealthCure_HMSMAIN_TF.sql
-- for the sibling GRNItems migration): Inventories.IsFinalized = 1 and
-- InventoryItems.IsDeleted IS NULL OR 0 -> 44,787 of 45,885 qualify.
--
-- ID remapping:
--   - InventoryId: via Inv.Inventories.QID (backfilled by
--     Inventories_AddQidAndBackfill.sql, 31146/31148 resolved). Rows whose
--     header didn't resolve are skipped (INNER JOIN) - consistent with not
--     guessing a parent.
--   - ItemId: via Inv.Items.QID (already 99.8% populated from earlier in this
--     session's work).
--   - ManufacturerId: NOT resolved. Verified before writing this script:
--     Name-only match against Pharmacy.Manufacturers only resolves 234/707
--     (33%, heavy duplicate-name ambiguity) - same conclusion the sibling
--     GRNItems migration already reached and left NULL rather than guess.
--   - MedicineId / SubServiceId: NOT resolved, same reasoning as
--     MigratePurchaseSummary_iHealthCure_HMSMAIN_TF.sql's header explains -
--     Pharmacy.Medicines/Account.Fees are HMS's own native catalogs, not a
--     migrated copy of iHealthCure's BranchMedicines/BranchFees, so there is
--     no reliable ID correspondence. Historical rows that were originally a
--     Medicine/Fee purchase (87% of qualifying rows) end up with ItemId,
--     MedicineId, and SubServiceId all NULL - unlike GRNItems there is no
--     DenormalizedItemName column here to fall back to, so the QID captured
--     below is the only way to trace those rows back to their original item.
--   - UnitBuyingPrice/UnitSellingPrice/TotalSellingPrice: resolved through
--     iHealthCure.dbo.Prices (the FK old InventoryItems actually points
--     through), same approach as the sibling GRNItems migration.
--   - Discount/RetailCharges/GSTCharges bit + Amount: same formula as the
--     sibling GRNItems migration (from USP_GetNetPurchaseSummary): the bit is
--     "was any charge/discount present at all", DiscountType = 2 means the
--     raw Discount value is a PERCENTAGE of Amount, otherwise it is already
--     an absolute value.
--   - ProfitPerItem/ProfitMarginPerItem: no such column exists on the old
--     side (frontend computes these client-side on live inserts, per
--     InventoryService.cs) - derived here as
--     UnitSellingPrice-UnitBuyingPrice and that difference /UnitBuyingPrice*100.
--   - PackQuantity: left NULL - grep confirms no frontend code anywhere in
--     this app ever sets it (dead column carried over from the GRN schema).
-- =============================================================================

IF COL_LENGTH('Inv.InventoryDetails', 'QID') IS NULL
BEGIN
    ALTER TABLE Inv.InventoryDetails ADD QID UNIQUEIDENTIFIER NULL;
END
GO

IF OBJECT_ID('dbo.InventoryDetails_HistoricalBackfill_Log', 'U') IS NOT NULL
    DROP TABLE dbo.InventoryDetails_HistoricalBackfill_Log;
CREATE TABLE dbo.InventoryDetails_HistoricalBackfill_Log (
    NewId INT NOT NULL,
    OldQID UNIQUEIDENTIFIER NOT NULL,
    InsertedOn DATETIME NOT NULL DEFAULT GETUTCDATE()
);

INSERT INTO Inv.InventoryDetails (
    InventoryId, ItemId, ManufacturerId, MfgDate, ExpiryDate,
    NoOfBoxes, NoOfPackets, ItemsPerPacket, TotalItems, PackQuantity,
    UnitBuyingPrice, TotalBuyingPrice, AdvanceTaxPercentage, AdvanceTaxAmount,
    Discount, DiscountAmount, RetailCharges, RetailChargesAmount,
    GSTCharges, GSTChargesAmount, UnitSellingPrice, TotalSellingPrice,
    ProfitMarginPerItem, ProfitPerItem, MedicineId, SubServiceId, QID
)
OUTPUT inserted.Id, inserted.QID INTO dbo.InventoryDetails_HistoricalBackfill_Log(NewId, OldQID)
SELECT
    invMap.Id AS InventoryId,
    itemMap.Id AS ItemId,
    NULL AS ManufacturerId,
    src.ManufacturingDate,
    src.ExpiryDate,
    src.NumberOfBoxes,
    src.NumberOfPackets,
    src.ItemsPerPacket,
    src.TotalItems,
    NULL AS PackQuantity,
    buyPrice.Amount AS UnitBuyingPrice,
    ISNULL(src.TotalItems, 0) * ISNULL(buyPrice.Amount, 0) AS TotalBuyingPrice,
    src.AdvanceTaxPercentage,
    src.AdvanceTaxCalculatedAmount AS AdvanceTaxAmount,
    CASE WHEN ISNULL(src.Discount, 0) <> 0 THEN 1 ELSE 0 END AS Discount,
    CASE WHEN src.DiscountType = 2 THEN (ISNULL(src.Discount, 0) * ISNULL(src.Amount, 0)) / 100.0
         ELSE ISNULL(src.Discount, 0) END AS DiscountAmount,
    CASE WHEN ISNULL(src.RetailCharges, 0) <> 0 THEN 1 ELSE 0 END AS RetailCharges,
    src.RetailChargesCalculatedAmount AS RetailChargesAmount,
    CASE WHEN ISNULL(src.GSTCharges, 0) <> 0 THEN 1 ELSE 0 END AS GSTCharges,
    src.GSTChargesCalculatedAmount AS GSTChargesAmount,
    sellPrice.Amount AS UnitSellingPrice,
    totalSellPrice.Amount AS TotalSellingPrice,
    CASE WHEN ISNULL(buyPrice.Amount, 0) <> 0 THEN ((ISNULL(sellPrice.Amount, 0) - ISNULL(buyPrice.Amount, 0)) / buyPrice.Amount) * 100.0 ELSE NULL END AS ProfitMarginPerItem,
    (ISNULL(sellPrice.Amount, 0) - ISNULL(buyPrice.Amount, 0)) AS ProfitPerItem,
    NULL AS MedicineId,
    NULL AS SubServiceId,
    src.Id AS QID
FROM iHealthCure.dbo.InventoryItems src
JOIN iHealthCure.dbo.Inventories ins ON ins.Id = src.InventoryId
JOIN Inv.Inventories invMap ON invMap.QID = src.InventoryId
LEFT JOIN Inv.Items itemMap ON itemMap.QID = src.ItemId
LEFT JOIN iHealthCure.dbo.Prices buyPrice ON buyPrice.Id = src.UnitBuyingPriceId
LEFT JOIN iHealthCure.dbo.Prices sellPrice ON sellPrice.Id = src.UnitSellingPriceId
LEFT JOIN iHealthCure.dbo.Prices totalSellPrice ON totalSellPrice.Id = src.TotalSellingPriceId
WHERE ins.IsFinalized = 1
  AND (src.IsDeleted IS NULL OR src.IsDeleted = 0);

PRINT 'InventoryDetails historical backfill inserted:';
SELECT COUNT(*) AS RowsInserted FROM dbo.InventoryDetails_HistoricalBackfill_Log;
PRINT 'InventoryDetails final counts:';
SELECT COUNT(*) AS Total, COUNT(QID) AS WithQid, COUNT(ItemId) AS WithItemId FROM Inv.InventoryDetails;
