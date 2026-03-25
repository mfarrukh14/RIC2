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
        CAST(id.Id AS NVARCHAR(50)) AS BatchNumber, -- Using ID as batch number since no batch field exists
        id.ExpiryDate,
        id.TotalItems AS Quantity,
        ISNULL(sty.StockTypeName, 'Regular') AS StockType,
        
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
            WHEN id.TotalItems <= ISNULL(i.MinimumPanicLevel, 0) THEN 1
            ELSE 0
        END AS IsBelowMPL,
        
        -- Item Details
        it.Name AS ItemType,
        CAST(0 AS BIT) AS IsExpensiveItem, -- Not in schema, defaulting to false
        i.IsFridgeItem,
        i.CategoryId,
        
        -- Total Items in Transition (all items for this ItemId in this store)
        (SELECT ISNULL(SUM(id2.TotalItems), 0) 
         FROM InventoryDetails id2
         INNER JOIN Inventories inv2 ON id2.InventoryId = inv2.Id
         WHERE id2.ItemId = i.Id AND inv2.StoreId = inv.StoreId) AS TotalItemsInTransition,
        
        inv.ModifiedOn,
        inv.ModifiedById,
        inv.CreatedOn,
        inv.CreatedById
        
    FROM dbo.InventoryDetails id
    INNER JOIN dbo.Inventories inv ON id.InventoryId = inv.Id
    INNER JOIN dbo.Items i ON id.ItemId = i.Id
    INNER JOIN dbo.Stores st ON inv.StoreId = st.StoreId
    LEFT JOIN dbo.ItemTypes it ON i.ItemTypeId = it.Id
    LEFT JOIN dbo.StockTypes sty ON inv.StockTypeId = sty.StockTypeId
    LEFT JOIN dbo.SpaceAllocations sa ON CAST(SUBSTRING(CAST(sa.ItemId AS VARCHAR(36)), 1, 8) AS INT) = i.Id
    LEFT JOIN dbo.Racks r ON sa.RackId = r.Id
    LEFT JOIN dbo.RackRows rr ON sa.RackRowId = rr.Id
    LEFT JOIN dbo.RackColumns rc ON sa.RackColumnId = rc.Id
    LEFT JOIN dbo.RackDrawers rd ON sa.RackDrawerId = rd.Id
    
    WHERE 
        (@BranchId IS NULL OR inv.BranchId = @BranchId)
        AND (@StoreId IS NULL OR inv.StoreId = @StoreId)
        AND (@ItemType IS NULL OR it.Name = @ItemType)
        AND (@ItemId IS NULL OR i.Id = @ItemId)
        AND (@CategoryId IS NULL OR i.CategoryId = @CategoryId)
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
