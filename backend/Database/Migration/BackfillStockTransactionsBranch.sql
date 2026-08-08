-- The 3 Inv.StockTransactions rows already logged for Central Store (149) /
-- Emergency Store (148) before FixCentralEmergencyStoreBranch.sql ran still carry
-- the stale BranchId=1 the trigger derived at the time. Backfilling them to 20 so
-- this already-completed demand issue/receive shows up in StockStats_Search when
-- filtered by the real branch (20).
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.StockTransactions', Id, BranchId FROM Inv.StockTransactions WHERE StoreId IN (148, 149) AND BranchId = 1;

UPDATE Inv.StockTransactions SET BranchId = 20 WHERE StoreId IN (148, 149) AND BranchId = 1;

SELECT Id, StoreId, ItemId, BranchId, ReceivedQty, IssuedQty, BalanceQty, CreatedOn
FROM Inv.StockTransactions WHERE StoreId IN (148, 149);
