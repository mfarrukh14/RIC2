namespace InventoryManagement.Api.Models
{
    public class EstimatedPurchaseOrderSearchRequest
    {
        public int? StoreId { get; set; }
        public int? VendorId { get; set; }
        public int? ManufacturerId { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public int DeliveryLeadTimeDays { get; set; } = 7;
        public decimal SafetyStock { get; set; } = 20;
    }

    public class EstimatedPurchaseOrderItem
    {
        public int ItemId { get; set; }
        public string ItemName { get; set; } = string.Empty;
        public string? ItemTypeName { get; set; }
        public int StoreId { get; set; }
        public string StoreName { get; set; } = string.Empty;
        public int? VendorId { get; set; }
        public string? VendorName { get; set; }
        public int? ManufacturerId { get; set; }
        public string? ManufacturerName { get; set; }
        public decimal ReceivedQuantity { get; set; }
        public decimal ConsumedQuantity { get; set; }
        public decimal CurrentStock { get; set; }
        public decimal AverageDailyConsumption { get; set; }
        public int DeliveryLeadTimeDays { get; set; }
        public decimal SafetyStock { get; set; }
        public decimal RecommendedOrderQuantity { get; set; }
        public string RunningCategory { get; set; } = string.Empty;
        public decimal UnitBuyingPrice { get; set; }
        public DateTime? LastReceiptDate { get; set; }
    }
}