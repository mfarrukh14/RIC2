-- =============================================
-- Create StockWithExpiry View/Stored Procedure
-- =============================================

-- =============================================
-- Procedure: StockWithExpiry_GetAll
-- Description: Get all stock items with their expiry dates and MPL (Minimum Panic Level)
-- =============================================
IF OBJECT_ID('dbo.StockWithExpiry_GetAll', 'P') IS NOT NULL
    DROP PROCEDURE dbo.StockWithExpiry_GetAll;
GO

CREATE PROCEDURE dbo.StockWithExpiry_GetAll
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @ItemType VARCHAR(50) = NULL,
    @ItemId INT = NULL,
    @CategoryId INT = NULL,
    @IsExpensiveItem BIT = NULL,
    @IsFridgeItem BIT = NULL,
    @MinimumPanicLevelOnly BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    -- Inv.InventoryDetails (the original source here) has only ever had 15 rows in it - it's
    -- effectively dead. The real, populated per-batch receiving table (6000+ rows, with
    -- ExpiryDate/Batch/SysBatchNo/BalanceTotalItems - the live remaining balance for that
    -- batch) is Inv.InventoryItems, same table InventoryItem_GetAvailable.sql already reads
    -- for "available stock" (ii.IsActive = 1 AND ii.BalanceTotalItems > 0). Mirrored here so
    -- expiry tracking actually sees real batches instead of coming back empty.
    SELECT
        ii.Id,
        i.Id AS ItemId,
        i.Name AS ItemName,
        inv.StoreId,
        st.StoreName,
        COALESCE(ii.Batch, ii.SysBatchNo, CAST(ii.Id AS NVARCHAR(50))) AS BatchNumber,
        ii.ExpiryDate,
        CAST(ii.BalanceTotalItems AS INT) AS Quantity,
        ISNULL(sty.Name, 'Regular') AS StockType,

        -- Rack Location Information (from SpaceAllocations)
        sa.RackId,
        r.Name AS RackName,
        sa.RackRowId,
        rr.Name AS RowNumber,
        sa.RackColumnId,
        rc.Name AS ColumnNumber,
        sa.RackDrawerId,
        rd.Name AS DrawerNumber,

        -- MPL and Stock Status
        ISNULL(i.MinimumPanicLevel, 0) AS MPL,
        CASE
            WHEN ii.BalanceTotalItems <= ISNULL(i.MinimumPanicLevel, 0) THEN 1
            ELSE 0
        END AS IsBelowMPL,

        -- Item Details
        it.Name AS ItemType,
        i.IsExpensiveItem,
        i.IsFridgeItem,
        i.CategoryId,

        -- Total Items in Transition (all batches for this ItemId in this store)
        (SELECT CAST(ISNULL(SUM(ii2.BalanceTotalItems), 0) AS INT)
         FROM Inv.InventoryItems ii2
         INNER JOIN Inv.Inventories inv2 ON ii2.InventoryId = inv2.Id
         WHERE ii2.ItemId = i.Id AND inv2.StoreId = inv.StoreId
           AND ii2.IsActive = 1 AND ISNULL(ii2.IsDeleted, 0) = 0) AS TotalItemsInTransition,

        ii.ModifiedOn,
        ii.ModifiedById,
        ii.CreatedOn,
        ii.CreatedById

    FROM Inv.InventoryItems ii
    INNER JOIN Inv.Inventories inv ON ii.InventoryId = inv.Id
    INNER JOIN Inv.Items i ON ii.ItemId = i.Id
    INNER JOIN Inv.PharmacyStores st ON inv.StoreId = st.StoreId
    LEFT JOIN Inv.ItemTypes it ON i.ItemTypeId = it.Id
    LEFT JOIN Inv.StockTypes sty ON ii.StockTypeId = sty.Id
    LEFT JOIN Inv.SpaceAllocations sa ON sa.ItemId = i.Id
    LEFT JOIN Inv.Racks r ON sa.RackId = r.Id
    LEFT JOIN Inv.RackRows rr ON sa.RackRowId = rr.Id
    LEFT JOIN Inv.RackColumns rc ON sa.RackColumnId = rc.Id
    LEFT JOIN Inv.RackDrawrs rd ON sa.RackDrawerId = rd.Id

    WHERE
        (@BranchId IS NULL OR ii.BranchId = @BranchId)
        AND (@StoreId IS NULL OR inv.StoreId = @StoreId)
        AND (@ItemType IS NULL OR it.Name = @ItemType)
        AND (@ItemId IS NULL OR i.Id = @ItemId)
        AND (@CategoryId IS NULL OR i.CategoryId = @CategoryId)
        AND (@IsExpensiveItem IS NULL OR i.IsExpensiveItem = @IsExpensiveItem)
        AND (@IsFridgeItem IS NULL OR i.IsFridgeItem = @IsFridgeItem)
        AND (@MinimumPanicLevelOnly = 0 OR ii.BalanceTotalItems <= ISNULL(i.MinimumPanicLevel, 0))
        AND ii.BalanceTotalItems > 0
        AND ii.IsActive = 1
        AND ISNULL(ii.IsDeleted, 0) = 0

    ORDER BY
        CASE WHEN ii.BalanceTotalItems <= ISNULL(i.MinimumPanicLevel, 0) THEN 0 ELSE 1 END,
        ii.ExpiryDate ASC,
        i.Name;
END
GO

PRINT 'StockWithExpiry stored procedure created successfully';
GO
