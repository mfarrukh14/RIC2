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
    @ItemType NVARCHAR(50) = 'All', -- All, Medicine, Disposable, Item
    @ItemIds NVARCHAR(MAX) = NULL, -- Comma-separated INTs
    @StockTypeId INT = NULL,
    @Type NVARCHAR(50) = 'All',
    @SaleType NVARCHAR(50) = 'OverAll' -- OverAll, OPD, Emergency, IPD, OutDoorPharmacy
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
    
    -- Get stock statistics
    -- This calculates Opening, Received, Issued, and Balance for each item
    ;WITH StockMovements AS (
        SELECT 
            i.Id AS ItemId,
            i.Name AS ItemName,
            st.Name AS StockType,
            -- Opening: Stock at start date (would need historical data)
            CAST(0 AS FLOAT) AS Opening,
            -- Received: Sum of inventory received in date range
            ISNULL(SUM(CASE 
                WHEN inv.CreatedOn >= @StartDate AND inv.CreatedOn <= @EndDate 
                THEN invd.TotalItems 
                ELSE 0 
            END), 0) AS Received,
            -- Issued: Would come from dispensing/sales records (not implemented yet)
            CAST(0 AS FLOAT) AS Issued,
            -- Balance: Opening + Received - Issued
            CAST(0 AS FLOAT) AS Balance
        FROM dbo.Items i
        LEFT JOIN dbo.StockTypes st ON i.ItemTypeId = st.Id
        LEFT JOIN dbo.InventoryDetails invd ON i.Id = invd.ItemId
        LEFT JOIN dbo.Inventories inv ON invd.InventoryId = inv.Id
        WHERE 
            (@StoreId IS NULL OR inv.StoreId = @StoreId)
            AND (@StockTypeId IS NULL OR i.ItemTypeId = @StockTypeId)
            AND (NOT EXISTS(SELECT 1 FROM #ItemIds) OR i.Id IN (SELECT ItemId FROM #ItemIds))
            AND i.IsActive = 1
        GROUP BY i.Id, i.Name, st.Name
    )
    SELECT 
        ItemId,
        ItemName,
        StockType,
        Opening,
        Received,
        Issued,
        (Opening + Received - Issued) AS Balance
    FROM StockMovements
    ORDER BY ItemName;
    
    DROP TABLE #ItemIds;
END
GO

PRINT 'Stock Stats stored procedures created successfully';
