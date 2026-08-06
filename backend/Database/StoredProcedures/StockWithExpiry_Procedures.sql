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

    SELECT 
        id.Id,
        i.Id AS ItemId,
        i.Name AS ItemName,
        inv.StoreId,
        st.StoreName,
        COALESCE(ii.Batch, ii.SysBatchNo, CAST(id.Id AS NVARCHAR(50))) AS BatchNumber,
        id.ExpiryDate,
        id.TotalItems AS Quantity,
        ISNULL(sty.Name, 'Regular') AS StockType,
        
        -- Rack Location Information (from SpaceAllocations)
        sa.RackId,
        r.Name AS RackName,
        sa.RackRowId,
        rr.Name AS RowNumber,
        sa.RackColumnId,
        rc.Name AS ColumnNumber,
        sa.RackDrawrId AS RackDrawerId,
        rd.Name AS DrawerNumber,
        
        -- MPL and Stock Status
        ISNULL(i.MinimumPanicLevel, 0) AS MPL,
        CASE 
            WHEN id.TotalItems <= ISNULL(i.MinimumPanicLevel, 0) THEN 1
            ELSE 0
        END AS IsBelowMPL,
        
        -- Item Details
        it.Name AS ItemType,
        i.IsExpensiveItem,
        i.IsFridgeItem,
        i.CategoryId,
        
        -- Total Items in Transition (all items for this ItemId in this store)
        (SELECT ISNULL(SUM(id2.TotalItems), 0) 
         FROM Inv.InventoryDetails id2
         INNER JOIN Inv.Inventories inv2 ON id2.InventoryId = inv2.Id
         WHERE id2.ItemId = i.Id AND inv2.StoreId = inv.StoreId) AS TotalItemsInTransition,
        
        inv.ModifiedOn,
        inv.ModifiedById,
        inv.CreatedOn,
        inv.CreatedById
        
    FROM Inv.InventoryDetails id
    INNER JOIN Inv.Inventories inv ON id.InventoryId = inv.Id
    INNER JOIN Inv.Items i ON id.ItemId = i.Id
    INNER JOIN Inv.PharmacyStores st ON inv.StoreId = st.StoreId
    LEFT JOIN Inv.ItemTypes it ON i.ItemTypeId = it.Id
    LEFT JOIN Inv.StockTypes sty ON inv.StockTypeId = sty.Id
        OUTER APPLY (
                SELECT TOP 1 ii.Batch, ii.SysBatchNo
                FROM Inv.InventoryItems ii
                WHERE ii.InventoryId = id.InventoryId
                    AND ii.ItemId = id.ItemId
                    AND ii.IsActive = 1
                    AND (ii.IsDeleted = 0 OR ii.IsDeleted IS NULL)
                ORDER BY ii.Id DESC
        ) ii
    LEFT JOIN Inv.SpaceAllocations sa ON sa.ItemId = i.Id
    LEFT JOIN Inv.Racks r ON sa.RackId = r.Id
    LEFT JOIN Inv.RackRows rr ON sa.RackRowId = rr.Id
    LEFT JOIN Inv.RackColumns rc ON sa.RackColumnId = rc.Id
    LEFT JOIN Inv.RackDrawrs rd ON sa.RackDrawrId = rd.Id
    
    WHERE 
        (@BranchId IS NULL OR inv.BranchId = @BranchId)
        AND (@StoreId IS NULL OR inv.StoreId = @StoreId)
        AND (@ItemType IS NULL OR it.Name = @ItemType)
        AND (@ItemId IS NULL OR i.Id = @ItemId)
        AND (@CategoryId IS NULL OR i.CategoryId = @CategoryId)
        AND (@IsExpensiveItem IS NULL OR i.IsExpensiveItem = @IsExpensiveItem)
        AND (@IsFridgeItem IS NULL OR i.IsFridgeItem = @IsFridgeItem)
        AND (@MinimumPanicLevelOnly = 0 OR id.TotalItems <= ISNULL(i.MinimumPanicLevel, 0))
        AND id.TotalItems > 0
        AND inv.IsActive = 1
        
    ORDER BY 
        CASE WHEN id.TotalItems <= ISNULL(i.MinimumPanicLevel, 0) THEN 0 ELSE 1 END,
        id.ExpiryDate ASC,
        i.Name;
END
GO

PRINT 'StockWithExpiry stored procedure created successfully';
GO
