-- =============================================
-- Stock Expiring Stored Procedures
-- =============================================

-- =============================================
-- Get Expiring Stock with Filters
-- =============================================
CREATE OR ALTER PROCEDURE StockExpiring_GetExpiringStock
    @StoreId INT = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @ItemIds NVARCHAR(MAX) = NULL -- Comma-separated list of item IDs
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Create temp table for item IDs if provided
    DECLARE @ItemIdTable TABLE (ItemId INT);
    
    IF @ItemIds IS NOT NULL AND @ItemIds != ''
    BEGIN
        INSERT INTO @ItemIdTable (ItemId)
        SELECT CAST(value AS INT)
        FROM STRING_SPLIT(@ItemIds, ',')
        WHERE value != '';
    END
    
    SELECT 
        id.Id,
        i.Name AS ItemName,
        st.Name AS StockType,
        CAST(id.Id AS NVARCHAR(50)) AS BatchNo, -- Using ID as batch number since no BatchNo column
        id.MfgDate,
        id.ExpiryDate,
        id.TotalItems,
        inv.StoreId,
        s.StoreName
    FROM Inv.InventoryDetails id
    INNER JOIN Inv.Inventories inv ON id.InventoryId = inv.Id
    INNER JOIN Inv.Items i ON id.ItemId = i.Id
    LEFT JOIN Inv.Stores s ON inv.StoreId = s.StoreId
    LEFT JOIN Inv.StockTypes st ON inv.StockTypeId = st.Id
    WHERE id.TotalItems > 0
        AND id.ExpiryDate IS NOT NULL
        AND id.ExpiryDate >= GETDATE() -- Only non-expired items
        AND (@StoreId IS NULL OR inv.StoreId = @StoreId)
        AND (@StartDate IS NULL OR id.ExpiryDate >= @StartDate)
        AND (@EndDate IS NULL OR id.ExpiryDate <= @EndDate)
        AND (@ItemIds IS NULL OR @ItemIds = '' OR id.ItemId IN (SELECT ItemId FROM @ItemIdTable))
    ORDER BY id.ExpiryDate ASC;
END
GO
