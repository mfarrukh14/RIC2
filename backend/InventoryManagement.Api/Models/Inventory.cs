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
        public int? ItemId { get; set; }
        public int? MedicineId { get; set; }
        public int? SubServiceId { get; set; }
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
    public class InventoryFilterRequest : PagedRequest
    {
        public string? SearchTerm { get; set; }
        public int? VendorId { get; set; }
        public int? StoreId { get; set; }
        public DateTime? DateFrom { get; set; }
        public DateTime? DateTo { get; set; }
    }

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
        public int? ItemId { get; set; }
        public int? MedicineId { get; set; }
        public int? SubServiceId { get; set; }
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
    // Note: Store model moved to Models/Store.cs

    public class StockType
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public int StockTypeId { get; set; }
        public string StockTypeName { get; set; } = string.Empty;
        public string? Description { get; set; }
        public bool IsActive { get; set; }
    }

    public class StockTypeRequest
    {
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
    }

    public class StockTypeAssociation
    {
        public int Id { get; set; }
        public int PharmacyStoreId { get; set; }
        public string? StoreName { get; set; }
        public int StockTypes { get; set; }
        public string? StockTypeName { get; set; }
        // Nullable: rows seeded directly via StoreId/StockTypeId (see
        // SeedDemoData.sql) never set PatientTypes - there is no canonical
        // "PatientTypeId" twin column to fall back to, unlike PharmacyStoreId/
        // StockTypes which fall back to StoreId/StockTypeId.
        public int? PatientTypes { get; set; }
        public DateTime CreatedOn { get; set; }
    }

    public class StockTypeAssociationRequest
    {
        public int PharmacyStoreId { get; set; }
        public int StockTypes { get; set; }
        public int PatientTypes { get; set; }
    }

    public class StockExpiringItem
    {
        public int Id { get; set; }
        public string ItemName { get; set; } = string.Empty;
        public string? StockType { get; set; }
        public string? BatchNo { get; set; }
        public DateTime? MfgDate { get; set; }
        public DateTime? ExpiryDate { get; set; }
        public int TotalItems { get; set; }
        public int? StoreId { get; set; }
        public string? StoreName { get; set; }
    }

    public class StockExpiringRequest : PagedRequest
    {
        public int? StoreId { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public string? ItemIds { get; set; } // Comma-separated list
        public string? SearchTerm { get; set; }
    }

    public class InventoryLookupData
    {
        public List<Vendor> Vendors { get; set; } = new();
        public List<Store> Stores { get; set; } = new();
        public List<StockType> StockTypes { get; set; } = new();
        public List<Item> Items { get; set; } = new();
        public List<Manufacturer> Manufacturers { get; set; } = new();
        public List<Branch> Branches { get; set; } = new();
        public List<Category> Categories { get; set; } = new();
        public List<Brand> Brands { get; set; } = new();
    }

    // Rack models
    public class Rack
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public int StoreId { get; set; }
        public string? StoreName { get; set; }
        public string? Description { get; set; }
        public string? Location { get; set; }
        public int NumberOfRows { get; set; }
        public int NumberOfCols { get; set; }
        public int NumberOfDraws { get; set; }
        public int BranchId { get; set; }
        public bool IsActive { get; set; }
        public DateTime? CreatedOn { get; set; }
    }

    public class RackRequest
    {
        public int? Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public int StoreId { get; set; }
        public string? Description { get; set; }
        public string? Location { get; set; }
        public int NumberOfRows { get; set; }
        public int NumberOfCols { get; set; }
        public int NumberOfDraws { get; set; }
        public int BranchId { get; set; }
        public bool IsActive { get; set; } = true;
    }

    // Rack Row models
    // Stock models
    public class Stock
    {
        public int Id { get; set; }
        // Nullable: Pharmacy.PharmacyMedicinesStocks rows for Medicine/Fee stock
        // (TypeBit 4/5) have no ItemId - only real "Item" rows (TypeBit 15) do.
        public int? ItemId { get; set; }
        public string ItemName { get; set; } = string.Empty;
        public string? StockType { get; set; }
        // Decimal: Pharmacy.PharmacyMedicinesStocks.TotalItemsInStock is a real
        // decimal quantity (partial units are a real, intentional case there) -
        // truncating to int would silently lose data.
        public decimal? TotalItems { get; set; }
        public int? MinimumPanicLevel { get; set; }
        public int StoreId { get; set; }
        // Nullable: derived via a join to Pharmacy.PharmacyStores (no BranchId
        // column exists directly on the stock table itself).
        public int? BranchId { get; set; }
        public bool IsActive { get; set; }
        public DateTime? ModifiedOn { get; set; }
        public int? ItemTypeId { get; set; }
        public string? ItemTypeName { get; set; }
        public string? CategoryName { get; set; }
        public bool? IsFridgeItem { get; set; }
        public bool? IsConsumptionItem { get; set; }
        public string? Location { get; set; }
    }

    public class UpdateMinimumPanicLevelRequest
    {
        public int MinimumPanicLevel { get; set; }
    }

    public class StockSearchRequest : PagedRequest
    {
        public int? BranchId { get; set; }
        public int? StoreId { get; set; }
        public int? ItemTypeId { get; set; }
        public int? ItemId { get; set; }
        public string? CategoryIds { get; set; }
        public int? StockTypeId { get; set; }
        public string? GeneralType { get; set; }
        public int? MedicineTypeId { get; set; }
        public string? StockAvailability { get; set; }
        public bool? IsVaccine { get; set; }
        public bool MinimumPanicLevelOnly { get; set; } = false;
    }

    // Stock Audit models
    public class StockAudit
    {
        public int Id { get; set; }
        public int StoreId { get; set; }
        public int BranchId { get; set; }
        public DateTime StockAuditDate { get; set; }
        public string? Remarks { get; set; }
        public bool IsActive { get; set; }
        public int? CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
        public bool? IsDeleted { get; set; }
    }

    public class StockAuditRequest
    {
        public int StoreId { get; set; }
        public int BranchId { get; set; }
        public DateTime StockAuditDate { get; set; }
        public string? Remarks { get; set; }
        public int? CreatedById { get; set; }
    }

    public class StockAuditListRequest
    {
        public int? BranchId { get; set; }
        public int? StoreId { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
    }

    public class StockAuditListItem
    {
        public int Id { get; set; }
        public DateTime AuditDate { get; set; }
        public int StoreId { get; set; }
        public string? StoreName { get; set; }
        public int BranchId { get; set; }
        public string? BranchName { get; set; }
        public string? Remarks { get; set; }
        public bool IsActive { get; set; }
        public int? CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
    }

    public class StockAuditSearchRequest
    {
        public int? BranchId { get; set; }
        public int? StoreId { get; set; }
        public int? ItemTypeId { get; set; }
        public int? StockTypeId { get; set; }
        public string? ItemIds { get; set; }
        public string? ManufacturerIds { get; set; }
    }

    public class StockAuditItem
    {
        public int ItemId { get; set; }
        public string? ItemName { get; set; }
        public string? StockType { get; set; }
        public double TotalItems { get; set; }
        public double QtyOnShelf { get; set; }
        public double Difference { get; set; }
        public double MPL { get; set; }
        public decimal SalePrice { get; set; }
        public double QuantityPerPacket { get; set; }
        public DateTime? ModifiedOn { get; set; }
    }

    // Stock Stats models
    public class StockStatsSearchRequest
    {
        public int? BranchId { get; set; }
        public int? StoreId { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public int? ItemTypeId { get; set; }
        public string? ItemIds { get; set; }
        public int? StockTypeId { get; set; }
        public string SaleType { get; set; } = "OverAll";
    }

    public class StockStatsItem
    {
        public int ItemId { get; set; }
        public string? ItemName { get; set; }
        public string? StockType { get; set; }
        public double Opening { get; set; }
        public double Received { get; set; }
        public double Issued { get; set; }
        public double Balance { get; set; }
    }
}

