using System.ComponentModel.DataAnnotations;

namespace InventoryManagement.API.Models
{
    public class ReturnInventory
    {
        public int Id { get; set; }
        public string? InventoryNo { get; set; }
        public string? PurchaseOrderNo { get; set; }
        public int? BranchId { get; set; }
        public string? BranchName { get; set; }
        public int? StoreId { get; set; }
        public string? StoreName { get; set; }
        public int? ItemTypeId { get; set; }
        public string? ItemTypeName { get; set; }
        public int? ItemId { get; set; }
        public string? ItemName { get; set; }
        public int ReturnQuantity { get; set; }
        public int? StockTypeId { get; set; }
        public string? StockTypeName { get; set; }
        public int? VendorId { get; set; }
        public string? VendorName { get; set; }
        public DateTime ReturnDate { get; set; }
        public string? Reason { get; set; }
        public string? Notes { get; set; }
        public bool IsActive { get; set; }
        public int? CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
    }

    public class ReturnInventoryCreateRequest
    {
        public string? InventoryNo { get; set; }
        public string? PurchaseOrderNo { get; set; }
        public int? BranchId { get; set; }
        
        [Required]
        public int? StoreId { get; set; }
        
        public int? ItemTypeId { get; set; }
        
        [Required]
        public int ItemId { get; set; }
        
        [Required]
        public string ItemName { get; set; } = string.Empty;
        
        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "Return quantity must be at least 1")]
        public int ReturnQuantity { get; set; }
        
        public int? StockTypeId { get; set; }
        public int? VendorId { get; set; }
        public DateTime? ReturnDate { get; set; }
        public string? Reason { get; set; }
        public string? Notes { get; set; }
    }

    public class ReturnInventoryUpdateRequest
    {
        public string? InventoryNo { get; set; }
        public string? PurchaseOrderNo { get; set; }
        public int? BranchId { get; set; }
        
        [Required]
        public int? StoreId { get; set; }
        
        public int? ItemTypeId { get; set; }
        
        [Required]
        public int ItemId { get; set; }
        
        [Required]
        public string ItemName { get; set; } = string.Empty;
        
        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "Return quantity must be at least 1")]
        public int ReturnQuantity { get; set; }
        
        public int? StockTypeId { get; set; }
        public int? VendorId { get; set; }
        
        [Required]
        public DateTime ReturnDate { get; set; }
        
        public string? Reason { get; set; }
        public string? Notes { get; set; }
    }

    public class ReturnInventoryFilterRequest
    {
        public int? BranchId { get; set; }
        public int? StoreId { get; set; }
        public int? ItemTypeId { get; set; }
        public string? ItemType { get; set; } // 'Medicine', 'Disposable', 'Item'
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public string? PurchaseOrderNo { get; set; }
        public int? ItemId { get; set; }
        public string? InventoryNo { get; set; }
    }

    public class ReturnInventoryLookupData
    {
        public List<LookupItem> Branches { get; set; } = new();
        public List<LookupItem> Stores { get; set; } = new();
        public List<LookupItem> ItemTypes { get; set; } = new();
        public List<LookupItem> StockTypes { get; set; } = new();
        public List<LookupItem> Vendors { get; set; } = new();
        public List<LookupItem> Items { get; set; } = new();
    }
}
