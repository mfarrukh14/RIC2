-- All 233 rows' StoreId doesn't resolve against Pharmacy.PharmacyStores (Inv.Stores
-- is empty too) - no branch derivable, default to 20 (RIC) per the established pattern.
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.PurchaseRequisitions', Id, BranchId FROM Inv.PurchaseRequisitions WHERE BranchId = 1;

UPDATE Inv.PurchaseRequisitions SET BranchId = 20 WHERE BranchId = 1;

SELECT BranchId, COUNT(*) FROM Inv.PurchaseRequisitions GROUP BY BranchId;
