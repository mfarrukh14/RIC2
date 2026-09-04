namespace InventoryManagement.Api.Models
{
    public class SaleSummaryDaily
    {
        public DateTime Date { get; set; }
        public int Count { get; set; }
        public decimal GrossSales { get; set; }
        public decimal Discounts { get; set; }
        public decimal TotalSales { get; set; }
        public decimal TotalSReturn { get; set; }
        public decimal NetSale { get; set; }
        public decimal CostOfSales { get; set; }
        public decimal GPAmount { get; set; }
        public decimal GPPercentage { get; set; }
    }

    public class SaleSummarySummary
    {
        public int TotalCount { get; set; }
        public decimal GrossSales { get; set; }
        public decimal Discounts { get; set; }
        public decimal TotalSales { get; set; }
        public decimal TotalSReturn { get; set; }
        public decimal NetSale { get; set; }
        public decimal CostOfSales { get; set; }
        public decimal GPAmount { get; set; }
        public decimal GPPercentage { get; set; }
    }

    public class SaleSummarySearchRequest : PagedRequest
    {
        public string? Store { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public string? Type { get; set; } // Daily, Monthly, Yearly
    }
}
