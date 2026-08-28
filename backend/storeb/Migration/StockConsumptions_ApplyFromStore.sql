-- Inv.StockConsumptions.BranchId corrected by deriving it from the row's own
-- StoreId -> Pharmacy.PharmacyStores.BranchId (the same store-derived approach
-- Pharmacy.TR_PharmacyMedicinesStocks_LogTransactions already uses for stock
-- transactions) rather than trying to re-trace each header row individually -
-- StoreId+CreatedOn+Type is not a reliable natural key here (only ~53% unique).
-- 2055 rows reference a StoreId that exists in neither Pharmacy.PharmacyStores
-- nor Inv.Stores (which is completely empty) - no branch derivable, defaulted
-- to 20 (RIC) as the only real operating branch, consistent with every other
-- untraceable case found in this investigation.

INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.StockConsumptions (store-derived)', Id, BranchId FROM Inv.StockConsumptions;

UPDATE sc
SET sc.BranchId = ps.BranchId
FROM Inv.StockConsumptions sc
JOIN Pharmacy.PharmacyStores ps ON ps.Id = sc.StoreId
WHERE sc.BranchId <> ps.BranchId OR sc.BranchId IS NULL;

UPDATE sc
SET sc.BranchId = 20
FROM Inv.StockConsumptions sc
WHERE NOT EXISTS (SELECT 1 FROM Pharmacy.PharmacyStores ps WHERE ps.Id = sc.StoreId)
  AND (sc.BranchId <> 20 OR sc.BranchId IS NULL);

PRINT 'Post-correction branch distribution:';
SELECT BranchId, COUNT(*) FROM Inv.StockConsumptions GROUP BY BranchId;
