using System.ComponentModel.DataAnnotations;
using InventoryManagement.Api.Models;

namespace InventoryManagement.API.Models
{
    public class PurchaseSummaryInvoice
    {
        public int Id { get; set; }
        public DateTime InvoiceDate { get; set; }
        public string InvoiceNo { get; set; } = string.Empty;
        public int? VendorId { get; set; }
        public string? VendorName { get; set; }
        public decimal Amount { get; set; }
        public decimal? AdvanceTax { get; set; }
        public decimal? Discount { get; set; }
        public decimal TotalAmount { get; set; }
        public int? BranchId { get; set; }
        public string? BranchName { get; set; }
        public int? StoreId { get; set; }
        public string? StoreName { get; set; }
        public DateTime? InventoryDate { get; set; }
        public string? ReportType { get; set; }
        public string? InvoiceType { get; set; }
        public bool IsActive { get; set; }
        public int CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
    }

    public class PurchaseSummaryInvoiceCreateRequest
    {
        [Required]
        public DateTime InvoiceDate { get; set; }
        
        [Required]
        public string InvoiceNo { get; set; } = string.Empty;
        
        public int? VendorId { get; set; }
        public string? VendorName { get; set; }
        
        [Required]
        [Range(0, double.MaxValue)]
        public decimal Amount { get; set; }
        
        public decimal? AdvanceTax { get; set; }
        public decimal? Discount { get; set; }
        
        [Required]
        [Range(0, double.MaxValue)]
        public decimal TotalAmount { get; set; }
        
        public int? BranchId { get; set; }
        public int? StoreId { get; set; }
        public DateTime? InventoryDate { get; set; }
        public string? ReportType { get; set; }
        public string? InvoiceType { get; set; }
    }

    public class PurchaseSummaryInvoiceUpdateRequest
    {
        [Required]
        public DateTime InvoiceDate { get; set; }
        
        [Required]
        public string InvoiceNo { get; set; } = string.Empty;
        
        public int? VendorId { get; set; }
        public string? VendorName { get; set; }
        
        [Required]
        [Range(0, double.MaxValue)]
        public decimal Amount { get; set; }
        
        public decimal? AdvanceTax { get; set; }
        public decimal? Discount { get; set; }
        
        [Required]
        [Range(0, double.MaxValue)]
        public decimal TotalAmount { get; set; }
        
        public int? BranchId { get; set; }
        public int? StoreId { get; set; }
        public DateTime? InventoryDate { get; set; }
        public string? ReportType { get; set; }
        public string? InvoiceType { get; set; }
    }

    public class PurchaseSummaryInvoiceFilterRequest : PagedRequest
    {
        public int? BranchId { get; set; }
        public int? StoreId { get; set; }
        public DateTime? InventoryDateStart { get; set; }
        public DateTime? InventoryDateEnd { get; set; }
        public int? VendorId { get; set; }
        public DateTime? InvoiceDateStart { get; set; }
        public DateTime? InvoiceDateEnd { get; set; }
        public string? InvoiceNo { get; set; }
        public string? ReportType { get; set; } // 'Purchase', 'Return', 'Both'
        public string? InvoiceType { get; set; }
    }

    public class PurchaseSummaryInvoiceTotals
    {
        public decimal TotalAmount { get; set; }
        public decimal TotalAdvanceTax { get; set; }
        public decimal TotalDiscount { get; set; }
        public decimal GrandTotal { get; set; }
    }

    // Totals always cover the full filtered scope (not just the current page) -
    // Records is just the current page, so TotalCount/PageNumber/PageSize
    // travel alongside it rather than wrapping this whole response in
    // PagedResult<T>.
    public class PurchaseSummaryInvoiceResponse
    {
        public List<PurchaseSummaryInvoice> Records { get; set; } = new();
        public PurchaseSummaryInvoiceTotals Totals { get; set; } = new();
        public int TotalCount { get; set; }
        public int PageNumber { get; set; }
        public int PageSize { get; set; }
    }

    public class PurchaseSummaryInvoiceLookupData
    {
        public List<LookupItem> Branches { get; set; } = new();
        public List<LookupItem> Stores { get; set; } = new();
        public List<LookupItem> Vendors { get; set; } = new();
    }
}
