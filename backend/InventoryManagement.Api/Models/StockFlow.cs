namespace InventoryManagement.Api.Models
{
    public class StockFlow
    {
        public DateTime DateTime { get; set; }
        public string TransactionType { get; set; } = string.Empty;
        public string RefNumber { get; set; } = string.Empty;
        public string ItemName { get; set; } = string.Empty;
        public string DemandRequestedStore { get; set; } = string.Empty;
        public string StockType { get; set; } = string.Empty;
        public decimal OpeningQuantity { get; set; }
        public decimal ReceivedQuantity { get; set; }
        public decimal IssuedQuantity { get; set; }
        public decimal BalanceQuantity { get; set; }
        public string? BatchNo { get; set; }
        public string ActionBy { get; set; } = string.Empty;
    }

    public class StockFlowSearchRequest
    {
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public string? Store { get; set; }
        public string? Item { get; set; }
        public string? InventoryNo { get; set; }
        public string? ChallanNo { get; set; }
        public string? InvoiceNo { get; set; }
        public string? DemandRequestNo { get; set; }
    }
}
