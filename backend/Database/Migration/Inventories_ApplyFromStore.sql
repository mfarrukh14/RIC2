INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.Inventories (store-derived)', Id, BranchId FROM Inv.Inventories;

UPDATE inv
SET inv.BranchId = ps.BranchId
FROM Inv.Inventories inv
JOIN Pharmacy.PharmacyStores ps ON ps.Id = inv.StoreId
WHERE inv.BranchId <> ps.BranchId OR inv.BranchId IS NULL;

UPDATE inv
SET inv.BranchId = 20
FROM Inv.Inventories inv
WHERE NOT EXISTS (SELECT 1 FROM Pharmacy.PharmacyStores ps WHERE ps.Id = inv.StoreId)
  AND (inv.BranchId <> 20 OR inv.BranchId IS NULL);

PRINT 'Post-correction branch distribution:';
SELECT BranchId, COUNT(*) FROM Inv.Inventories GROUP BY BranchId;
