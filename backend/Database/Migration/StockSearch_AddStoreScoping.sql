-- Adds store-scoped access control to Stock_Search: a non-admin caller
-- (BaseController.IsAdmin / AllowedStoreIds, from Inv.StoreAllocationToUser)
-- is now restricted to their assigned stores server-side, not just by
-- whatever storeId the frontend happens to send - the same STRING_SPLIT
-- table-variable idiom already used here for @CategoryIds.
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
    @MinimumPanicLevelOnly BIT = 0,
    @IsAdmin BIT = 0,
    @AllowedStoreIds NVARCHAR(MAX) = NULL, -- Comma-separated; ignored when @IsAdmin = 1
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * (CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END);
    DECLARE @Take INT = CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END;
    DECLARE @CategoryIdTable TABLE (CategoryId INT);
    DECLARE @AllowedStoreIdTable TABLE (StoreId INT);

    IF @CategoryIds IS NOT NULL AND LTRIM(RTRIM(@CategoryIds)) <> ''
    BEGIN
        INSERT INTO @CategoryIdTable (CategoryId)
        SELECT TRY_CAST(value AS INT)
        FROM STRING_SPLIT(@CategoryIds, ',')
        WHERE TRY_CAST(value AS INT) IS NOT NULL;
    END

    IF @IsAdmin = 0 AND @AllowedStoreIds IS NOT NULL AND LTRIM(RTRIM(@AllowedStoreIds)) <> ''
    BEGIN
        INSERT INTO @AllowedStoreIdTable (StoreId)
        SELECT TRY_CAST(value AS INT)
        FROM STRING_SPLIT(@AllowedStoreIds, ',')
        WHERE TRY_CAST(value AS INT) IS NOT NULL;
    END

    ;WITH FilteredStock AS (
        SELECT
            p.ID AS Id,
            p.ItemId,
            p.SysBatchNo,
            p.BatchNo,
            COALESCE(i.Name, bm.MedicineName, bf.Name) AS ResolvedName,
            COALESCE(st.Name, 'Regular') AS StockType,
            p.TotalItemsInStock AS TotalItems,
            COALESCE(p.MinimumPanicLevel, i.MinimumPanicLevel, 0) AS MinimumPanicLevel,
            p.StoreId,
            ps.BranchId,
            p.ModifiedOn,
            i.ItemTypeId,
            COALESCE(it.Name, CASE WHEN p.TypeBit = 4 THEN 'Medicine' WHEN p.TypeBit = 5 THEN 'Fee' ELSE NULL END) AS ItemTypeName,
            c.Name AS CategoryName,
            i.IsFridgeItem,
            i.IsConsumptionItem
        FROM Pharmacy.PharmacyMedicinesStocks p
        LEFT JOIN Inv.PharmacyStores ps ON ps.StoreId = p.StoreId
        LEFT JOIN Inv.Items i ON p.ItemId = i.Id
        LEFT JOIN Inv.ItemTypes it ON i.ItemTypeId = it.Id
        LEFT JOIN Inv.Categories c ON i.CategoryId = c.Id
        LEFT JOIN Inv.StockTypes st ON p.StockTypeId = st.Id
        LEFT JOIN Pharmacy.BranchMedicines bm ON bm.Id = p.BranchMedicineId
        LEFT JOIN Data.BranchFees bf ON bf.Id = p.BranchSubServiceId
        WHERE (@BranchId IS NULL OR ps.BranchId = @BranchId)
            AND (@StoreId IS NULL OR p.StoreId = @StoreId)
            AND (@IsAdmin = 1 OR p.StoreId IN (SELECT StoreId FROM @AllowedStoreIdTable))
            AND (@ItemTypeId IS NULL OR i.ItemTypeId = @ItemTypeId)
            AND (@ItemId IS NULL OR p.ItemId = @ItemId)
            AND (@StockTypeId IS NULL OR p.StockTypeId = @StockTypeId)
            AND (
                @CategoryIds IS NULL
                OR LTRIM(RTRIM(@CategoryIds)) = ''
                OR i.CategoryId IN (SELECT CategoryId FROM @CategoryIdTable)
            )
            AND (
                @StockAvailability IS NULL
                OR @StockAvailability = 'All'
                OR (@StockAvailability = 'InStock' AND p.TotalItemsInStock > 0)
                OR (@StockAvailability = 'OutOfStock' AND COALESCE(p.TotalItemsInStock, 0) <= 0)
            )
            AND (
                @MinimumPanicLevelOnly = 0
                OR COALESCE(p.TotalItemsInStock, 0) <= COALESCE(p.MinimumPanicLevel, i.MinimumPanicLevel, 0)
            )
    ),
    Paged AS (
        SELECT *, COUNT(*) OVER() AS TotalCount
        FROM FilteredStock
        ORDER BY ResolvedName ASC
        OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY
    )
    SELECT
        Paged.Id,
        Paged.ItemId,
        COALESCE(Paged.ResolvedName, grnItem.DenormalizedItemName, '(item not found)') AS ItemName,
        Paged.StockType,
        Paged.TotalItems,
        Paged.MinimumPanicLevel,
        Paged.StoreId,
        Paged.BranchId,
        CAST(1 AS BIT) AS IsActive,
        Paged.ModifiedOn,
        Paged.ItemTypeId,
        Paged.ItemTypeName,
        Paged.CategoryName,
        Paged.IsFridgeItem,
        Paged.IsConsumptionItem,
        CAST(NULL AS NVARCHAR(200)) AS Location,
        Paged.TotalCount
    FROM Paged
    OUTER APPLY
    (
        SELECT TOP 1 gi.DenormalizedItemName
        FROM Inv.GoodsReceivingNotes g
        INNER JOIN Inv.GRNItems gi ON gi.GRNId = g.Id
        WHERE Paged.ResolvedName IS NULL
          AND g.InvoiceNo = Paged.SysBatchNo
          AND gi.BatchNo = Paged.BatchNo
        ORDER BY gi.Id DESC
    ) grnItem
    ORDER BY ItemName ASC;
END
