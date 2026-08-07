using System.ComponentModel.DataAnnotations;

namespace InventoryManagement.API.Models
{
    public class PurchaseSummary
    {
        public int Id { get; set; }
        public DateTime PurchaseDate { get; set; }
        public string? BatchNo { get; set; }
        public int? ItemId { get; set; }
        public string ItemName { get; set; } = string.Empty;
        public int? StoreId { get; set; }
        public string? StoreName { get; set; }
        public int? VendorId { get; set; }
        public string? VendorName { get; set; }
        public string? InvoiceNo { get; set; }
        public DateTime? InvoiceDate { get; set; }
        public int Quantity { get; set; }
        public decimal Amount { get; set; }
        public decimal? AdvanceTax { get; set; }
        public decimal? Discount { get; set; }
        public decimal TotalPrice { get; set; }
        public int? BranchId { get; set; }
        public string? BranchName { get; set; }
        public int? ItemTypeId { get; set; }
        public string? ItemTypeName { get; set; }
        public string? ReportType { get; set; }
        public bool IsActive { get; set; }
        public int CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
    }

    public class PurchaseSummaryCreateRequest
    {
        [Required]
        public DateTime PurchaseDate { get; set; }
        
        public string? BatchNo { get; set; }
        
        [Required]
        public int ItemId { get; set; }
        
        [Required]
        public string ItemName { get; set; } = string.Empty;
        
        public int? StoreId { get; set; }
        public string? StoreName { get; set; }
        public int? VendorId { get; set; }
        public string? VendorName { get; set; }
        public string? InvoiceNo { get; set; }
        public DateTime? InvoiceDate { get; set; }
        
        [Required]
        [Range(1, int.MaxValue)]
        public int Quantity { get; set; }
        
        [Required]
        [Range(0, double.MaxValue)]
        public decimal Amount { get; set; }
        
        public decimal? AdvanceTax { get; set; }
        public decimal? Discount { get; set; }
        
        [Required]
        [Range(0, double.MaxValue)]
        public decimal TotalPrice { get; set; }
        
        public int? BranchId { get; set; }
        public int? ItemTypeId { get; set; }
        public string? ReportType { get; set; }
    }

    public class PurchaseSummaryUpdateRequest
    {
        [Required]
        public DateTime PurchaseDate { get; set; }
        
        public string? BatchNo { get; set; }
        
        [Required]
        public int ItemId { get; set; }
        
        [Required]
        public string ItemName { get; set; } = string.Empty;
        
        public int? StoreId { get; set; }
        public string? StoreName { get; set; }
        public int? VendorId { get; set; }
        public string? VendorName { get; set; }
        public string? InvoiceNo { get; set; }
        public DateTime? InvoiceDate { get; set; }
        
        [Required]
        [Range(1, int.MaxValue)]
        public int Quantity { get; set; }
        
        [Required]
        [Range(0, double.MaxValue)]
        public decimal Amount { get; set; }
        
        public decimal? AdvanceTax { get; set; }
        public decimal? Discount { get; set; }
        
        [Required]
        [Range(0, double.MaxValue)]
        public decimal TotalPrice { get; set; }
        
        public int? BranchId { get; set; }
        public int? ItemTypeId { get; set; }
        public string? ReportType { get; set; }
    }

    public class PurchaseSummaryFilterRequest
    {
        public int? BranchId { get; set; }
        public int? StoreId { get; set; }
        public int? ItemTypeId { get; set; }
        public string? ItemType { get; set; } // 'Medicine', 'Disposable', 'Item'
        public DateTime? InvoiceDateStart { get; set; }
        public DateTime? InvoiceDateEnd { get; set; }
        public DateTime? InventoryDateStart { get; set; }
        public DateTime? InventoryDateEnd { get; set; }
        public int? ItemId { get; set; }
        public string? InvoiceNo { get; set; }
        public string? ReportType { get; set; } // 'Purchase', 'Return', 'Both'
    }

    public class PurchaseSummaryTotals
    {
        public int TotalQuantity { get; set; }
        public decimal TotalAmount { get; set; }
        public decimal TotalAdvanceTax { get; set; }
        public decimal TotalDiscount { get; set; }
        public decimal TotalPrice { get; set; }
    }

    public class PurchaseSummaryResponse
    {
        public List<PurchaseSummary> Records { get; set; } = new();
        public PurchaseSummaryTotals Totals { get; set; } = new();
    }

    public class PurchaseSummaryLookupData
    {
        public List<LookupItem> Branches { get; set; } = new();
        public List<LookupItem> Stores { get; set; } = new();
        public List<LookupItem> ItemTypes { get; set; } = new();
        public List<LookupItem> Vendors { get; set; } = new();
        public List<LookupItem> Items { get; set; } = new();
    }
}
