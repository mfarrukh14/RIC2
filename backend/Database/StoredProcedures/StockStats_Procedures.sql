-- =============================================
-- Stock Stats Stored Procedures
-- =============================================

-- =============================================
-- StockStats_Search
-- =============================================
IF OBJECT_ID('dbo.StockStats_Search', 'P') IS NOT NULL
    DROP PROCEDURE dbo.StockStats_Search;
GO

CREATE PROCEDURE dbo.StockStats_Search
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @ItemTypeId INT = NULL,
    @ItemIds NVARCHAR(MAX) = NULL, -- Comma-separated INTs
    @StockTypeId INT = NULL,
    @SaleType NVARCHAR(50) = 'OverAll' -- OverAll, OPD, Emergency, IPD, OutDoorPharmacy (not tracked yet, reserved)
AS
BEGIN
    SET NOCOUNT ON;

    -- Create temp table for item IDs
    CREATE TABLE #ItemIds (ItemId INT);

    -- Parse ItemIds
    IF @ItemIds IS NOT NULL AND @ItemIds != ''
    BEGIN
        INSERT INTO #ItemIds (ItemId)
        SELECT TRY_CAST(value AS INT)
        FROM STRING_SPLIT(@ItemIds, ',')
        WHERE TRY_CAST(value AS INT) IS NOT NULL;
    END

    -- @StoreId/@BranchId here are Inv.PharmacyStores ids (what the Store filter dropdown
    -- and Pharmacy.PharmacyMedicinesStocks/Inv.TransferInventory actually use), NOT
    -- Inv.Inventories.StoreId (that's a separate, unrelated id space - Inv.Stores: Main
    -- Warehouse/OT Store/ER Store). The previous version filtered Received off
    -- Inv.Inventories.StoreId, so any real PharmacyStore selection (e.g. "Central Store")
    -- could never match and always came back as 0 even when the item was actually on hand
    -- there.
    --
    -- Balance comes from Pharmacy.PharmacyMedicinesStocks, the live-balance table the real
    -- HMS pharmacy operations update (see Stock_Procedures.sql header for why it's not
    -- Inv.Stocks). That table has no BranchId column, so @BranchId is applied via a join to
    -- Inv.PharmacyStores instead.
    --
    -- Received/Issued/Opening now read from Inv.StockTransactions, the real ledger every
    -- stock movement writes to via Pharmacy.TR_PharmacyMedicinesStocks_LogTransactions (see
    -- that trigger's header). Previously Received/Issued were reconstructed by UNIONing
    -- only 3 of the 9 real stock-mutation paths (Transfer, Stock Adjustment, Stock
    -- Consumption) - pharmacy retail dispensing and demand-request movements were
    -- completely invisible, so an item could show equal-looking Received with far less
    -- Issued than actually left the store, producing negative Opening. Opening is anchored
    -- off the CURRENT balance (always "now") minus every ledgered movement from @StartDate
    -- to now, not off a snapshot at @StartDate - none exists prior to the trigger's
    -- creation, so windows starting before that degrade gracefully (Opening ~= current
    -- balance) rather than going wrong.
    ;WITH StockBalance AS (
        SELECT s.ItemId, SUM(s.TotalItemsInStock) AS TotalItems
        FROM Pharmacy.PharmacyMedicinesStocks s
        LEFT JOIN Inv.PharmacyStores ps ON ps.StoreId = s.StoreId
        WHERE (@StoreId IS NULL OR s.StoreId = @StoreId)
          AND (@BranchId IS NULL OR ps.BranchId = @BranchId)
        GROUP BY s.ItemId
    ),
    Received AS (
        SELECT st.ItemId, SUM(st.ReceivedQty) AS Qty
        FROM Inv.StockTransactions st
        WHERE st.ItemId IS NOT NULL
          AND (@StoreId IS NULL OR st.StoreId = @StoreId)
          AND (@BranchId IS NULL OR st.BranchId = @BranchId)
          AND (@StartDate IS NULL OR st.CreatedOn >= @StartDate) AND (@EndDate IS NULL OR st.CreatedOn < DATEADD(DAY, 1, @EndDate))
        GROUP BY st.ItemId
    ),
    Issued AS (
        SELECT st.ItemId, SUM(st.IssuedQty) AS Qty
        FROM Inv.StockTransactions st
        WHERE st.ItemId IS NOT NULL
          AND (@StoreId IS NULL OR st.StoreId = @StoreId)
          AND (@BranchId IS NULL OR st.BranchId = @BranchId)
          AND (@StartDate IS NULL OR st.CreatedOn >= @StartDate) AND (@EndDate IS NULL OR st.CreatedOn < DATEADD(DAY, 1, @EndDate))
        GROUP BY st.ItemId
    ),
    NetSinceStart AS (
        SELECT st.ItemId, SUM(st.ReceivedQty) - SUM(st.IssuedQty) AS NetQty
        FROM Inv.StockTransactions st
        WHERE st.ItemId IS NOT NULL
          AND (@StoreId IS NULL OR st.StoreId = @StoreId)
          AND (@BranchId IS NULL OR st.BranchId = @BranchId)
          AND (@StartDate IS NULL OR st.CreatedOn >= @StartDate)
        GROUP BY st.ItemId
    ),
    -- Old system's stock transaction report (SP_Pharmacy_StockTransactionReport) builds
    -- its query FROM the StockTransactions ledger and INNER JOINs out to the item - an
    -- item with zero rows in that ledger for the window simply never appears in the
    -- report. Mirror that here: only items with an actual Received or Issued movement in
    -- the window are included (a nonzero standing Balance with no movement in-window does
    -- NOT qualify on its own), instead of listing every active Inv.Item and left-joining
    -- movement data onto it (which surfaced items that have never had any stock activity
    -- at all as bogus all-zero rows).
    MovedItems AS (
        SELECT ItemId FROM Received
        UNION
        SELECT ItemId FROM Issued
    ),
    StockMovements AS (
        SELECT
            i.Id AS ItemId,
            i.Name AS ItemName,
            COALESCE(st.Name, 'Regular') AS StockType,
            CAST(ISNULL(s.TotalItems, 0) AS FLOAT) AS Balance,
            CAST(ISNULL(r.Qty, 0) AS FLOAT) AS Received,
            CAST(ISNULL(iss.Qty, 0) AS FLOAT) AS Issued,
            CAST(ISNULL(s.TotalItems, 0) - ISNULL(ns.NetQty, 0) AS FLOAT) AS Opening
        FROM Inv.Items i
        INNER JOIN MovedItems m ON m.ItemId = i.Id
        LEFT JOIN StockBalance s ON s.ItemId = i.Id
        LEFT JOIN Received r ON r.ItemId = i.Id
        LEFT JOIN Issued iss ON iss.ItemId = i.Id
        LEFT JOIN NetSinceStart ns ON ns.ItemId = i.Id
        OUTER APPLY
        (
            SELECT TOP 1 latest.StockTypeId
            FROM Inv.InventoryDetails d
            INNER JOIN Inv.Inventories latest ON d.InventoryId = latest.Id
            WHERE d.ItemId = i.Id
              AND latest.IsActive = 1
            ORDER BY COALESCE(latest.ModifiedOn, latest.CreatedOn) DESC, latest.Id DESC
        ) latestInventory
        LEFT JOIN Inv.StockTypes st ON latestInventory.StockTypeId = st.Id
        WHERE
            (@ItemTypeId IS NULL OR i.ItemTypeId = @ItemTypeId)
            AND (@StockTypeId IS NULL OR latestInventory.StockTypeId = @StockTypeId)
            AND (NOT EXISTS(SELECT 1 FROM #ItemIds) OR i.Id IN (SELECT ItemId FROM #ItemIds))
            AND i.IsActive = 1
    )
    SELECT
        ItemId,
        ItemName,
        StockType,
        Opening,
        Received,
        Issued,
        Balance
    FROM StockMovements
    ORDER BY ItemName;

    DROP TABLE #ItemIds;
END
GO

PRINT 'Stock Stats stored procedures created successfully';
