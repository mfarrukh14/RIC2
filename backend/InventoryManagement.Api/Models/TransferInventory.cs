using System.ComponentModel.DataAnnotations;

namespace InventoryManagement.Api.Models
{
    public class TransferInventory
    {
        public int Id { get; set; }
        public string DRNo { get; set; } = string.Empty;
        public int FromStoreId { get; set; }
        public string? FromStoreName { get; set; }
        public int ToStoreId { get; set; }
        public string? ToStoreName { get; set; }
        public int StockTypeId { get; set; }
        public string? StockTypeName { get; set; }
        public int ItemId { get; set; }
        public string? ItemName { get; set; }
        public int Quantity { get; set; }
        public DateTime TransferDate { get; set; }
        public string Status { get; set; } = "Pending";
        public string? Notes { get; set; }
        public bool IsActive { get; set; }
        public int? CreatedById { get; set; }
        public DateTime? CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
    }

    public class TransferInventoryCreateRequest
    {
        [Required]
        public int FromStoreId { get; set; }
        
        [Required]
        public int ToStoreId { get; set; }
        
        [Required]
        public int StockTypeId { get; set; }
        
        [Required]
        public int ItemId { get; set; }
        
        public string? ItemName { get; set; }
        
        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "Quantity must be at least 1")]
        public int Quantity { get; set; }
        
        public DateTime? TransferDate { get; set; }
        public string? Status { get; set; }
        public string? Notes { get; set; }
    }

    public class TransferInventoryUpdateRequest
    {
        [Required]
        public int FromStoreId { get; set; }
        
        [Required]
        public int ToStoreId { get; set; }
        
        [Required]
        public int StockTypeId { get; set; }
        
        [Required]
        public int ItemId { get; set; }
        
        public string? ItemName { get; set; }
        
        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "Quantity must be at least 1")]
        public int Quantity { get; set; }
        
        public string? Status { get; set; }
        public string? Notes { get; set; }
    }

    public class TransferInventoryLookupData
    {
        public List<Store> Stores { get; set; } = new();
        public List<StockType> StockTypes { get; set; } = new();
        public List<Item> Items { get; set; } = new();
    }
}
