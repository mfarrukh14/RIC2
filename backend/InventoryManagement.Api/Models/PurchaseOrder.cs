using System.ComponentModel.DataAnnotations;

namespace InventoryManagement.Api.Models
{
    public class PurchaseOrderFilter : PagedRequest
    {
        public DateTime? DateFrom { get; set; }
        public DateTime? DateTo { get; set; }
        public int? VendorId { get; set; }
        public string? Status { get; set; }
        public string? Search { get; set; }
    }

    public class PurchaseOrderSummary
    {
        public int PurchaseOrderId { get; set; }
        public string PONumber { get; set; } = string.Empty;
        public string? ManualPONumber { get; set; }
        public int StoreId { get; set; }
        public string StoreName { get; set; } = string.Empty;
        public int VendorId { get; set; }
        public string VendorName { get; set; } = string.Empty;
        public DateTime CreatedOn { get; set; }
        public DateTime? POValidityDate { get; set; }
        public string Status { get; set; } = string.Empty;
        public int ItemsCount { get; set; }
        public decimal TotalQuantity { get; set; }
        public decimal TotalAmount { get; set; }
        public string? ItemSummary { get; set; }
        public string? Subject { get; set; }
    }

    public class PurchaseOrderDetails : PurchaseOrderSummary
    {
        public string? Instructions { get; set; }
        public string? TermsAndConditions { get; set; }
        public List<PurchaseOrderItem> Items { get; set; } = new();
    }

    public class PurchaseOrderItem
    {
        public int Id { get; set; }
        public int PurchaseOrderId { get; set; }
        public int? ItemId { get; set; }
        public int? MedicineId { get; set; }
        public int? SubServiceId { get; set; }
        public string ItemName { get; set; } = string.Empty;
        public string? ItemModel { get; set; }
        public string? ItemTypeName { get; set; }
        public decimal? PacketQuantity { get; set; }
        public decimal UnitQuantity { get; set; }
        public decimal? PacketPrice { get; set; }
        public decimal UnitPrice { get; set; }
        public decimal TotalPrice { get; set; }
    }

    public class PurchaseOrderCreateRequest
    {
        [Required]
        public int StoreId { get; set; }

        [Required]
        public int VendorId { get; set; }

        public string? ManualPONumber { get; set; }
        public DateTime? POValidityDate { get; set; }
        public string? Subject { get; set; }
        public string? Instructions { get; set; }
        public string? TermsAndConditions { get; set; }

        [MinLength(1, ErrorMessage = "At least one purchase order item is required.")]
        public List<PurchaseOrderCreateItem> Items { get; set; } = new();
    }

    public class PurchaseOrderCreateItem
    {
        public int? ItemId { get; set; }
        public int? MedicineId { get; set; }
        public int? SubServiceId { get; set; }

        public string? ItemType { get; set; }
        public decimal? PacketQuantity { get; set; }

        [Range(typeof(decimal), "0.01", "999999999")]
        public decimal UnitQuantity { get; set; }

        public decimal? PacketPrice { get; set; }

        [Range(typeof(decimal), "0.01", "999999999")]
        public decimal UnitPrice { get; set; }
    }
}