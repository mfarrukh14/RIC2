-- =============================================================================
-- Backfills Inv.StockTransactions (currently 3 rows, trigger-only since today)
-- from iHealthCure.dbo.StockTransactionHistories (18.9M rows, 2018-07 to
-- 2026-08) for ONE date-range batch at a time - invoke repeatedly with
-- different -v StartDate=/-v EndDate= values (see run log / task notes for
-- the batch plan). Each invocation is its own transaction; a failed batch
-- can simply be re-run (rows are keyed by QID, and the WHERE clause below
-- also excludes CreatedOn already present as an extra guard against
-- accidental double-insert if a batch is re-run after partially committing).
--
-- Column resolution (all via QID infra built earlier in this project):
--   StoreId              -> Pharmacy.PharmacyStores.QID   (98.6% covered;
--                            INNER JOIN - StoreId is NOT NULL on the target,
--                            so an unresolved row is skipped, not guessed)
--   ItemId                -> Inv.Items.QID                 (99.8% covered)
--   BranchMedicineId       -> Pharmacy.BranchMedicines.Qid  (100% covered)
--   BranchSubServiceId     -> Data.BranchFees.QID           (100% covered)
--   BranchId                -> dbo.BranchQidMap.QID
--   InventoryItemId         -> Inv.InventoryDetails.QID     (backfilled this
--                              project; only resolves for finalized/
--                              non-deleted old InventoryItems rows, by design)
--   DemandRequestId          -> Inv.DemandRequests.QID      (99.99% covered)
--   PharmacyChallanFormId    -> Pharmacy.PharmacyChallanForms.QID (100% covered)
--   CreatedBy / ModifiedBy   -> dbo.Users.QID               (92.7% covered)
--   PrescribedInId, TransactionSourceId -> left NULL (no mapping infra for
--     these subsystems - same "don't guess" principle used throughout this
--     project). TransactionSourceType (a plain int code, not an ID) is
--     copied as-is.
--   The old table also has a separate "InventoryId" GUID column distinct
--   from "InventoryItemId" - the new schema has no matching slot for it, so
--   it is not carried over (nothing to resolve it TO).
--
-- Rollback for the WHOLE historical backfill (all batches): the pre-existing
-- 3 live rows all have QID IS NULL (trigger-inserted, never had this column);
-- every row this script (any batch) inserts has QID = the source row's GUID.
-- So `DELETE FROM Inv.StockTransactions WHERE QID IS NOT NULL` cleanly undoes
-- the entire backfill with no separate backup table needed, at this scale.
-- =============================================================================

-- Reads from dbo.StockTransactionHistories_Staging (a local, CreatedOn-
-- clustered one-time copy built by StockTransactions_StagingCopy.sql), not
-- the cross-database source directly - even with a sargable predicate, the
-- optimizer judged seek+lookup against the un-covered source table not worth
-- it at ~2-3% selectivity per batch and kept scanning all 18.9M rows every
-- time (confirmed via actual execution plan). Paying that scan cost once via
-- the staging copy is far cheaper than paying it on every one of ~30+ batches.
-- Date bounds are still sqlcmd-substituted as literals (not a DECLAREd
-- variable) so the optimizer gets a real cardinality estimate off the
-- staging table's clustered CreatedOn index.
PRINT 'Batch: $(StartDate) to $(EndDate)';

INSERT INTO Inv.StockTransactions (
    StoreId, ItemId, BranchMedicineId, BranchSubServiceId, OpeningQty, ReceivedQty, IssuedQty, BalanceQty,
    StockTypeId, BranchId, InventoryItemId, SysBatchNo, BatchNo, TypeBit,
    PrescribedInId, DemandRequestId, PharmacyChallanFormId, TransactionSourceId, TransactionSourceType,
    CreatedOn, ModifiedOn, CreatedBy, ModifiedBy, StockExpiryDate, QID
)
SELECT
    storeMap.Id, itemMap.Id, bmMap.Id, bfMap.Id, src.OpeningQty, src.ReceivedQty, src.IssuedQty, src.BalanceQty,
    src.StockTypeId, branchMap.BranchId, invDetailMap.Id, src.SysBatchNo, src.BatchNo, src.TypeBit,
    NULL, drMap.Id, challanMap.Id, NULL, src.TransactionSourceType,
    src.CreatedOn, src.ModifiedOn, createdByMap.UserID, modifiedByMap.UserID, src.StockExpiryDate, src.ID
FROM dbo.StockTransactionHistories_Staging src
JOIN Pharmacy.PharmacyStores storeMap ON storeMap.QID = src.StoreId
LEFT JOIN Inv.Items itemMap ON itemMap.QID = src.ItemId
LEFT JOIN Pharmacy.BranchMedicines bmMap ON bmMap.Qid = src.BranchMedicineId
LEFT JOIN Data.BranchFees bfMap ON bfMap.QID = src.BranchSubServiceId
LEFT JOIN dbo.BranchQidMap branchMap ON branchMap.QID = src.BranchId
LEFT JOIN Inv.InventoryDetails invDetailMap ON invDetailMap.QID = src.InventoryItemId
LEFT JOIN Inv.DemandRequests drMap ON drMap.QID = src.DemandRequestId
LEFT JOIN Pharmacy.PharmacyChallanForms challanMap ON challanMap.QID = src.PharmacyChallanFormId
LEFT JOIN dbo.Users createdByMap ON createdByMap.QID = src.CreatedBy
LEFT JOIN dbo.Users modifiedByMap ON modifiedByMap.QID = src.ModifiedBy
WHERE src.CreatedOn >= '$(StartDate)' AND src.CreatedOn < '$(EndDate)'
  AND NOT EXISTS (SELECT 1 FROM Inv.StockTransactions t WHERE t.QID = src.ID);

PRINT 'Batch rows inserted:';
SELECT @@ROWCOUNT AS RowsInserted;
