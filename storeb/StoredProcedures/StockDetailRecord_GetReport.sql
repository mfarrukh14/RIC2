-- Stored procedure to get pharmacy stock detail records
--
-- Rewritten again to read from Inv.StockTransactions, the real ledger every stock
-- movement now writes to via Pharmacy.TR_PharmacyMedicinesStocks_LogTransactions (see
-- that trigger's header for the full story). The previous version reconstructed
-- Received/Issued by UNIONing 4 of the 9 real stock-mutation paths (Transfer, Stock
-- Adjustment, GRN, Add Inventory) - it could never see pharmacy retail dispensing or
-- demand-request movements, which silently drained stock the report had no record of
-- "leaving", producing negative Opening balances (e.g. an item with 1218 units added via
-- one tracked path, 0 tracked Issued, but a real current balance of 0).
--
-- Opening is anchored off the CURRENT balance (Pharmacy.PharmacyMedicinesStocks, always
-- "now") minus every ledgered movement from @StartDate to now - not off a snapshot at
-- @StartDate, because none exists. Received/Issued for display are still windowed to
-- [@StartDate, @EndDate] as before. The ledger only started being populated when the
-- trigger was created, so windows starting well before that still degrade gracefully
-- (Opening ~= current balance, since no historical movement rows exist to subtract) -
-- there is no way to backfill a "before" state for movements nobody ever recorded, but
-- accuracy will now be exact for any window entirely after the trigger existed.
CREATE OR ALTER PROCEDURE StockDetailRecord_GetReport
    @Branch NVARCHAR(255) = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @Store NVARCHAR(255) = NULL,
    @Vendor NVARCHAR(255) = NULL,
    @StockType NVARCHAR(255) = NULL,
    @Item NVARCHAR(255) = NULL,
    @ItemType NVARCHAR(255) = NULL,
    @SaleType NVARCHAR(255) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StoreId INT = (SELECT StoreId FROM Inv.PharmacyStores WHERE StoreName = @Store);
    DECLARE @Offset INT = (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * (CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END);
    DECLARE @Take INT = CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END;

    ;WITH StockBalance AS (
        SELECT ItemId, SUM(TotalItemsInStock) AS TotalItems
        FROM Pharmacy.PharmacyMedicinesStocks
        WHERE (@StoreId IS NULL OR StoreId = @StoreId) AND ItemId IS NOT NULL
        GROUP BY ItemId
    ),
    -- Single pass over the ledger instead of three separate GROUP BY scans (Received/
    -- Issued/NetSinceStart previously each independently re-scanned the same
    -- @StartDate-filtered rows) - conditional SUMs split out the in-window (Received/
    -- Issued display values) vs. since-@StartDate-to-now totals (NetSinceStart, needed
    -- because Opening is anchored off the current balance) in one aggregation. Verified
    -- byte-identical output against the old 3-CTE version (including against the
    -- busiest store, 10M+ ledger rows) before switching - see StockStats_Procedures.sql
    -- for the same technique applied there first. InWindowRowCount preserves the old
    -- "item has an actual in-window ledger row" membership test (not just nonzero qty)
    -- for MovedItems below.
    Movement AS (
        SELECT
            st.ItemId,
            SUM(CASE WHEN @EndDate IS NULL OR st.CreatedOn < DATEADD(DAY, 1, @EndDate) THEN st.ReceivedQty ELSE 0 END) AS ReceivedQty,
            SUM(CASE WHEN @EndDate IS NULL OR st.CreatedOn < DATEADD(DAY, 1, @EndDate) THEN st.IssuedQty ELSE 0 END) AS IssuedQty,
            SUM(st.ReceivedQty) - SUM(st.IssuedQty) AS NetQty,
            SUM(CASE WHEN @EndDate IS NULL OR st.CreatedOn < DATEADD(DAY, 1, @EndDate) THEN 1 ELSE 0 END) AS InWindowRowCount
        FROM Inv.StockTransactions st
        WHERE st.ItemId IS NOT NULL
          AND (@StoreId IS NULL OR st.StoreId = @StoreId)
          AND (@StartDate IS NULL OR st.CreatedOn >= @StartDate)
        GROUP BY st.ItemId
    ),
    -- Most recent GRN receipt per item, for display pricing only - ROW_NUMBER (not
    -- GROUP BY) so an item with several differently-priced batches shows one row here,
    -- not one row per batch.
    LatestGrn AS (
        SELECT
            gi.ItemId, gi.UnitBuyingPrice, gi.UnitSellingPrice, v.Name AS VendorName,
            ROW_NUMBER() OVER (PARTITION BY gi.ItemId ORDER BY grn.DateAndTime DESC, gi.Id DESC) AS rn
        FROM Inv.GRNItems gi
        INNER JOIN Inv.GoodsReceivingNotes grn ON grn.Id = gi.GRNId
        LEFT JOIN Inv.Vendors v ON grn.VendorId = v.Id
        WHERE grn.IsActive = 1
    ),
    LatestInventoryDetail AS (
        SELECT
            d.ItemId, d.UnitBuyingPrice, d.UnitSellingPrice,
            ROW_NUMBER() OVER (PARTITION BY d.ItemId ORDER BY inv.CreatedOn DESC, d.Id DESC) AS rn
        FROM Inv.InventoryDetails d
        INNER JOIN Inv.Inventories inv ON inv.Id = d.InventoryId
        WHERE inv.IsActive = 1
    ),
    MovedItems AS (
        SELECT ItemId FROM Movement WHERE InWindowRowCount > 0
        UNION
        -- Items with no ledger movement in the window but that DO have a current balance
        -- still belong in the report (Opening = Balance in that case) - previously only
        -- items with a tracked Received/Issued row showed up at all.
        SELECT ItemId FROM StockBalance WHERE TotalItems <> 0
    )
    SELECT
        -- ROW_NUMBER() is BIGINT by default - cast down since StockDetailRecord.Sr is int
        -- and the C# reader uses GetInt32.
        CAST(ROW_NUMBER() OVER (ORDER BY i.Name) AS INT) AS Sr,
        i.Name,
        COALESCE(st.Name, 'Regular') AS StockType,
        -- GRNItems' price columns are DECIMAL but InventoryDetails' are REAL - cast the
        -- fallback branch so the expression's static type stays DECIMAL(18,2)
        -- throughout (SQL Server would otherwise promote the whole ISNULL to FLOAT
        -- because float outranks decimal in its type precedence, which the C# side's
        -- reader.GetDecimal(...) can't read back without throwing).
        ISNULL(lg.UnitBuyingPrice, CAST(ISNULL(lid.UnitBuyingPrice, 0) AS DECIMAL(18,2))) AS BuyingPrice,
        ISNULL(lg.UnitSellingPrice, CAST(ISNULL(lid.UnitSellingPrice, 0) AS DECIMAL(18,2))) AS SellingPrice,
        CAST(ISNULL(sb.TotalItems, 0) - ISNULL(mv.NetQty, 0) AS INT) AS Opening,
        CAST(ISNULL(mv.ReceivedQty, 0) AS INT) AS Received,
        CAST(ISNULL(mv.IssuedQty, 0) AS INT) AS Issued,
        CAST(ISNULL(sb.TotalItems, 0) AS INT) AS Balance,
        COUNT(*) OVER() AS TotalCount
    FROM Inv.Items i
    INNER JOIN MovedItems m ON m.ItemId = i.Id
    LEFT JOIN StockBalance sb ON sb.ItemId = i.Id
    LEFT JOIN Movement mv ON mv.ItemId = i.Id
    LEFT JOIN LatestGrn lg ON lg.ItemId = i.Id AND lg.rn = 1
    LEFT JOIN LatestInventoryDetail lid ON lid.ItemId = i.Id AND lid.rn = 1
    OUTER APPLY (
        SELECT TOP 1 latest.StockTypeId
        FROM Inv.InventoryDetails d
        INNER JOIN Inv.Inventories latest ON d.InventoryId = latest.Id
        WHERE d.ItemId = i.Id AND latest.IsActive = 1
        ORDER BY COALESCE(latest.ModifiedOn, latest.CreatedOn) DESC, latest.Id DESC
    ) latestInventory
    LEFT JOIN Inv.StockTypes st ON latestInventory.StockTypeId = st.Id
    LEFT JOIN Inv.ItemTypes it ON i.ItemTypeId = it.Id
    WHERE i.IsActive = 1
      AND (@Vendor IS NULL OR lg.VendorName = @Vendor)
      AND (@StockType IS NULL OR st.Name = @StockType)
      AND (@Item IS NULL OR i.Name LIKE '%' + @Item + '%')
      AND (@ItemType IS NULL OR it.Name = @ItemType)
    ORDER BY i.Name
    OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY;
END
GO
