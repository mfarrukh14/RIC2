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
    -- and Inv.Stocks/Inv.TransferInventory actually use), NOT Inv.Inventories.StoreId
    -- (that's a separate, unrelated id space - Inv.Stores: Main Warehouse/OT Store/ER
    -- Store). The previous version filtered Received off Inv.Inventories.StoreId, so any
    -- real PharmacyStore selection (e.g. "Central Store") could never match and always
    -- came back as 0 even when the item was actually on hand there.
    --
    -- Balance now comes from Inv.Stocks, the app's canonical live-balance table (same
    -- table StockAudit_Search/Stock Consumption/Stock search already treat as the source
    -- of truth). Received/Issued for the date window are pulled from the real, dated
    -- movement ledgers that exist against that same PharmacyStore id space:
    -- Inv.TransferInventory(Items) for stock moved in/out between stores,
    -- Inv.StockConsumptionDetails for stock dispensed out of a store, and
    -- Inv.StockAdjustmentDetails for manual adjustments - matching the old system, where
    -- every stock-affecting operation (including adjustments) funnels through one
    -- StockTransactions ledger that this report's old-system equivalent reads from, so an
    -- adjustment shows up in Received/Issued exactly like a transfer or consumption would.
    -- Opening is derived from Balance minus net movement in the window, rather than
    -- hardcoded to 0.
    ;WITH StockBalance AS (
        SELECT ItemId, SUM(TotalItems) AS TotalItems
        FROM Inv.Stocks
        WHERE IsActive = 1
          AND (@StoreId IS NULL OR StoreId = @StoreId)
          AND (@BranchId IS NULL OR BranchId = @BranchId)
        GROUP BY ItemId
    ),
    Received AS (
        SELECT ItemId, SUM(Qty) AS Qty
        FROM (
            SELECT ti.ItemId, ti.Quantity AS Qty
            FROM Inv.TransferInventoryItems ti
            INNER JOIN Inv.TransferInventory t ON ti.TransferInventoryId = t.Id
            WHERE ti.IsActive = 1
              AND t.IsActive = 1
              AND (@StoreId IS NULL OR t.ToStoreId = @StoreId)
              AND (@BranchId IS NULL OR t.BranchId = @BranchId)
              AND (@StartDate IS NULL OR t.TransferDate >= @StartDate) AND (@EndDate IS NULL OR t.TransferDate <= @EndDate)

            UNION ALL

            -- Type 2 ("Issue / Increase" in the Stock Adjustment UI) credits stock into the
            -- store - see StockAdjustmentService.ApplyStockEffectAsync's same Type == 2 check.
            SELECT sad.ItemId, sad.Quantity AS Qty
            FROM Inv.StockAdjustmentDetails sad
            INNER JOIN Inv.StockAdjustments sa ON sa.Id = sad.StockAdjustmentId
            WHERE sad.IsDeleted = 0 AND sa.IsDeleted = 0
              AND sad.Type = 2
              AND (@StoreId IS NULL OR sa.StoreId = @StoreId)
              AND (@BranchId IS NULL OR sa.BranchId = @BranchId)
              AND (@StartDate IS NULL OR sad.CreatedOn >= @StartDate) AND (@EndDate IS NULL OR sad.CreatedOn <= @EndDate)
        ) x
        GROUP BY ItemId
    ),
    Issued AS (
        SELECT ItemId, SUM(Qty) AS Qty
        FROM (
            SELECT ti.ItemId, ti.Quantity AS Qty
            FROM Inv.TransferInventoryItems ti
            INNER JOIN Inv.TransferInventory t ON ti.TransferInventoryId = t.Id
            WHERE ti.IsActive = 1
              AND t.IsActive = 1
              AND (@StoreId IS NULL OR t.FromStoreId = @StoreId)
              AND (@BranchId IS NULL OR t.BranchId = @BranchId)
              AND (@StartDate IS NULL OR t.TransferDate >= @StartDate) AND (@EndDate IS NULL OR t.TransferDate <= @EndDate)

            UNION ALL

            SELECT scd.ItemId, scd.Quantity AS Qty
            FROM Inv.StockConsumptionDetails scd
            WHERE scd.IsActive = 1 AND ISNULL(scd.IsDeleted, 0) = 0
              AND (@StoreId IS NULL OR scd.StoreId = @StoreId)
              AND (@BranchId IS NULL OR scd.BranchId = @BranchId)
              AND (@StartDate IS NULL OR scd.CreatedOn >= @StartDate) AND (@EndDate IS NULL OR scd.CreatedOn <= @EndDate)

            UNION ALL

            -- Type 1 ("Less / Decrease") and anything else removes stock from the store -
            -- see StockAdjustmentService.ApplyStockEffectAsync's else branch.
            SELECT sad.ItemId, sad.Quantity AS Qty
            FROM Inv.StockAdjustmentDetails sad
            INNER JOIN Inv.StockAdjustments sa ON sa.Id = sad.StockAdjustmentId
            WHERE sad.IsDeleted = 0 AND sa.IsDeleted = 0
              AND sad.Type <> 2
              AND (@StoreId IS NULL OR sa.StoreId = @StoreId)
              AND (@BranchId IS NULL OR sa.BranchId = @BranchId)
              AND (@StartDate IS NULL OR sad.CreatedOn >= @StartDate) AND (@EndDate IS NULL OR sad.CreatedOn <= @EndDate)
        ) x
        GROUP BY ItemId
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
            CAST(ISNULL(iss.Qty, 0) AS FLOAT) AS Issued
        FROM Inv.Items i
        INNER JOIN MovedItems m ON m.ItemId = i.Id
        LEFT JOIN StockBalance s ON s.ItemId = i.Id
        LEFT JOIN Received r ON r.ItemId = i.Id
        LEFT JOIN Issued iss ON iss.ItemId = i.Id
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
        CAST((Balance - Received + Issued) AS FLOAT) AS Opening,
        Received,
        Issued,
        Balance
    FROM StockMovements
    ORDER BY ItemName;

    DROP TABLE #ItemIds;
END
GO

PRINT 'Stock Stats stored procedures created successfully';
