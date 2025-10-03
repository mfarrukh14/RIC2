-- =============================================
-- Author: System Generated
-- Create date: 2025-10-03
-- Description: Update existing item
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'Item_Update')
    DROP PROCEDURE [dbo].[Item_Update]
GO

CREATE PROCEDURE [dbo].[Item_Update]
    @Id INT,
    @Name NVARCHAR(MAX),
    @Description NVARCHAR(MAX) = NULL,
    @Model NVARCHAR(MAX) = NULL,
    @BarCode NVARCHAR(MAX) = NULL,
    @Specification NVARCHAR(MAX) = NULL,
    @ItemTypeId INT = NULL,
    @BrandId INT = NULL,
    @PackingId INT = NULL,
    @UnitId INT = NULL,
    @PriceId INT = NULL,
    @CategoryId INT = NULL,
    @SubCategoryId INT = NULL,
    @Frequency INT = NULL,
    @IsProduct BIT = NULL,
    @BatchExpiryRequired BIT = NULL,
    @DescriptionForSale NVARCHAR(MAX) = NULL,
    @SaleUnitId INT = NULL,
    @Conversion DECIMAL(18,4) = NULL,
    @CaseContains NVARCHAR(MAX) = NULL,
    @HSCode NVARCHAR(MAX) = NULL,
    @RetailPrice DECIMAL(18,4) = NULL,
    @CostMethod INT = NULL,
    @SalesAccountId INT = NULL,
    @InventoryAccountId INT = NULL,
    @ExpenseAccountId INT = NULL,
    @TaxRateId INT = NULL,
    @TaxDescriptionId INT = NULL,
    @TaxTypeId INT = NULL,
    @Colour NVARCHAR(MAX) = NULL,
    @MinimumPanicLevel REAL = NULL,
    @IsHidePanicFromBill BIT = NULL,
    @QuantityPerPacket REAL = NULL,
    @IsConsumptionItem BIT = NULL,
    @IsFridgeItem BIT = NULL,
    @Code NVARCHAR(MAX) = NULL,
    @MarketPrice DECIMAL(18,4) = NULL,
    @MinimumOrderPrice DECIMAL(18,2) = NULL,
    @MinimumOrderQuantity DECIMAL(18,2) = NULL,
    @PackageType NVARCHAR(MAX) = NULL,
    @PackageSize NVARCHAR(MAX) = NULL,
    @ModifiedById INT,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE dbo.Items
    SET
        Name = @Name,
        Description = @Description,
        Model = @Model,
        BarCode = @BarCode,
        Specification = @Specification,
        ItemTypeId = @ItemTypeId,
        BrandId = @BrandId,
        PackingId = @PackingId,
        UnitId = @UnitId,
        PriceId = @PriceId,
        CategoryId = @CategoryId,
        SubCategoryId = @SubCategoryId,
        Frequency = @Frequency,
        IsProduct = @IsProduct,
        BatchExpiryRequired = @BatchExpiryRequired,
        DescriptionForSale = @DescriptionForSale,
        SaleUnitId = @SaleUnitId,
        Conversion = @Conversion,
        CaseContains = @CaseContains,
        HSCode = @HSCode,
        RetailPrice = @RetailPrice,
        CostMethod = @CostMethod,
        SalesAccountId = @SalesAccountId,
        InventoryAccountId = @InventoryAccountId,
        ExpenseAccountId = @ExpenseAccountId,
        TaxRateId = @TaxRateId,
        TaxDescriptionId = @TaxDescriptionId,
        TaxTypeId = @TaxTypeId,
        Colour = @Colour,
        MinimumPanicLevel = @MinimumPanicLevel,
        IsHidePanicFromBill = @IsHidePanicFromBill,
        QuantityPerPacket = @QuantityPerPacket,
        IsConsumptionItem = @IsConsumptionItem,
        IsFridgeItem = @IsFridgeItem,
        Code = @Code,
        MarketPrice = @MarketPrice,
        MinimumOrderPrice = @MinimumOrderPrice,
        MinimumOrderQuantity = @MinimumOrderQuantity,
        PackageType = @PackageType,
        PackageSize = @PackageSize,
        IsActive = @IsActive,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETUTCDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT as AffectedRows;
END
GO