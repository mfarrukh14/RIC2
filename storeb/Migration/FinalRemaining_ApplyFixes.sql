-- Backup everything about to change
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.StockConsumptionDetails', Id, BranchId FROM Inv.StockConsumptionDetails WHERE BranchId = 1;
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.StockAdjustmentDetails', Id, BranchId FROM Inv.StockAdjustmentDetails WHERE BranchId = 1;
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.InventoryItems', Id, BranchId FROM Inv.InventoryItems WHERE BranchId = 1;
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.PurchaseSummaries', Id, BranchId FROM Inv.PurchaseSummaries WHERE BranchId = 1;
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.ReturnInventory', Id, BranchId FROM Inv.ReturnInventory WHERE BranchId = 1;
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.StockAudits', Id, BranchId FROM Inv.StockAudits WHERE BranchId = 1;
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.ContingentBills', Id, BranchId FROM Inv.ContingentBills WHERE BranchId = 1;
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.Items', Id, BranchId FROM Inv.Items WHERE BranchId = 1;
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.ItemTypeSaleLevels', Id, BranchId FROM Inv.ItemTypeSaleLevels WHERE BranchId = 1;
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.DemandRequestStatuses', Id, BranchId FROM Inv.DemandRequestStatuses WHERE BranchId = 1;
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Data.BranchSubDepartments', BSubDId, BranchId FROM Data.BranchSubDepartments WHERE BranchId = 1;
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.SurgicalItemGroups (unused-by-app, orphan table)', Id, BranchId FROM Inv.SurgicalItemGroups WHERE BranchId = 1;

-- Derive from already-corrected parent: StockConsumptionDetails <- StockConsumptions
UPDATE d SET d.BranchId = sc.BranchId
FROM Inv.StockConsumptionDetails d JOIN Inv.StockConsumptions sc ON sc.Id = d.StockConsumptionId
WHERE d.BranchId = 1;

-- Derive from already-corrected parent: StockAdjustmentDetails <- StockAdjustments
UPDATE d SET d.BranchId = sa.BranchId
FROM Inv.StockAdjustmentDetails d JOIN Inv.StockAdjustments sa ON sa.Id = d.StockAdjustmentId
WHERE d.BranchId = 1;

-- Derive from already-corrected parent: InventoryItems <- Inventories
UPDATE ii SET ii.BranchId = inv.BranchId
FROM Inv.InventoryItems ii JOIN Inv.Inventories inv ON inv.Id = ii.InventoryId
WHERE ii.BranchId = 1;
-- any InventoryItems whose InventoryId didn't match an Inventories row: default to 20
UPDATE ii SET ii.BranchId = 20
FROM Inv.InventoryItems ii
WHERE ii.BranchId = 1;

-- Store-derived: PurchaseSummaries, ReturnInventory, StockAudits, ContingentBills
UPDATE t SET t.BranchId = ps.BranchId
FROM Inv.PurchaseSummaries t JOIN Pharmacy.PharmacyStores ps ON ps.Id = t.StoreId
WHERE t.BranchId = 1;
UPDATE t SET t.BranchId = 20 FROM Inv.PurchaseSummaries t WHERE t.BranchId = 1;

UPDATE t SET t.BranchId = ps.BranchId
FROM Inv.ReturnInventory t JOIN Pharmacy.PharmacyStores ps ON ps.Id = t.StoreId
WHERE t.BranchId = 1;
UPDATE t SET t.BranchId = 20 FROM Inv.ReturnInventory t WHERE t.BranchId = 1;

UPDATE t SET t.BranchId = ps.BranchId
FROM Inv.StockAudits t JOIN Pharmacy.PharmacyStores ps ON ps.Id = t.StoreId
WHERE t.BranchId = 1;
UPDATE t SET t.BranchId = 20 FROM Inv.StockAudits t WHERE t.BranchId = 1;

UPDATE t SET t.BranchId = ps.BranchId
FROM Inv.ContingentBills t JOIN Pharmacy.PharmacyStores ps ON ps.Id = t.StoreId
WHERE t.BranchId = 1;
UPDATE t SET t.BranchId = 20 FROM Inv.ContingentBills t WHERE t.BranchId = 1;

-- No derivable link (seed/demo data or global lookups) - default to 20
UPDATE Inv.Items SET BranchId = 20 WHERE BranchId = 1;
UPDATE Inv.ItemTypeSaleLevels SET BranchId = 20 WHERE BranchId = 1;
UPDATE Inv.DemandRequestStatuses SET BranchId = 20 WHERE BranchId = 1;
UPDATE Data.BranchSubDepartments SET BranchId = 20 WHERE BranchId = 1;

PRINT 'Done. Remaining BranchId=1 counts (should all be 0 or unrelated to Inv/Pharmacy/Data):';
SELECT 'StockConsumptionDetails' , COUNT(*) FROM Inv.StockConsumptionDetails WHERE BranchId=1
UNION ALL SELECT 'StockAdjustmentDetails', COUNT(*) FROM Inv.StockAdjustmentDetails WHERE BranchId=1
UNION ALL SELECT 'InventoryItems', COUNT(*) FROM Inv.InventoryItems WHERE BranchId=1
UNION ALL SELECT 'PurchaseSummaries', COUNT(*) FROM Inv.PurchaseSummaries WHERE BranchId=1
UNION ALL SELECT 'ReturnInventory', COUNT(*) FROM Inv.ReturnInventory WHERE BranchId=1
UNION ALL SELECT 'StockAudits', COUNT(*) FROM Inv.StockAudits WHERE BranchId=1
UNION ALL SELECT 'ContingentBills', COUNT(*) FROM Inv.ContingentBills WHERE BranchId=1
UNION ALL SELECT 'Items', COUNT(*) FROM Inv.Items WHERE BranchId=1
UNION ALL SELECT 'ItemTypeSaleLevels', COUNT(*) FROM Inv.ItemTypeSaleLevels WHERE BranchId=1
UNION ALL SELECT 'DemandRequestStatuses', COUNT(*) FROM Inv.DemandRequestStatuses WHERE BranchId=1
UNION ALL SELECT 'BranchSubDepartments', COUNT(*) FROM Data.BranchSubDepartments WHERE BranchId=1;
