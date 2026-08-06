-- Stored procedure to get pharmacy stock detail records
--
-- Rewritten to match the old system's real stock-ledger approach (same fix already
-- applied to StockStats_Search): Opening/Received/Issued/Balance now come from the
-- actual, dated movement sources (GRN, Add Inventory, Transfer, Stock Adjustment,
-- Stock Consumption) instead of a derived "Issued = Opening + Received - Balance"
-- formula. That formula produced wrong (often negative) numbers whenever a store's
-- balance changed for any reason other than a GRN receipt - which is the normal case,
-- since issuance in this app happens via consumption/transfer/adjustment, not by
-- editing a GRN line. The previous version also GROUPed GrnHistory by
-- UnitBuyingPrice/UnitSellingPrice/VendorName, which silently fanned an item with
-- multiple distinct GRN batches out into several duplicate rows, each showing the
-- item's FULL current balance - compounding the wrong-Issued bug further.
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
        SELECT ItemId, SUM(TotalItems) AS TotalItems
        FROM Inv.Stocks
        WHERE IsActive = 1 AND (@StoreId IS NULL OR StoreId = @StoreId)
        GROUP BY ItemId
    ),
    Received AS (
        SELECT ItemId, SUM(Qty) AS Qty
        FROM (
            SELECT ti.ItemId, ti.Quantity AS Qty
            FROM Inv.TransferInventoryItems ti
            INNER JOIN Inv.TransferInventory t ON ti.TransferInventoryId = t.Id
            WHERE ti.IsActive = 1 AND t.IsActive = 1
              AND (@StoreId IS NULL OR t.ToStoreId = @StoreId)
              AND (@StartDate IS NULL OR t.TransferDate >= @StartDate) AND (@EndDate IS NULL OR t.TransferDate <= @EndDate)

            UNION ALL

            -- Type 2 ("Issue / Increase" in the Stock Adjustment UI) credits stock in.
            SELECT sad.ItemId, sad.Quantity AS Qty
            FROM Inv.StockAdjustmentDetails sad
            INNER JOIN Inv.StockAdjustments sa ON sa.Id = sad.StockAdjustmentId
            WHERE sad.IsDeleted = 0 AND sa.IsDeleted = 0 AND sad.Type = 2
              AND (@StoreId IS NULL OR sa.StoreId = @StoreId)
              AND (@StartDate IS NULL OR sad.CreatedOn >= @StartDate) AND (@EndDate IS NULL OR sad.CreatedOn <= @EndDate)

            UNION ALL

            SELECT gi.ItemId, gi.ReceivedQuantity AS Qty
            FROM Inv.GRNItems gi
            INNER JOIN Inv.GoodsReceivingNotes grn ON grn.Id = gi.GRNId
            INNER JOIN Inv.PurchaseOrders po ON po.PurchaseOrderId = grn.PurchaseOrderId
            WHERE grn.IsActive = 1
              AND (@StoreId IS NULL OR po.StoreId = @StoreId)
              AND (@StartDate IS NULL OR grn.DateAndTime >= @StartDate) AND (@EndDate IS NULL OR grn.DateAndTime <= @EndDate)

            UNION ALL

            SELECT d.ItemId, d.TotalItems AS Qty
            FROM Inv.InventoryDetails d
            INNER JOIN Inv.Inventories inv ON inv.Id = d.InventoryId
            WHERE inv.IsActive = 1
              AND (@StoreId IS NULL OR inv.StoreId = @StoreId)
              AND (@StartDate IS NULL OR inv.CreatedOn >= @StartDate) AND (@EndDate IS NULL OR inv.CreatedOn <= @EndDate)
        ) x
        GROUP BY ItemId
    ),
    Issued AS (
        SELECT ItemId, SUM(Qty) AS Qty
        FROM (
            SELECT ti.ItemId, ti.Quantity AS Qty
            FROM Inv.TransferInventoryItems ti
            INNER JOIN Inv.TransferInventory t ON ti.TransferInventoryId = t.Id
            WHERE ti.IsActive = 1 AND t.IsActive = 1
              AND (@StoreId IS NULL OR t.FromStoreId = @StoreId)
              AND (@StartDate IS NULL OR t.TransferDate >= @StartDate) AND (@EndDate IS NULL OR t.TransferDate <= @EndDate)

            UNION ALL

            SELECT scd.ItemId, scd.Quantity AS Qty
            FROM Inv.StockConsumptionDetails scd
            WHERE scd.IsActive = 1 AND ISNULL(scd.IsDeleted, 0) = 0
              AND (@StoreId IS NULL OR scd.StoreId = @StoreId)
              AND (@StartDate IS NULL OR scd.CreatedOn >= @StartDate) AND (@EndDate IS NULL OR scd.CreatedOn <= @EndDate)

            UNION ALL

            -- Type 1 ("Less / Decrease") and anything else removes stock.
            SELECT sad.ItemId, sad.Quantity AS Qty
            FROM Inv.StockAdjustmentDetails sad
            INNER JOIN Inv.StockAdjustments sa ON sa.Id = sad.StockAdjustmentId
            WHERE sad.IsDeleted = 0 AND sa.IsDeleted = 0 AND sad.Type <> 2
              AND (@StoreId IS NULL OR sa.StoreId = @StoreId)
              AND (@StartDate IS NULL OR sad.CreatedOn >= @StartDate) AND (@EndDate IS NULL OR sad.CreatedOn <= @EndDate)
        ) x
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
        CAST(ISNULL(sb.TotalItems, 0) - ISNULL(r.Qty, 0) + ISNULL(iss.Qty, 0) AS INT) AS Opening,
        CAST(ISNULL(r.Qty, 0) AS INT) AS Received,
        CAST(ISNULL(iss.Qty, 0) AS INT) AS Issued,
        CAST(ISNULL(sb.TotalItems, 0) AS INT) AS Balance
    FROM Inv.Items i
    INNER JOIN MovedItems m ON m.ItemId = i.Id
    LEFT JOIN StockBalance sb ON sb.ItemId = i.Id
    LEFT JOIN Received r ON r.ItemId = i.Id
    LEFT JOIN Issued iss ON iss.ItemId = i.Id
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
