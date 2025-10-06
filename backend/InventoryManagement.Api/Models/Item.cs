namespace InventoryManagement.Api.Models
{
    public class Item
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? Model { get; set; }
        public string? BarCode { get; set; }
        public string? Specification { get; set; }
        public int? ItemTypeId { get; set; }
        public string? ItemTypeName { get; set; }
        public int? BrandId { get; set; }
        public string? BrandName { get; set; }
        public int? PackingId { get; set; }
        public string? PackingName { get; set; }
        public int? UnitId { get; set; }
        public string? UnitName { get; set; }
        public int? PriceId { get; set; }
        public decimal? RetailPrice { get; set; }
        public decimal? SalePrice { get; set; }
        public decimal? MarketPrice { get; set; }
        public int? CategoryId { get; set; }
        public string? CategoryName { get; set; }
        public int? SubCategoryId { get; set; }
        public string? SubCategoryName { get; set; }
        public bool IsActive { get; set; }
        public int? CreatedById { get; set; }
        public DateTime? CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
        public int? Frequency { get; set; }
        public bool? IsProduct { get; set; }
        public bool? BatchExpiryRequired { get; set; }
        public string? DescriptionForSale { get; set; }
        public int? SaleUnitId { get; set; }
        public string? SaleUnitName { get; set; }
        public decimal? Conversion { get; set; }
        public string? CaseContains { get; set; }
        public string? HSCode { get; set; }
        public decimal? ItemRetailPrice { get; set; }
        public int? CostMethod { get; set; }
        public int? SalesAccountId { get; set; }
        public string? SalesAccountName { get; set; }
        public int? InventoryAccountId { get; set; }
        public string? InventoryAccountName { get; set; }
        public int? ExpenseAccountId { get; set; }
        public string? ExpenseAccountName { get; set; }
        public int? TaxRateId { get; set; }
        public string? TaxRateName { get; set; }
        public int? TaxDescriptionId { get; set; }
        public string? TaxDescriptionName { get; set; }
        public int? TaxTypeId { get; set; }
        public string? TaxTypeName { get; set; }
        public string? Colour { get; set; }
        public float? MinimumPanicLevel { get; set; }
        public bool? IsHidePanicFromBill { get; set; }
        public float? QuantityPerPacket { get; set; }
        public bool? IsConsumptionItem { get; set; }
        public bool? IsFridgeItem { get; set; }
        public string? Code { get; set; }
        public decimal? ItemMarketPrice { get; set; }
        public decimal? MinimumOrderPrice { get; set; }
        public decimal? MinimumOrderQuantity { get; set; }
        public string? PackageType { get; set; }
        public string? PackageSize { get; set; }
    }

    public class ItemCreateRequest
    {
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? Model { get; set; }
        public string? BarCode { get; set; }
        public string? Specification { get; set; }
        public int? ItemTypeId { get; set; }
        public int? BrandId { get; set; }
        public int? PackingId { get; set; }
        public int? UnitId { get; set; }
        public int? PriceId { get; set; }
        public int? CategoryId { get; set; }
        public int? SubCategoryId { get; set; }
        public int? Frequency { get; set; }
        public bool? IsProduct { get; set; }
        public bool? BatchExpiryRequired { get; set; }
        public string? DescriptionForSale { get; set; }
        public int? SaleUnitId { get; set; }
        public decimal? Conversion { get; set; }
        public string? CaseContains { get; set; }
        public string? HSCode { get; set; }
        public decimal? RetailPrice { get; set; }
        public int? CostMethod { get; set; }
        public int? SalesAccountId { get; set; }
        public int? InventoryAccountId { get; set; }
        public int? ExpenseAccountId { get; set; }
        public int? TaxRateId { get; set; }
        public int? TaxDescriptionId { get; set; }
        public int? TaxTypeId { get; set; }
        public string? Colour { get; set; }
        public float? MinimumPanicLevel { get; set; }
        public bool? IsHidePanicFromBill { get; set; }
        public float? QuantityPerPacket { get; set; }
        public bool? IsConsumptionItem { get; set; }
        public bool? IsFridgeItem { get; set; }
        public string? Code { get; set; }
        public decimal? MarketPrice { get; set; }
        public decimal? MinimumOrderPrice { get; set; }
        public decimal? MinimumOrderQuantity { get; set; }
        public string? PackageType { get; set; }
        public string? PackageSize { get; set; }
        public bool IsActive { get; set; } = true;
    }

    public class ItemUpdateRequest
    {
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? Model { get; set; }
        public string? BarCode { get; set; }
        public string? Specification { get; set; }
        public int? ItemTypeId { get; set; }
        public int? BrandId { get; set; }
        public int? PackingId { get; set; }
        public int? UnitId { get; set; }
        public int? PriceId { get; set; }
        public int? CategoryId { get; set; }
        public int? SubCategoryId { get; set; }
        public int? Frequency { get; set; }
        public bool? IsProduct { get; set; }
        public bool? BatchExpiryRequired { get; set; }
        public string? DescriptionForSale { get; set; }
        public int? SaleUnitId { get; set; }
        public decimal? Conversion { get; set; }
        public string? CaseContains { get; set; }
        public string? HSCode { get; set; }
        public decimal? RetailPrice { get; set; }
        public int? CostMethod { get; set; }
        public int? SalesAccountId { get; set; }
        public int? InventoryAccountId { get; set; }
        public int? ExpenseAccountId { get; set; }
        public int? TaxRateId { get; set; }
        public int? TaxDescriptionId { get; set; }
        public int? TaxTypeId { get; set; }
        public string? Colour { get; set; }
        public float? MinimumPanicLevel { get; set; }
        public bool? IsHidePanicFromBill { get; set; }
        public float? QuantityPerPacket { get; set; }
        public bool? IsConsumptionItem { get; set; }
        public bool? IsFridgeItem { get; set; }
        public string? Code { get; set; }
        public decimal? MarketPrice { get; set; }
        public decimal? MinimumOrderPrice { get; set; }
        public decimal? MinimumOrderQuantity { get; set; }
        public string? PackageType { get; set; }
        public string? PackageSize { get; set; }
        public bool IsActive { get; set; } = true;
    }

    public class Category
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public bool IsActive { get; set; }
    }

    public class CategoryRequest
    {
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public bool IsActive { get; set; } = true;
    }

    public class SubCategory
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int? CategoryId { get; set; }
        public string? CategoryName { get; set; }
        public bool IsActive { get; set; }
    }

    public class Price
    {
        public int Id { get; set; }
        public decimal RetailPrice { get; set; }
        public decimal SalePrice { get; set; }
        public decimal MarketPrice { get; set; }
        public bool IsActive { get; set; }
    }

    public class TaxRate
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public decimal Rate { get; set; }
        public bool IsActive { get; set; }
    }

    public class TaxDescription
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public bool IsActive { get; set; }
    }

    public class TaxType
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public bool IsActive { get; set; }
    }
}