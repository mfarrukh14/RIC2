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
--     BranchMedicineId/BranchSubServiceId - but BranchMedicineId/
--     BranchSubServiceId are 100% NULL on every live row (the original
--     iHealthCure migration into this table had no ID map for them either -
--     see MigratePharmacyMedicinesStocks_HMSMAIN_TF.sql). For TypeBit 4/5
--     rows (71% of the table), the only way to recover what item a row is
--     for is by cross-referencing its SysBatchNo/BatchNo against the
--     already-migrated Inv.GoodsReceivingNotes/Inv.GRNItems (SysBatchNo
--     matches GoodsReceivingNotes.InvoiceNo, BatchNo matches
--     GRNItems.BatchNo) - verified 18,691 of 18,869 otherwise-unresolvable
--     rows (99%) recover a real name this way.
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
        p.ID AS Id,
        p.ItemId,
        COALESCE(i.Name, grnItem.DenormalizedItemName, '(item not found)') AS ItemName,
        COALESCE(st.Name, 'Regular') AS StockType,
        p.TotalItemsInStock AS TotalItems,
        COALESCE(p.MinimumPanicLevel, i.MinimumPanicLevel, 0) AS MinimumPanicLevel,
        p.StoreId,
        ps.BranchId,
        CAST(1 AS BIT) AS IsActive,
        p.ModifiedOn,
        i.ItemTypeId,
        COALESCE(it.Name, CASE WHEN p.TypeBit = 4 THEN 'Medicine' WHEN p.TypeBit = 5 THEN 'Fee' ELSE NULL END) AS ItemTypeName,
        c.Name AS CategoryName,
        i.IsFridgeItem,
        i.IsConsumptionItem,
        CAST(NULL AS NVARCHAR(200)) AS Location
    FROM Pharmacy.PharmacyMedicinesStocks p
    LEFT JOIN Inv.PharmacyStores ps ON ps.StoreId = p.StoreId
    LEFT JOIN Inv.Items i ON p.ItemId = i.Id
    LEFT JOIN Inv.ItemTypes it ON i.ItemTypeId = it.Id
    LEFT JOIN Inv.Categories c ON i.CategoryId = c.Id
    LEFT JOIN Inv.StockTypes st ON p.StockTypeId = st.Id
    OUTER APPLY
    (
        SELECT TOP 1 gi.DenormalizedItemName
        FROM Inv.GoodsReceivingNotes g
        INNER JOIN Inv.GRNItems gi ON gi.GRNId = g.Id
        WHERE p.ItemId IS NULL
          AND g.InvoiceNo = p.SysBatchNo
          AND gi.BatchNo = p.BatchNo
        ORDER BY gi.Id DESC
    ) grnItem
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
    ORDER BY ItemName ASC;
END
GO

PRINT 'Stock search stored procedure created successfully';
