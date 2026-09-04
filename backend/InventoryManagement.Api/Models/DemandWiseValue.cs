namespace InventoryManagement.Api.Models
{
    public class DemandWiseValueFilter : PagedRequest
    {
        public int? BranchId { get; set; }
        public int? StoreId { get; set; }
        public string? ItemType { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public int? ItemId { get; set; }
        public string? Search { get; set; }
    }

    public class DemandWiseValueRow
    {
        public int Sr { get; set; }
        public string ItemName { get; set; } = string.Empty;
        public string DRNo { get; set; } = string.Empty;
        public string? BatchNo { get; set; }
        public DateTime IssuedDate { get; set; }
        public int IssuedQty { get; set; }
        public string Status { get; set; } = string.Empty;
        public decimal UnitBuyingPrice { get; set; }
        public decimal TotalBuyingPrice { get; set; }
        public string ItemType { get; set; } = "Item(s)";
        public int BranchId { get; set; }
        public string BranchName { get; set; } = string.Empty;
        public int StoreId { get; set; }
        public string StoreName { get; set; } = string.Empty;
        public int? ItemId { get; set; }
    }

    public class DemandWiseValueTotals
    {
        public int TotalIssuedQty { get; set; }
        public decimal TotalUnitBuyingPrice { get; set; }
        public decimal TotalBuyingPrice { get; set; }
    }

    public class DemandWiseValueResponse
    {
        public IReadOnlyList<DemandWiseValueRow> Items { get; set; } = Array.Empty<DemandWiseValueRow>();
        public int TotalCount { get; set; }
        public int PageNumber { get; set; }
        public int PageSize { get; set; }
        public DemandWiseValueTotals Totals { get; set; } = new();
    }
}