namespace InventoryManagement.Api.Models
{
    public class ExpiredStock
    {
        public string Name { get; set; } = string.Empty;
        public string StockType { get; set; } = string.Empty;
        public string? BatchNo { get; set; }
        public DateTime? MfgDate { get; set; }
        public DateTime? ExpDate { get; set; }
        public int TotalItems { get; set; }
    }

    public class ExpiredStockSearchRequest : PagedRequest
    {
        public string? StoreName { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public string? Item { get; set; }
        public string? SearchTerm { get; set; }
    }
}
