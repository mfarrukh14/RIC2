namespace InventoryManagement.Api.Models
{
    // Main Inventory (GRN) model
    public class Inventory
    {
        public int Id { get; set; }
        public string? PurchaseOrderNumber { get; set; }
        public string? InvoiceNo { get; set; }
        public int? PurchaseOrderId { get; set; }
        public int? VendorId { get; set; }
        public string? VendorName { get; set; }
        public int StoreId { get; set; }
        public string? StoreName { get; set; }
        public int BranchId { get; set; }
        public string? BranchName { get; set; }
        public bool IsActive { get; set; }
        public int? CreatedById { get; set; }
        public DateTime? CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
        public bool? IsFinalized { get; set; }
        public int? StockTypeId { get; set; }
        public string? StockTypeName { get; set; }
        public string? VendorInvoiceNumber { get; set; }
        public DateTime? VendorInvoiceTimestamp { get; set; }
        public float? Amount { get; set; }
        public float? Discount { get; set; }
        public int? DiscountType { get; set; }
        public float? Total { get; set; }
        public float? PaidAmount { get; set; }
        public int? PaymentStatusId { get; set; }
        public float? TotalPaidAmount { get; set; }
        public int? PayableAccountId { get; set; }
        public bool? IsPaymentPending { get; set; }
        public int? VoucherId { get; set; }
        public float? TotalVoucherPaidAmount { get; set; }
        public float? TotalBuyingPrice { get; set; }
        public string? ReceiptPath { get; set; }
        public float? AdvanceTaxPercentage { get; set; }
        public float? AdvanceTaxCalculatedAmount { get; set; }
        public float? RetailCharges { get; set; }
        public int? RetailChargesType { get; set; }
        public float? GSTCharges { get; set; }
        public float? RetailChargesCalculatedAmount { get; set; }
        public float? GSTChargesCalculatedAmount { get; set; }
        public string? ManualPurchaseOrderNumber { get; set; }
        public int? TotalQuantity { get; set; }
        
        public List<InventoryDetail>? Details { get; set; }
    }

    // Inventory detail (line item) model
    public class InventoryDetail
    {
        public int Id { get; set; }
        public int InventoryId { get; set; }
        public int ItemId { get; set; }
        public string? ItemName { get; set; }
        public int? ManufacturerId { get; set; }
        public string? ManufacturerName { get; set; }
        public DateTime? MfgDate { get; set; }
        public DateTime? ExpiryDate { get; set; }
        public int? NoOfBoxes { get; set; }
        public int? NoOfPackets { get; set; }
        public int? ItemsPerPacket { get; set; }
        public int? TotalItems { get; set; }
        public int? PackQuantity { get; set; }
        public float? UnitBuyingPrice { get; set; }
        public float? TotalBuyingPrice { get; set; }
        public float? AdvanceTaxPercentage { get; set; }
        public float? AdvanceTaxAmount { get; set; }
        public bool? Discount { get; set; }
        public float? DiscountAmount { get; set; }
        public bool? RetailCharges { get; set; }
        public float? RetailChargesAmount { get; set; }
        public bool? GSTCharges { get; set; }
        public float? GSTChargesAmount { get; set; }
        public float? UnitSellingPrice { get; set; }
        public float? TotalSellingPrice { get; set; }
        public float? ProfitMarginPerItem { get; set; }
        public float? ProfitPerItem { get; set; }
    }

    // Request models
    public class InventoryCreateRequest
    {
        public int VendorId { get; set; }
        public int StoreId { get; set; }
        public int BranchId { get; set; }
        public int StockTypeId { get; set; }
        public string? VendorInvoiceNumber { get; set; }
        public DateTime? VendorInvoiceTimestamp { get; set; }
        public string? ManualPurchaseOrderNumber { get; set; }
    }

    public class InventoryUpdateRequest
    {
        public int VendorId { get; set; }
        public int StoreId { get; set; }
        public int BranchId { get; set; }
        public int StockTypeId { get; set; }
        public string? VendorInvoiceNumber { get; set; }
        public DateTime? VendorInvoiceTimestamp { get; set; }
        public string? ManualPurchaseOrderNumber { get; set; }
        public float? Amount { get; set; }
        public float? Discount { get; set; }
        public int? DiscountType { get; set; }
        public float? Total { get; set; }
        public float? AdvanceTaxPercentage { get; set; }
        public float? AdvanceTaxCalculatedAmount { get; set; }
        public float? RetailCharges { get; set; }
        public int? RetailChargesType { get; set; }
        public float? GSTCharges { get; set; }
        public float? RetailChargesCalculatedAmount { get; set; }
        public float? GSTChargesCalculatedAmount { get; set; }
        public float? TotalBuyingPrice { get; set; }
    }

    public class InventoryDetailCreateRequest
    {
        public int InventoryId { get; set; }
        public int ItemId { get; set; }
        public int? ManufacturerId { get; set; }
        public DateTime? MfgDate { get; set; }
        public DateTime? ExpiryDate { get; set; }
        public int? NoOfBoxes { get; set; }
        public int? NoOfPackets { get; set; }
        public int? ItemsPerPacket { get; set; }
        public int? TotalItems { get; set; }
        public int? PackQuantity { get; set; }
        public float? UnitBuyingPrice { get; set; }
        public float? TotalBuyingPrice { get; set; }
        public float? AdvanceTaxPercentage { get; set; }
        public float? AdvanceTaxAmount { get; set; }
        public bool? Discount { get; set; }
        public float? DiscountAmount { get; set; }
        public bool? RetailCharges { get; set; }
        public float? RetailChargesAmount { get; set; }
        public bool? GSTCharges { get; set; }
        public float? GSTChargesAmount { get; set; }
        public float? UnitSellingPrice { get; set; }
        public float? TotalSellingPrice { get; set; }
        public float? ProfitMarginPerItem { get; set; }
        public float? ProfitPerItem { get; set; }
    }

    public class InventoryDetailUpdateRequest : InventoryDetailCreateRequest
    {
        public int Id { get; set; }
    }

    // Lookup models
    public class Store
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
    }

    public class StockType
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public bool IsActive { get; set; }
    }

    public class StockTypeRequest
    {
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
    }

    public class InventoryLookupData
    {
        public List<Vendor> Vendors { get; set; } = new();
        public List<Store> Stores { get; set; } = new();
        public List<StockType> StockTypes { get; set; } = new();
        public List<Item> Items { get; set; } = new();
        public List<Manufacturer> Manufacturers { get; set; } = new();
        public List<Branch> Branches { get; set; } = new();
    }
}
