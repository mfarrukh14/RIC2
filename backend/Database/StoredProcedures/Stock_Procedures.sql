-- =============================================
-- Stock Search Stored Procedure
--
-- Reads from the Inv.* schema (Inv.Stocks/Inv.Items/Inv.ItemTypes/Inv.Categories),
-- not the legacy dbo.Stocks/dbo.Items tables, which no longer exist. This must stay
-- in sync with InventoryManagement.Api.Services.StockService.CreateFallbackSearchCommand -
-- that C# query is used whenever this procedure is absent, and StockService.MapStockFromReader
-- expects the exact same result-set shape (including StockType/Location) from either path.
-- =============================================
CREATE OR ALTER PROCEDURE Stock_Search
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @ItemTypeId INT = NULL,
    @ItemId INT = NULL,
    @CategoryIds NVARCHAR(MAX) = NULL, -- Comma-separated
    @StockTypeId INT = NULL,
    @GeneralType NVARCHAR(50) = NULL,
    @MedicineTypeId INT = NULL,
    @StockAvailability NVARCHAR(20) = NULL, -- 'All', 'InStock', 'OutOfStock'
    @IsVaccine BIT = NULL,
    @MinimumPanicLevelOnly BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CategoryIdTable TABLE (CategoryId INT);

    IF @CategoryIds IS NOT NULL AND LTRIM(RTRIM(@CategoryIds)) <> ''
    BEGIN
        INSERT INTO @CategoryIdTable (CategoryId)
        SELECT TRY_CAST(value AS INT)
        FROM STRING_SPLIT(@CategoryIds, ',')
        WHERE TRY_CAST(value AS INT) IS NOT NULL;
    END

    SELECT
        s.Id,
        i.Id AS ItemId,
        i.Name AS ItemName,
        COALESCE(st.Name, 'Regular') AS StockType,
        s.TotalItems,
        COALESCE(s.MinimumPanicLevel, i.MinimumPanicLevel, 0) AS MinimumPanicLevel,
        s.StoreId,
        s.BranchId,
        s.IsActive,
        s.ModifiedOn,
        i.ItemTypeId,
        it.Name AS ItemTypeName,
        c.Name AS CategoryName,
        i.IsFridgeItem,
        i.IsConsumptionItem,
        loc.Location
    FROM Inv.Stocks s
    INNER JOIN Inv.Items i ON s.ItemId = i.Id
    LEFT JOIN Inv.ItemTypes it ON i.ItemTypeId = it.Id
    LEFT JOIN Inv.Categories c ON i.CategoryId = c.Id
    OUTER APPLY
    (
        SELECT TOP 1 inv.StockTypeId
        FROM Inv.InventoryDetails details
        INNER JOIN Inv.Inventories inv ON details.InventoryId = inv.Id
        WHERE details.ItemId = s.ItemId
          AND inv.StoreId = s.StoreId
          AND inv.IsActive = 1
        ORDER BY COALESCE(inv.ModifiedOn, inv.CreatedOn) DESC, inv.Id DESC
    ) latestInventory
    LEFT JOIN Inv.StockTypes st ON latestInventory.StockTypeId = st.Id
    -- Rack.Row.Column[.Drawer] shelf location, same concept as the old system's
    -- SpaceAllocations-based Location column on this same report.
    OUTER APPLY
    (
        SELECT TOP 1
            r.Name + ISNULL('.' + rr.Name, '') + ISNULL('.' + rc.Name, '') + ISNULL('.' + rd.Name, '') AS Location
        FROM Inv.SpaceAllocations sa
        INNER JOIN Inv.Racks r ON r.Id = sa.RackId
        LEFT JOIN Inv.RackRows rr ON rr.Id = sa.RackRowId
        LEFT JOIN Inv.RackColumns rc ON rc.Id = sa.RackColumnId
        LEFT JOIN Inv.RackDrawrs rd ON rd.Id = sa.RackDrawrId
        WHERE sa.ItemId = s.ItemId
          AND sa.StoreId = s.StoreId
          AND ISNULL(sa.IsDeleted, 0) = 0
          AND sa.IsActive = 1
        ORDER BY sa.Id DESC
    ) loc
    WHERE s.IsActive = 1
        AND (@BranchId IS NULL OR s.BranchId = @BranchId)
        AND (@StoreId IS NULL OR s.StoreId = @StoreId)
        AND (@ItemTypeId IS NULL OR i.ItemTypeId = @ItemTypeId)
        AND (@ItemId IS NULL OR i.Id = @ItemId)
        AND (@StockTypeId IS NULL OR latestInventory.StockTypeId = @StockTypeId)
        AND (
            @CategoryIds IS NULL
            OR LTRIM(RTRIM(@CategoryIds)) = ''
            OR i.CategoryId IN (SELECT CategoryId FROM @CategoryIdTable)
        )
        AND (
            @StockAvailability IS NULL
            OR @StockAvailability = 'All'
            OR (@StockAvailability = 'InStock' AND s.TotalItems > 0)
            OR (@StockAvailability = 'OutOfStock' AND COALESCE(s.TotalItems, 0) <= 0)
        )
        AND (
            @MinimumPanicLevelOnly = 0
            OR COALESCE(s.TotalItems, 0) <= COALESCE(s.MinimumPanicLevel, i.MinimumPanicLevel, 0)
        )
    ORDER BY i.Name ASC;
END
GO

PRINT 'Stock search stored procedure created successfully';
