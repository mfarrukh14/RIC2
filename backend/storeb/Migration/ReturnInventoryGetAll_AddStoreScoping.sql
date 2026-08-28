-- Adds store-scoped access control to ReturnInventory_GetAll - same pattern
-- as StockSearch_AddStoreScoping.sql, see that file's header for the full
-- rationale.
CREATE OR ALTER PROCEDURE dbo.ReturnInventory_GetAll
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @ItemTypeId INT = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @PurchaseOrderNo NVARCHAR(50) = NULL,
    @ItemId INT = NULL,
    @InventoryNo NVARCHAR(50) = NULL,
    @IsAdmin BIT = 0,
    @AllowedStoreIds NVARCHAR(MAX) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * (CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END);
    DECLARE @Take INT = CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END;
    DECLARE @AllowedStoreIdTable TABLE (StoreId INT);

    IF @IsAdmin = 0 AND @AllowedStoreIds IS NOT NULL AND LTRIM(RTRIM(@AllowedStoreIds)) <> ''
    BEGIN
        INSERT INTO @AllowedStoreIdTable (StoreId)
        SELECT TRY_CAST(value AS INT)
        FROM STRING_SPLIT(@AllowedStoreIds, ',')
        WHERE TRY_CAST(value AS INT) IS NOT NULL;
    END

    SELECT
        ri.Id,
        ri.ReturnNumber AS InventoryNo,
        ri.PurchaseOrderNo,
        ri.BranchId,
        b.Name AS BranchName,
        ri.StoreId,
        s.StoreName AS StoreName,
        ri.ItemTypeId,
        it.Name AS ItemTypeName,
        primaryItem.ItemId,
        primaryItem.ItemName,
        ISNULL(itemTotals.ReturnQuantity, 0) AS ReturnQuantity,
        NULL AS StockTypeId,
        NULL AS StockTypeName,
        ri.VendorId,
        v.Name AS VendorName,
        ri.ReturnDate,
        ri.Reason,
        ri.Notes,
        ri.IsActive,
        ri.CreatedById,
        ri.CreatedOn,
        ri.ModifiedById,
        ri.ModifiedOn,
        COUNT(*) OVER() AS TotalCount
    FROM Inv.ReturnInventory ri
    LEFT JOIN Inv.Branches b ON ri.BranchId = b.Id
    LEFT JOIN Inv.PharmacyStores s ON ri.StoreId = s.StoreId
    LEFT JOIN Inv.ItemTypes it ON ri.ItemTypeId = it.Id
    LEFT JOIN Inv.Vendors v ON ri.VendorId = v.Id
    OUTER APPLY (
        SELECT TOP (1)
            rii.ItemId,
            i.Name AS ItemName
        FROM Inv.ReturnInventoryItems rii
        LEFT JOIN Inv.Items i ON rii.ItemId = i.Id
        WHERE rii.ReturnInventoryId = ri.Id
            AND rii.IsActive = 1
        ORDER BY rii.Id DESC
    ) primaryItem
    OUTER APPLY (
        SELECT SUM(rii.Quantity) AS ReturnQuantity
        FROM Inv.ReturnInventoryItems rii
        WHERE rii.ReturnInventoryId = ri.Id
            AND rii.IsActive = 1
    ) itemTotals
    WHERE ri.IsActive = 1
        AND (@BranchId IS NULL OR ri.BranchId = @BranchId)
        AND (@StoreId IS NULL OR ri.StoreId = @StoreId)
        AND (@IsAdmin = 1 OR ri.StoreId IN (SELECT StoreId FROM @AllowedStoreIdTable))
        AND (@ItemTypeId IS NULL OR ri.ItemTypeId = @ItemTypeId)
        AND (@StartDate IS NULL OR ri.ReturnDate >= @StartDate)
        AND (@EndDate IS NULL OR ri.ReturnDate <= @EndDate)
        AND (@PurchaseOrderNo IS NULL OR ri.PurchaseOrderNo = @PurchaseOrderNo)
        AND (@InventoryNo IS NULL OR ri.ReturnNumber LIKE '%' + @InventoryNo + '%')
        AND (@ItemId IS NULL OR EXISTS (
            SELECT 1 FROM Inv.ReturnInventoryItems rii2
            WHERE rii2.ReturnInventoryId = ri.Id AND rii2.ItemId = @ItemId AND rii2.IsActive = 1
        ))
    ORDER BY ri.CreatedOn DESC
    OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY;
END
