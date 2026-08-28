-- =============================================================================
-- Migrate iHealthCure.dbo.PharmacyMedicinesStocks into HMSMAIN_TF's
-- Pharmacy.PharmacyMedicinesStocks (found empty - 0 rows - even though the
-- equivalent Inv.Stocks table was already populated by Phase 6 of
-- MigrateFromIHealthCure_HMSMAIN_TF.sql). Pharmacy.PharmacyMedicinesStocks is
-- apparently a second, separate consumer of the same source data that the
-- original migration never touched.
--
-- Run this ON HMSMAIN_TF (reaches iHealthCure via 3-part names, same server).
--
-- ID REMAPPING: iHealthCure StoreId/ItemId are uniqueidentifier; the target
-- columns are int. The original migration's #StoreMap/#ItemMap temp tables
-- only existed for the duration of that one script run and were discarded,
-- and Pharmacy.PharmacyStores / Inv.Items are no longer empty - so they can't
-- be rebuilt by re-running that script's INSERT logic (that would duplicate
-- every store and item). Instead, the maps are reconstructed here by matching
-- on (Name, CreatedOn), which the original migration passed through from
-- iHealthCure unchanged - verified as a clean, 1:1, zero-duplicate match
-- against both tables before writing this script (145/145 stores, 3224/3224
-- items).
--
-- BranchMedicineId / BranchSubServiceId / InventoryItemId are also
-- uniqueidentifier on the source with no equivalent map (nothing in
-- HMSMAIN_TF tracks the old iHealthCure BranchMedicine/SubService/
-- InventoryItem GUIDs) - left NULL rather than invented; all three are
-- nullable on the target.
--
-- CreatedBy is NOT NULL on the target, but Users were never migrated (no
-- iHealthCure GUID -> HMSMAIN_TF UserID map exists, same as the rest of this
-- migration). Per explicit instruction, using dbo.Users.UserID = 1671
-- ('admin', UserTypeId = 1 / Super Admin Role, Status = 1) as a fixed
-- placeholder - this is NOT a real attribution of who created each stock
-- row, just the only way to satisfy the NOT NULL constraint. ModifiedBy IS
-- nullable on the target and is left NULL (no placeholder invented there).
-- =============================================================================

SET NOCOUNT ON;
PRINT '=== Migrating iHealthCure.dbo.PharmacyMedicinesStocks -> Pharmacy.PharmacyMedicinesStocks ===';

DECLARE @MigrationUserId INT = 1671; -- dbo.Users 'admin' (Super Admin Role) - CreatedBy placeholder only

CREATE TABLE #StoreMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
INSERT INTO #StoreMap (OldId, NewId)
SELECT src.Id, tgt.Id
FROM iHealthCure.dbo.PharmacyStores src
JOIN Pharmacy.PharmacyStores tgt ON tgt.Name = src.Name AND tgt.CreatedOn = src.CreatedOn;

CREATE TABLE #ItemMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
INSERT INTO #ItemMap (OldId, NewId)
SELECT src.Id, tgt.Id
FROM iHealthCure.dbo.Items src
JOIN Inv.Items tgt ON tgt.Name = src.Name AND tgt.CreatedOn = src.CreatedOn;

PRINT 'Store map rows built:';
SELECT COUNT(*) AS StoreMapRows FROM #StoreMap;
PRINT 'Item map rows built:';
SELECT COUNT(*) AS ItemMapRows FROM #ItemMap;

PRINT 'Source row count:';
SELECT COUNT(*) AS SourceRows FROM iHealthCure.dbo.PharmacyMedicinesStocks;

INSERT INTO Pharmacy.PharmacyMedicinesStocks (
    StoreId, BranchMedicineId, BranchSubServiceId, TotalItemsInStock, MinimumPanicLevel,
    TypeBit, CreatedBy, CreatedOn, ModifiedBy, ModifiedOn, ItemId, TotalItemsInTransition,
    Price, StockTypeId, InventoryItemId, SysBatchNo, BatchNo, StockExpiryDate
)
SELECT
    sm.NewId,
    NULL, -- BranchMedicineId: no source->target map available
    NULL, -- BranchSubServiceId: no source->target map available
    src.TotalItemsInStock,
    src.MinimumPanicLevel,
    src.TypeBit,
    @MigrationUserId,
    src.CreatedOn,
    NULL, -- ModifiedBy: nullable, no user map available
    src.ModifiedOn,
    im.NewId, -- ItemId: nullable, NULL when source ItemId was NULL or didn't match #ItemMap
    src.TotalItemsInTransition,
    src.Price,
    src.StockTypeId,
    NULL, -- InventoryItemId: no source->target map available
    src.SysBatchNo,
    src.BatchNo,
    src.StockExpiryDate
FROM iHealthCure.dbo.PharmacyMedicinesStocks src
JOIN #StoreMap sm ON sm.OldId = src.StoreId
LEFT JOIN #ItemMap im ON im.OldId = src.ItemId;

PRINT 'Rows inserted into Pharmacy.PharmacyMedicinesStocks:';
SELECT COUNT(*) AS InsertedRows FROM Pharmacy.PharmacyMedicinesStocks;

PRINT '=== Migration complete ===';
