namespace InventoryManagement.Api.Models
{
    public class SaleSummaryStockNoDiscount
    {
        public string Name { get; set; } = string.Empty;
        public decimal UnitPurchaseRate { get; set; }
        public decimal UnitSaleRate { get; set; }
        public decimal Quantity { get; set; }
        public decimal Sale { get; set; }
        public decimal TotalPurchaseRate { get; set; }
        public decimal Profit { get; set; }
    }

    public class SaleSummaryStockNoDiscountTotals
    {
        public decimal UnitPurchaseRate { get; set; }
        public decimal UnitSaleRate { get; set; }
        public decimal Quantity { get; set; }
        public decimal Sale { get; set; }
        public decimal PurchaseRate { get; set; }
        public decimal Profit { get; set; }
        public decimal DiscountAmount { get; set; }
    }

    public class SaleSummaryStockNoDiscountRequest : PagedRequest
    {
        public string? Store { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
    }
}
