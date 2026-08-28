INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.Stocks (store-derived)', Id, BranchId FROM Inv.Stocks;

UPDATE s
SET s.BranchId = ps.BranchId
FROM Inv.Stocks s
JOIN Pharmacy.PharmacyStores ps ON ps.Id = s.StoreId
WHERE s.BranchId <> ps.BranchId OR s.BranchId IS NULL;

UPDATE s
SET s.BranchId = 20
FROM Inv.Stocks s
WHERE NOT EXISTS (SELECT 1 FROM Pharmacy.PharmacyStores ps WHERE ps.Id = s.StoreId)
  AND (s.BranchId <> 20 OR s.BranchId IS NULL);

PRINT 'Post-correction branch distribution:';
SELECT BranchId, COUNT(*) FROM Inv.Stocks GROUP BY BranchId;
