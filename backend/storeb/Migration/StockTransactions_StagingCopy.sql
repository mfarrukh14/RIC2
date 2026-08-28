-- =============================================================================
-- One-time copy of iHealthCure.dbo.StockTransactionHistories (18.9M rows) into
-- a local staging table on HMSMAIN_TF, clustered on CreatedOn.
--
-- WHY: the batched backfill (StockTransactions_HistoricalBackfill_Batch.sql)
-- was doing a full Clustered Index Scan of the 18.9M-row source table on
-- EVERY batch (verified via actual execution plan) - at ~2.5% selectivity per
-- batch, the optimizer correctly judged seek+lookup as not cheaper than a
-- scan given no covering index exists. Rather than pay that full-scan cost
-- 30+ times (once per batch), pay it ONCE here, then every batch reads from
-- this local, CreatedOn-clustered copy instead - fast range scans, no
-- cross-database calls.
-- =============================================================================

IF OBJECT_ID('dbo.StockTransactionHistories_Staging', 'U') IS NOT NULL
    DROP TABLE dbo.StockTransactionHistories_Staging;

SELECT
    ID, StoreId, BranchMedicineId, BranchSubServiceId, OpeningQty, ReceivedQty, IssuedQty, BalanceQty,
    TypeBit, PrescribedInId, BranchId, CreatedBy, CreatedOn, ModifiedBy, ModifiedOn, ItemId,
    DemandRequestId, PharmacyChallanFormId, TransactionSourceId, TransactionSourceType, StockTypeId,
    InventoryItemId, SysBatchNo, BatchNo, StockExpiryDate
INTO dbo.StockTransactionHistories_Staging
FROM iHealthCure.dbo.StockTransactionHistories;

CREATE CLUSTERED INDEX IX_Staging_CreatedOn ON dbo.StockTransactionHistories_Staging(CreatedOn);
CREATE UNIQUE NONCLUSTERED INDEX IX_Staging_ID ON dbo.StockTransactionHistories_Staging(ID);

PRINT 'Staging copy complete:';
SELECT COUNT(*) AS TotalRows, MIN(CreatedOn) AS MinDate, MAX(CreatedOn) AS MaxDate FROM dbo.StockTransactionHistories_Staging;
