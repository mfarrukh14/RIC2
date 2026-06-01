-- =============================================
-- Author: System Generated
-- Create date: 2025-10-03
-- Description: Get all items with related data
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'Item_GetAll')
    DROP PROCEDURE [dbo].[Item_GetAll]
GO

CREATE PROCEDURE [dbo].[Item_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    
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
        i.PackageSize
    FROM dbo.Items i
    LEFT JOIN dbo.ItemTypes it ON i.ItemTypeId = it.Id
    LEFT JOIN dbo.Brands b ON i.BrandId = b.Id
    LEFT JOIN dbo.Packings p ON i.PackingId = p.Id
    LEFT JOIN dbo.ItemUnits u ON i.UnitId = u.Id
    LEFT JOIN dbo.Prices pr ON i.PriceId = pr.Id
    LEFT JOIN dbo.Categories c ON i.CategoryId = c.Id
    LEFT JOIN dbo.SubCategories sc ON i.SubCategoryId = sc.Id
    LEFT JOIN dbo.ItemUnits su ON i.SaleUnitId = su.Id
    LEFT JOIN dbo.AccountCOAs sa ON i.SalesAccountId = sa.Id
    LEFT JOIN dbo.AccountCOAs ia ON i.InventoryAccountId = ia.Id
    LEFT JOIN dbo.AccountCOAs ea ON i.ExpenseAccountId = ea.Id
    LEFT JOIN dbo.TaxRates tr ON i.TaxRateId = tr.Id
    LEFT JOIN dbo.TaxDescriptions td ON i.TaxDescriptionId = td.Id
    LEFT JOIN dbo.TaxTypes tt ON i.TaxTypeId = tt.Id
    WHERE i.IsActive = 1
    ORDER BY i.Name;
END
GO