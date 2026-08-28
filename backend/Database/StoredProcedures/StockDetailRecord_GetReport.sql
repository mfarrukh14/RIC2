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
    @SaleType NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StoreId INT = (SELECT StoreId FROM Inv.PharmacyStores WHERE StoreName = @Store);

    ;WITH StockBalance AS (
        SELECT ItemId, SUM(TotalItemsInStock) AS TotalItems
        FROM Pharmacy.PharmacyMedicinesStocks
        WHERE (@StoreId IS NULL OR StoreId = @StoreId) AND ItemId IS NOT NULL
        GROUP BY ItemId
    ),
    Received AS (
        SELECT ItemId, SUM(ReceivedQty) AS Qty
        FROM Inv.StockTransactions st
        WHERE ItemId IS NOT NULL
          AND (@StoreId IS NULL OR st.StoreId = @StoreId)
          AND (@StartDate IS NULL OR st.CreatedOn >= @StartDate) AND (@EndDate IS NULL OR st.CreatedOn < DATEADD(DAY, 1, @EndDate))
        GROUP BY ItemId
    ),
    Issued AS (
        SELECT ItemId, SUM(IssuedQty) AS Qty
        FROM Inv.StockTransactions st
        WHERE ItemId IS NOT NULL
          AND (@StoreId IS NULL OR st.StoreId = @StoreId)
          AND (@StartDate IS NULL OR st.CreatedOn >= @StartDate) AND (@EndDate IS NULL OR st.CreatedOn < DATEADD(DAY, 1, @EndDate))
        GROUP BY ItemId
    ),
    -- Net movement from @StartDate to NOW (unbounded on the end date) - used only to back
    -- Opening out from the current balance, since Balance is always "as of now", not "as
    -- of @EndDate".
    NetSinceStart AS (
        SELECT ItemId, SUM(ReceivedQty) - SUM(IssuedQty) AS NetQty
        FROM Inv.StockTransactions st
        WHERE ItemId IS NOT NULL
          AND (@StoreId IS NULL OR st.StoreId = @StoreId)
          AND (@StartDate IS NULL OR st.CreatedOn >= @StartDate)
        GROUP BY ItemId
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
        SELECT ItemId FROM Received
        UNION
        SELECT ItemId FROM Issued
        UNION
        -- Items with no ledger movement in the window but that DO have a current balance
        -- still belong in the report (Opening = Balance in that case) - previously only
        -- items with a tracked Received/Issued row showed up at all.
        SELECT ItemId FROM StockBalance WHERE TotalItems <> 0
    )
    SELECT
        ROW_NUMBER() OVER (ORDER BY i.Name) AS Sr,
        i.Name,
        COALESCE(st.Name, 'Regular') AS StockType,
        -- GRNItems' price columns are DECIMAL but InventoryDetails' are REAL - cast the
        -- fallback branch so the expression's static type stays DECIMAL(18,2)
        -- throughout (SQL Server would otherwise promote the whole ISNULL to FLOAT
        -- because float outranks decimal in its type precedence, which the C# side's
        -- reader.GetDecimal(...) can't read back without throwing).
        ISNULL(lg.UnitBuyingPrice, CAST(ISNULL(lid.UnitBuyingPrice, 0) AS DECIMAL(18,2))) AS BuyingPrice,
        ISNULL(lg.UnitSellingPrice, CAST(ISNULL(lid.UnitSellingPrice, 0) AS DECIMAL(18,2))) AS SellingPrice,
        CAST(ISNULL(sb.TotalItems, 0) - ISNULL(ns.NetQty, 0) AS INT) AS Opening,
        CAST(ISNULL(r.Qty, 0) AS INT) AS Received,
        CAST(ISNULL(iss.Qty, 0) AS INT) AS Issued,
        CAST(ISNULL(sb.TotalItems, 0) AS INT) AS Balance
    FROM Inv.Items i
    INNER JOIN MovedItems m ON m.ItemId = i.Id
    LEFT JOIN StockBalance sb ON sb.ItemId = i.Id
    LEFT JOIN Received r ON r.ItemId = i.Id
    LEFT JOIN Issued iss ON iss.ItemId = i.Id
    LEFT JOIN NetSinceStart ns ON ns.ItemId = i.Id
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
    ORDER BY i.Name;
END
GO
