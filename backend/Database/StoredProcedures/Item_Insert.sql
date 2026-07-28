-- =============================================
-- Author: System Generated
-- Create date: 2025-10-03
-- Description: Insert new item
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[Item_Insert]
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
    @CreatedById INT,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @NewId INT;

    INSERT INTO Inv.Items (
        Name, Description, Model, BarCode, Specification,
        ItemTypeId, BrandId, PackingId, UnitId, PriceId,
        CategoryId, SubCategoryId, Frequency, IsProduct,
        BatchExpiryRequired, DescriptionForSale, SaleUnitId,
        Conversion, CaseContains, HSCode, RetailPrice,
        CostMethod, SalesAccountId, InventoryAccountId,
        ExpenseAccountId, TaxRateId, TaxDescriptionId,
        TaxTypeId, Colour, MinimumPanicLevel, IsHidePanicFromBill,
        QuantityPerPacket, IsConsumptionItem, IsFridgeItem,
        Code, MarketPrice, MinimumOrderPrice, MinimumOrderQuantity,
        PackageType, PackageSize, IsActive, CreatedById, CreatedOn, ModifiedOn
    )
    VALUES (
        @Name, @Description, @Model, @BarCode, @Specification,
        @ItemTypeId, @BrandId, @PackingId, @UnitId, @PriceId,
        @CategoryId, @SubCategoryId, @Frequency, ISNULL(@IsProduct, 0),
        ISNULL(@BatchExpiryRequired, 0), @DescriptionForSale, @SaleUnitId,
        ISNULL(@Conversion, 0), ISNULL(TRY_CONVERT(INT, @CaseContains), 0), @HSCode, ISNULL(@RetailPrice, 0),
        ISNULL(@CostMethod, 0), @SalesAccountId, @InventoryAccountId,
        @ExpenseAccountId, @TaxRateId, @TaxDescriptionId,
        @TaxTypeId, @Colour, @MinimumPanicLevel, @IsHidePanicFromBill,
        @QuantityPerPacket, @IsConsumptionItem, @IsFridgeItem,
        @Code, @MarketPrice, @MinimumOrderPrice, @MinimumOrderQuantity,
        @PackageType, @PackageSize, @IsActive, @CreatedById, GETUTCDATE(), GETUTCDATE()
    );

    SET @NewId = SCOPE_IDENTITY();

    SELECT @NewId as Id;
END