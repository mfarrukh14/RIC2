using System.ComponentModel.DataAnnotations;

namespace InventoryManagement.Api.Models
{
    // GRN Header
    public class GRN
    {
        public int Id { get; set; }
        public int? PurchaseOrderId { get; set; }
        public string? PONumber { get; set; }
        public int? VendorId { get; set; }
        public string? VendorName { get; set; }
        public string? InvoiceNo { get; set; }
        public int? StockTypeId { get; set; }
        public string? StockTypeName { get; set; }
        public DateTime? DateAndTime { get; set; }
        public string? VendorInvoiceNo { get; set; }
        public DateTime? VendorInvoiceDate { get; set; }
        public bool IsActive { get; set; }
        public int? CreatedById { get; set; }
        public DateTime? CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
        public List<GRNItem> Items { get; set; } = new();
    }

    // GRN Item
    public class GRNItem
    {
        public int Id { get; set; }
        public int GRNId { get; set; }
        public int? ItemId { get; set; }
        public int? MedicineId { get; set; }
        public int? SubServiceId { get; set; }
        public string? ItemName { get; set; }
        public int? ManufacturerId { get; set; }
        public string? ManufacturerName { get; set; }
        public DateTime? MfgDate { get; set; }
        public DateTime? ExpiryDate { get; set; }
        public string? RegistrationNumber { get; set; }
        public string? LotNo { get; set; }
        public string? BatchNo { get; set; }
        public int? NoOfBoxes { get; set; }
        public int? NoOfPackets { get; set; }
        public int? ItemPerPacket { get; set; }
        public int? TotalItem { get; set; }
        public int? PackQuantity { get; set; }
        public int? ReceivedQuantity { get; set; }
        public int? RemainingQuantity { get; set; }
        public decimal? TotalBuyingPrice { get; set; }
        public decimal? UnitBuyingPrice { get; set; }
        public decimal? AdvanceTaxPercentage { get; set; }
        public decimal? AdvanceTaxAmount { get; set; }
        public bool Discount { get; set; }
        public decimal? DiscountAmount { get; set; }
        public bool RetailCharges { get; set; }
        public decimal? RetailChargesAmount { get; set; }
        public bool GSTCharges { get; set; }
        public decimal? GSTChargesAmount { get; set; }
        public decimal? UnitSellingPrice { get; set; }
        public decimal? TotalSellingPrice { get; set; }
        public decimal? ProfitMarginPerItem { get; set; }
        public decimal? ProfitPerItem { get; set; }
    }

    // Purchase Order Info for GRN
    public class POForGRN
    {
        public int Id { get; set; }
        public string PONumber { get; set; } = string.Empty;
        public int VendorId { get; set; }
        public string VendorName { get; set; } = string.Empty;
        public DateTime? DateAndTime { get; set; }
        public string? Status { get; set; }
        public List<POItemForGRN> Items { get; set; } = new();
    }

    public class POItemForGRN
    {
        public int Id { get; set; }
        public int PurchaseOrderId { get; set; }
        public int? ItemId { get; set; }
        public int? MedicineId { get; set; }
        public int? SubServiceId { get; set; }
        public string ItemName { get; set; } = string.Empty;
        public int OrderedQuantity { get; set; }
        public int ReceivedQuantity { get; set; }
        public int RemainingQuantity { get; set; }
        public decimal? Rate { get; set; }
        public decimal? TotalAmount { get; set; }
    }

    // DTOs
    public class GRNCreateRequest
    {
        [Required]
        public int PurchaseOrderId { get; set; }
        public string PONumber { get; set; } = string.Empty;
        [Required]
        public int VendorId { get; set; }
        public string? InvoiceNo { get; set; }
        public int? StockTypeId { get; set; }
        public DateTime? DateAndTime { get; set; }
        public string? VendorInvoiceNo { get; set; }
        public DateTime? VendorInvoiceDate { get; set; }
        public List<GRNItemRequest> Items { get; set; } = new();
    }

    public class GRNUpdateRequest
    {
        public string? InvoiceNo { get; set; }
        public string? PONumber { get; set; }
        public int? StockTypeId { get; set; }
        public DateTime? DateAndTime { get; set; }
        public string? VendorInvoiceNo { get; set; }
        public DateTime? VendorInvoiceDate { get; set; }
    }

    public class GRNItemRequest
    {
        public int? ItemId { get; set; }
        public int? MedicineId { get; set; }
        public int? SubServiceId { get; set; }
        public int? ManufacturerId { get; set; }
        public DateTime? MfgDate { get; set; }
        public DateTime? ExpiryDate { get; set; }
        public string? RegistrationNumber { get; set; }
        public string? LotNo { get; set; }
        public string? BatchNo { get; set; }
        public int? NoOfBoxes { get; set; }
        public int? NoOfPackets { get; set; }
        public int? ItemPerPacket { get; set; }
        public int? TotalItem { get; set; }
        public int? PackQuantity { get; set; }
        public int? ReceivedQuantity { get; set; }
        public int? RemainingQuantity { get; set; }
        public decimal? TotalBuyingPrice { get; set; }
        public decimal? UnitBuyingPrice { get; set; }
        public decimal? AdvanceTaxPercentage { get; set; }
        public decimal? AdvanceTaxAmount { get; set; }
        public bool Discount { get; set; }
        public decimal? DiscountAmount { get; set; }
        public bool RetailCharges { get; set; }
        public decimal? RetailChargesAmount { get; set; }
        public bool GSTCharges { get; set; }
        public decimal? GSTChargesAmount { get; set; }
        public decimal? UnitSellingPrice { get; set; }
        public decimal? TotalSellingPrice { get; set; }
        public decimal? ProfitMarginPerItem { get; set; }
        public decimal? ProfitPerItem { get; set; }
    }

    public class GRNLookupData
    {
        public List<Vendor> Vendors { get; set; } = new();
        public List<StockType> StockTypes { get; set; } = new();
        public List<Manufacturer> Manufacturers { get; set; } = new();
        public List<PurchaseOrderOption> PurchaseOrders { get; set; } = new();
    }

    // Purchase Order picker for the GRN "receive against this PO" dropdown - the store
    // that gets credited on receipt is resolved from the selected PO's StoreId.
    public class PurchaseOrderOption
    {
        public int Id { get; set; }
        public string PONumber { get; set; } = string.Empty;
        public string? VendorName { get; set; }
    }
}
