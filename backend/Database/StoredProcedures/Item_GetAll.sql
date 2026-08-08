-- =============================================
-- Author: System Generated
-- Create date: 2025-10-03
-- Description: Get all items with related data
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'Item_GetAll')
    DROP PROCEDURE [dbo].[Item_GetAll]
GO

CREATE PROCEDURE [dbo].[Item_GetAll]
    @SearchTerm NVARCHAR(200) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * (CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END);
    DECLARE @Take INT = CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END;

    SELECT
        i.Id,
        i.Name,
        i.Description,
        i.Model,
        i.BarCode,
        i.Specification,
        i.ItemTypeId,
        it.Name as ItemTypeName,
        i.BrandId,
        b.Name as BrandName,
        i.PackingId,
        p.Name as PackingName,
        i.UnitId,
        u.Name as UnitName,
        i.PriceId,
        pr.RetailPrice,
        pr.SalePrice,
        pr.MarketPrice,
        i.CategoryId,
        c.Name as CategoryName,
        i.SubCategoryId,
        sc.Name as SubCategoryName,
        i.IsActive,
        i.CreatedById,
        i.CreatedOn,
        i.ModifiedById,
        i.ModifiedOn,
        i.Frequency,
        i.IsProduct,
        i.BatchExpiryRequired,
        i.DescriptionForSale,
        i.SaleUnitId,
        su.Name as SaleUnitName,
        i.Conversion,
        i.CaseContains,
        i.HSCode,
        i.RetailPrice as ItemRetailPrice,
        i.CostMethod,
        i.SalesAccountId,
        sa.Name as SalesAccountName,
        i.InventoryAccountId,
        ia.Name as InventoryAccountName,
        i.ExpenseAccountId,
        ea.Name as ExpenseAccountName,
        i.TaxRateId,
        tr.Name as TaxRateName,
        i.TaxDescriptionId,
        td.Name as TaxDescriptionName,
        i.TaxTypeId,
        tt.Name as TaxTypeName,
        i.Colour,
        i.MinimumPanicLevel,
        i.IsHidePanicFromBill,
        i.QuantityPerPacket,
        i.IsConsumptionItem,
        i.IsFridgeItem,
        i.Code,
        i.MarketPrice as ItemMarketPrice,
        i.MinimumOrderPrice,
        i.MinimumOrderQuantity,
        i.PackageType,
        i.PackageSize,
        COUNT(*) OVER() AS TotalCount
    FROM Inv.Items i
    LEFT JOIN Inv.ItemTypes it ON i.ItemTypeId = it.Id
    LEFT JOIN Data.Brands b ON i.BrandId = b.Id
    LEFT JOIN Inv.Packings p ON i.PackingId = p.Id
    LEFT JOIN Inv.ItemUnits u ON i.UnitId = u.Id
    LEFT JOIN Inv.Prices pr ON i.PriceId = pr.Id
    LEFT JOIN Inv.Categories c ON i.CategoryId = c.Id
    LEFT JOIN Inv.SubCategories sc ON i.SubCategoryId = sc.Id
    LEFT JOIN Inv.ItemUnits su ON i.SaleUnitId = su.Id
    LEFT JOIN Inv.AccountCOAs sa ON i.SalesAccountId = sa.Id
    LEFT JOIN Inv.AccountCOAs ia ON i.InventoryAccountId = ia.Id
    LEFT JOIN Inv.AccountCOAs ea ON i.ExpenseAccountId = ea.Id
    LEFT JOIN Inv.TaxRates tr ON i.TaxRateId = tr.Id
    LEFT JOIN Inv.TaxDescriptions td ON i.TaxDescriptionId = td.Id
    LEFT JOIN Inv.TaxTypes tt ON i.TaxTypeId = tt.Id
    WHERE (
        @SearchTerm IS NULL OR @SearchTerm = ''
        OR i.Name LIKE '%' + @SearchTerm + '%'
        OR i.BarCode LIKE '%' + @SearchTerm + '%'
        OR it.Name LIKE '%' + @SearchTerm + '%'
        OR c.Name LIKE '%' + @SearchTerm + '%'
    )
    ORDER BY i.Name
    OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY;
END
GO