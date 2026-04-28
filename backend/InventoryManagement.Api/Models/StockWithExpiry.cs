namespace InventoryManagement.Api.Models
{
    public class StockWithExpiry
    {
        public int Id { get; set; }
        public int ItemId { get; set; }
        public string ItemName { get; set; } = string.Empty;
        public int StoreId { get; set; }
        public string StoreName { get; set; } = string.Empty;
        public string? BatchNumber { get; set; }
        public DateTime? ExpiryDate { get; set; }
        public int Quantity { get; set; }
        public string StockType { get; set; } = string.Empty;
        
        // Rack Location
        public int? RackId { get; set; }
        public string? RackName { get; set; }
        public int? RackRowId { get; set; }
        public string? RowNumber { get; set; }
        public int? RackColumnId { get; set; }
        public string? ColumnNumber { get; set; }
        public int? RackDrawerId { get; set; }
        public string? DrawerNumber { get; set; }
        
        // MPL and Status
        public double MPL { get; set; }
        public bool IsBelowMPL { get; set; }
        
        // Item Details
        public string? ItemType { get; set; }
        public bool? IsExpensiveItem { get; set; }
        public bool? IsFridgeItem { get; set; }
        public int? CategoryId { get; set; }
        
        public int TotalItemsInTransition { get; set; }
        
        public DateTime CreatedOn { get; set; }
        public int? CreatedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
        public int? ModifiedById { get; set; }
        
        // Computed property for location display
        public string Location => 
            $"{RackName ?? "N/A"},{RowNumber?.ToString() ?? "N/A"},{ColumnNumber?.ToString() ?? "N/A"},{DrawerNumber?.ToString() ?? "N/A"}";
    }
    
    public class StockWithExpiryFilter
    {
        public int? BranchId { get; set; }
        public int? StoreId { get; set; }
        public string? ItemType { get; set; }
        public int? ItemId { get; set; }
        public int? CategoryId { get; set; }
        public bool? IsExpensiveItem { get; set; }
        public bool? IsFridgeItem { get; set; }
        public bool MinimumPanicLevelOnly { get; set; }
    }
}
