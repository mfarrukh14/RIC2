-- =============================================
-- Stock Search Stored Procedure
--
-- Reads from Pharmacy.PharmacyMedicinesStocks - the live, actively-maintained
-- stock ledger the real HMS pharmacy operations (dispense/sale/etc.) update -
-- NOT Inv.Stocks, which is a one-time migrated snapshot this app's own
-- features had been reading/writing in isolation ever since. Investigation
-- before this rewrite found the two had already diverged: of the store+item
-- pairs present in both, 44% disagreed on quantity, and Pharmacy.
-- PharmacyMedicinesStocks had 18,869 store+item combinations Inv.Stocks
-- didn't even have.
--
-- SCHEMA DIFFERENCES vs Inv.Stocks handled here:
--   - No BranchId column - derived via a join to Pharmacy.PharmacyStores.
--   - No IsActive column - every row is treated as active (no soft-delete
--     concept exists at this table's grain).
--   - TotalItemsInStock is DECIMAL, not INT - kept as decimal so partial-unit
--     quantities aren't silently truncated.
--   - Row identity is by TypeBit (15=Item/4=Medicine/5=Fee) + ItemId/
--     BranchMedicineId/BranchSubServiceId. BranchMedicineId/BranchSubServiceId
--     were 100% NULL on every live row until a later backfill (matched each
--     row back to iHealthCure and resolved the real link via
--     Pharmacy.BranchMedicines.Qid / Data.BranchFees.QID) populated ~99% of
--     them, resolvable via a cheap PK join. The remaining ~1% fall back to an
--     OUTER APPLY against Inv.GoodsReceivingNotes/Inv.GRNItems (a correlated
--     SysBatchNo/BatchNo string match) - but that fallback is applied AFTER
--     filtering/sorting/paging below, against at most @PageSize rows, not the
--     whole table. Running it per-row across the full ~27,000-row table
--     (unavoidable if it's part of the ORDER BY key before paging) is what
--     made unfiltered/broadly-filtered searches slow enough to time out;
--     confirmed via a live query dropping from 40M+ logical reads to a few
--     thousand once restructured this way.
-- =============================================
-- Paginated - see PaginationHelper.cs / GRN_GetAll for the shared convention.
-- @PageNumber/@PageSize default to page 1 of 10; TotalCount comes back via
-- COUNT(*) OVER() so the frontend gets paging + total in one round trip
-- instead of loading the whole ~27,000-row table on every search.
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
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * (CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END);
    DECLARE @Take INT = CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END;
    DECLARE @CategoryIdTable TABLE (CategoryId INT);

    IF @CategoryIds IS NOT NULL AND LTRIM(RTRIM(@CategoryIds)) <> ''
    BEGIN
        INSERT INTO @CategoryIdTable (CategoryId)
        SELECT TRY_CAST(value AS INT)
        FROM STRING_SPLIT(@CategoryIds, ',')
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
GO

PRINT 'Stock search stored procedure created successfully';
