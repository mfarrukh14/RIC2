namespace InventoryManagement.Api.Models
{
    public class StockDetailRecord
    {
        public int Sr { get; set; }
        public string Name { get; set; } = string.Empty;
        public string StockType { get; set; } = string.Empty;
        public decimal BuyingPrice { get; set; }
        public decimal SellingPrice { get; set; }
        public int Opening { get; set; }
        public int Received { get; set; }
        public int Issued { get; set; }
        public int Balance { get; set; }
    }

    public class StockDetailRecordSearchRequest : PagedRequest
    {
        public string? Branch { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public string? Store { get; set; }
        public string? Vendor { get; set; }
        public string? StockType { get; set; }
        public string? Item { get; set; }
        public string? ItemType { get; set; }
        public string? SaleType { get; set; }
    }
}
