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

    -- Get stock statistics: Received is real, pulled from inventory receipts in the date
    -- range, scoped to store/branch when given. Stock type comes from the item's most
    -- recent active receipt at that store, same technique used by Stock_Search/
    -- StockAudit_Search - Inv.Items has no StockTypeId of its own to join against.
    -- Opening/Issued need a historical ledger and a dispensing/sales feed respectively,
    -- neither of which exist yet, so they stay 0 rather than fabricating numbers.
    ;WITH StockMovements AS (
        SELECT
            i.Id AS ItemId,
            i.Name AS ItemName,
            COALESCE(st.Name, 'Regular') AS StockType,
            CAST(0 AS FLOAT) AS Opening,
            CAST(ISNULL(SUM(CASE
                WHEN inv.CreatedOn >= @StartDate AND inv.CreatedOn <= @EndDate
                THEN invd.TotalItems
                ELSE 0
            END), 0) AS FLOAT) AS Received,
            CAST(0 AS FLOAT) AS Issued
        FROM Inv.Items i
        LEFT JOIN Inv.InventoryDetails invd ON i.Id = invd.ItemId
        LEFT JOIN Inv.Inventories inv ON invd.InventoryId = inv.Id
            AND inv.IsActive = 1
            AND (@StoreId IS NULL OR inv.StoreId = @StoreId)
            AND (@BranchId IS NULL OR inv.BranchId = @BranchId)
        OUTER APPLY
        (
            SELECT TOP 1 latest.StockTypeId
            FROM Inv.InventoryDetails d
            INNER JOIN Inv.Inventories latest ON d.InventoryId = latest.Id
            WHERE d.ItemId = i.Id
              AND latest.IsActive = 1
              AND (@StoreId IS NULL OR latest.StoreId = @StoreId)
            ORDER BY COALESCE(latest.ModifiedOn, latest.CreatedOn) DESC, latest.Id DESC
        ) latestInventory
        LEFT JOIN Inv.StockTypes st ON latestInventory.StockTypeId = st.Id
        WHERE
            (@ItemTypeId IS NULL OR i.ItemTypeId = @ItemTypeId)
            AND (@StockTypeId IS NULL OR latestInventory.StockTypeId = @StockTypeId)
            AND (NOT EXISTS(SELECT 1 FROM #ItemIds) OR i.Id IN (SELECT ItemId FROM #ItemIds))
            AND i.IsActive = 1
        GROUP BY i.Id, i.Name, st.Name, latestInventory.StockTypeId
    )
    SELECT
        ItemId,
        ItemName,
        StockType,
        Opening,
        Received,
        Issued,
        CAST((Opening + Received - Issued) AS FLOAT) AS Balance
    FROM StockMovements
    ORDER BY ItemName;

    DROP TABLE #ItemIds;
END
GO

PRINT 'Stock Stats stored procedures created successfully';
