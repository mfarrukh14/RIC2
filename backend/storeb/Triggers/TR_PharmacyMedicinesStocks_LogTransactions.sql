-- =============================================
-- Trigger: Pharmacy.TR_PharmacyMedicinesStocks_LogTransactions
-- =============================================
-- The original HMS design funnels every stock-affecting operation through
-- Pharmacy.SP_Stock_UpdateStockBalance, which both updates the balance AND writes a row to
-- Inv.StockTransactions (OpeningQty/ReceivedQty/IssuedQty/BalanceQty per movement) - that
-- ledger is what the old system's stock reports read from. Our app never calls that proc:
-- 9 different code paths (GRN receiving, Add Inventory, Transfer, Stock Consumption, Stock
-- Adjustment, Demand Request dispatch/receive, Pharmacy retail dispensing, Return
-- Inventory, manual Stock edits) each UPDATE/INSERT Pharmacy.PharmacyMedicinesStocks
-- directly with their own SQL. Result: Inv.StockTransactions had only 8 rows total (stale
-- demo seed data), and StockDetailRecord_GetReport/StockStats_Search/StockBalance_GetReport
-- had to reconstruct "Received"/"Issued" by UNIONing 4 of those 9 paths - permanently
-- missing pharmacy retail sales and demand-request movements, which produced negative
-- Opening balances (an item could show units added via one tracked path with 0 tracked
-- Issued, while its real current balance is 0 - the missing ~1200 units left through an
-- untracked path).
--
-- Rather than retrofit 9 separate call sites (each touching a currently-working, and in
-- DemandRequestService's case just-fixed, live flow - real regression risk), this trigger
-- centralizes the fix: it fires on every INSERT/UPDATE to Pharmacy.PharmacyMedicinesStocks
-- regardless of which code path caused it, and logs the before/after balance as a proper
-- ledger row. No existing C#/SQL mutation code needs to change. Going forward this table is
-- a complete, accurate ledger; historical movements before this trigger was created are
-- not backfilled (no historical record of the "before" state exists to reconstruct from).
IF OBJECT_ID('Pharmacy.TR_PharmacyMedicinesStocks_LogTransactions', 'TR') IS NOT NULL
    DROP TRIGGER Pharmacy.TR_PharmacyMedicinesStocks_LogTransactions;
GO

CREATE TRIGGER Pharmacy.TR_PharmacyMedicinesStocks_LogTransactions
ON Pharmacy.PharmacyMedicinesStocks
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Inv.StockTransactions
        (StoreId, ItemId, BranchMedicineId, BranchSubServiceId, OpeningQty, ReceivedQty, IssuedQty, BalanceQty,
         StockTypeId, TypeBit, BranchId, InventoryItemId, SysBatchNo, BatchNo, StockExpiryDate,
         CreatedBy, CreatedOn, ModifiedBy, ModifiedOn)
    SELECT
        i.StoreId, i.ItemId, i.BranchMedicineId, i.BranchSubServiceId,
        ISNULL(d.TotalItemsInStock, 0) AS OpeningQty,
        CASE WHEN i.TotalItemsInStock > ISNULL(d.TotalItemsInStock, 0) THEN i.TotalItemsInStock - ISNULL(d.TotalItemsInStock, 0) ELSE 0 END AS ReceivedQty,
        CASE WHEN i.TotalItemsInStock < ISNULL(d.TotalItemsInStock, 0) THEN ISNULL(d.TotalItemsInStock, 0) - i.TotalItemsInStock ELSE 0 END AS IssuedQty,
        i.TotalItemsInStock AS BalanceQty,
        i.StockTypeId, i.TypeBit, ps.BranchId, i.InventoryItemId, i.SysBatchNo, i.BatchNo, i.StockExpiryDate,
        ISNULL(i.ModifiedBy, i.CreatedBy), GETDATE(), i.ModifiedBy, ISNULL(i.ModifiedOn, i.CreatedOn)
    FROM inserted i
    LEFT JOIN deleted d ON d.Id = i.Id
    LEFT JOIN Inv.PharmacyStores ps ON ps.StoreId = i.StoreId
    -- Skip no-op updates (e.g. Price/MinimumPanicLevel-only changes) that don't actually
    -- move the balance - only log real quantity movements.
    WHERE i.TotalItemsInStock <> ISNULL(d.TotalItemsInStock, -999999999);
END
GO

PRINT 'Pharmacy.TR_PharmacyMedicinesStocks_LogTransactions created successfully';
GO
