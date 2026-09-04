-- =============================================
-- Stock Search Stored Procedure
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
    
    -- Create temp table for category IDs if provided
    DECLARE @CategoryIdTable TABLE (CategoryId INT);
    
    IF @CategoryIds IS NOT NULL AND @CategoryIds != ''
    BEGIN
        INSERT INTO @CategoryIdTable (CategoryId)
        SELECT CAST(value AS INT)
        FROM STRING_SPLIT(@CategoryIds, ',')
        WHERE value != '';
    END
    
    SELECT 
        s.Id,
        i.Id AS ItemId,
        i.Name AS ItemName,
        'Regular' AS StockType,
        s.TotalItems,
        s.MinimumPanicLevel,
        s.StoreId,
        s.BranchId,
        s.IsActive,
        s.ModifiedOn,
        -- Additional item info
        i.ItemTypeId,
        it.Name AS ItemTypeName,
        ic.Name AS CategoryName,
        i.IsFridgeItem,
        i.IsConsumptionItem
    FROM Inv.Stocks s
    INNER JOIN Inv.Items i ON s.ItemId = i.Id
    LEFT JOIN Inv.ItemTypes it ON i.ItemTypeId = it.Id
    LEFT JOIN Inv.Categories ic ON i.CategoryId = ic.Id
    WHERE s.IsActive = 1
        AND (@BranchId IS NULL OR s.BranchId = @BranchId)
        AND (@StoreId IS NULL OR s.StoreId = @StoreId)
        AND (@ItemTypeId IS NULL OR i.ItemTypeId = @ItemTypeId)
        AND (@ItemId IS NULL OR i.Id = @ItemId)
        AND (@CategoryIds IS NULL OR @CategoryIds = '' OR i.CategoryId IN (SELECT CategoryId FROM @CategoryIdTable))
        AND (
            @StockAvailability IS NULL 
            OR @StockAvailability = 'All' 
            OR (@StockAvailability = 'InStock' AND s.TotalItems > 0)
            OR (@StockAvailability = 'OutOfStock' AND (s.TotalItems IS NULL OR s.TotalItems <= 0))
        )
        AND (
            @MinimumPanicLevelOnly = 0 
            OR (s.TotalItems IS NOT NULL AND s.MinimumPanicLevel IS NOT NULL AND s.TotalItems <= s.MinimumPanicLevel)
        )
    ORDER BY i.Name ASC;
END
GO

PRINT 'Stock search stored procedure created successfully';
