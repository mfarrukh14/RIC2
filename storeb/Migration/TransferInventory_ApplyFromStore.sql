INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.TransferInventory (store-derived)', Id, BranchId FROM Inv.TransferInventory;

UPDATE t
SET t.BranchId = ps.BranchId
FROM Inv.TransferInventory t
JOIN Pharmacy.PharmacyStores ps ON ps.Id = t.FromStoreId
WHERE t.BranchId <> ps.BranchId OR t.BranchId IS NULL;

UPDATE t
SET t.BranchId = ps.BranchId
FROM Inv.TransferInventory t
JOIN Pharmacy.PharmacyStores ps ON ps.Id = t.ToStoreId
WHERE NOT EXISTS (SELECT 1 FROM Pharmacy.PharmacyStores p2 WHERE p2.Id = t.FromStoreId)
  AND (t.BranchId <> ps.BranchId OR t.BranchId IS NULL);

UPDATE t
SET t.BranchId = 20
FROM Inv.TransferInventory t
WHERE NOT EXISTS (SELECT 1 FROM Pharmacy.PharmacyStores ps WHERE ps.Id = t.FromStoreId)
  AND NOT EXISTS (SELECT 1 FROM Pharmacy.PharmacyStores ps WHERE ps.Id = t.ToStoreId)
  AND (t.BranchId <> 20 OR t.BranchId IS NULL);

PRINT 'Post-correction branch distribution:';
SELECT BranchId, COUNT(*) FROM Inv.TransferInventory GROUP BY BranchId;
