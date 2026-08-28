-- =============================================
-- Migrate Store Allocation to User 1:1 from the real live table
-- =============================================
-- Inv.StoreAllocationToUser (this app's own table) was never synced from the real,
-- native HMS table for this exact feature: Pharmacy.UserPharmacyStores (Id, UserId,
-- PharmacyStoreId, CreatedById, CreatedOn, ModifiedById, ModifiedOn, IsDeleted, IsActive -
-- 6 real rows). Inv.StoreAllocationToUser only had 2 rows, both created today while
-- testing this session's fixes (a subset of the same UserId/StoreId combos, but with test
-- timestamps, not the originals). Add the missing IsDeleted column for full 1:1 schema
-- parity, clear the test rows, and migrate all 6 real rows with their original identity
-- preserved (CreatedById/CreatedOn/ModifiedById/ModifiedOn/IsActive/IsDeleted).

IF COL_LENGTH('Inv.StoreAllocationToUser', 'IsDeleted') IS NULL
BEGIN
    ALTER TABLE Inv.StoreAllocationToUser ADD IsDeleted BIT NOT NULL DEFAULT 0;
END
GO

DELETE FROM Inv.StoreAllocationToUser;
GO

SET IDENTITY_INSERT Inv.StoreAllocationToUser ON;
GO

INSERT INTO Inv.StoreAllocationToUser (Id, StoreId, UserId, BranchId, IsActive, IsDeleted, CreatedById, CreatedOn, ModifiedById, ModifiedOn)
SELECT
    ups.Id,
    ups.PharmacyStoreId,
    ups.UserId,
    (SELECT TOP 1 BranchId FROM Pharmacy.PharmacyStores WHERE Id = ups.PharmacyStoreId),
    ups.IsActive,
    ups.IsDeleted,
    ups.CreatedById,
    ups.CreatedOn,
    ups.ModifiedById,
    ups.ModifiedOn
FROM Pharmacy.UserPharmacyStores ups;
GO

SET IDENTITY_INSERT Inv.StoreAllocationToUser OFF;
GO

PRINT 'Migrated ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + ' rows (last statement) - see SELECT COUNT(*) below for actual total';
SELECT COUNT(*) AS MigratedRowCount FROM Inv.StoreAllocationToUser;
GO
