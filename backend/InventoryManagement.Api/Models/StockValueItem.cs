namespace InventoryManagement.Api.Models
{
    public class StockValueItem
    {
        public string StoreName { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string BatchNo { get; set; } = string.Empty;
        public int TotalItems { get; set; }
        public decimal UnitPurchaseRate { get; set; }
        public decimal TotalPurchaseRate { get; set; }
        public decimal UnitSaleRate { get; set; }
        public decimal TotalSaleRate { get; set; }
    }

    public class StockValueSearchRequest
    {
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public string? Store { get; set; }
        public string? ItemType { get; set; }
    }

    public class StockValueDetailRequest
    {
        public string BatchNo { get; set; } = string.Empty;
        public string ItemName { get; set; } = string.Empty;
    }

    public class GRNReportItem
    {
        public int Sr { get; set; }
        public string Items { get; set; } = string.Empty;
        public string Mfr { get; set; } = string.Empty;
        public DateTime? MfgDate { get; set; }
        public DateTime? ExpDate { get; set; }
        public string? BatchNo { get; set; }
        public int? Boxes { get; set; }
        public int? Packs { get; set; }
        public int? QtyPerPack { get; set; }
        public int TotalQty { get; set; }
        public int PackQty { get; set; }
        public decimal TotalPrice { get; set; }
        public decimal UnitPrice { get; set; }
        public decimal AdvanceTax { get; set; }
        public decimal AdvanceTaxAmount { get; set; }
        public decimal UnitSalePrice { get; set; }
        public decimal RetailCharges { get; set; }
        public decimal RetailChargesAmount { get; set; }
        public decimal GSTCharges { get; set; }
        public decimal GSTChargesAmount { get; set; }
        public decimal TotalSalePrice { get; set; }
        public decimal Margin { get; set; }
        public decimal Amount { get; set; }
        public decimal Discount { get; set; }
        public decimal Total { get; set; }
    }

    public class GRNReport
    {
        public string InventoryNo { get; set; } = string.Empty;
        public string EnteredBy { get; set; } = string.Empty;
        public DateTime DateAndTime { get; set; }
        public string PONumber { get; set; } = string.Empty;
        public string PODate { get; set; } = string.Empty;
        public string ManualPONumber { get; set; } = string.Empty;
        public string StockType { get; set; } = string.Empty;
        public string Regular { get; set; } = string.Empty;
        public string StoreName { get; set; } = string.Empty;
        public string VendorName { get; set; } = string.Empty;
        public string VendorAddress { get; set; } = string.Empty;
        public string VendorEmail { get; set; } = string.Empty;
        public string VendorContactNo { get; set; } = string.Empty;
        public List<GRNReportItem> Items { get; set; } = new();
        public decimal SubTotal { get; set; }
        public decimal Discount { get; set; }
        public decimal Total { get; set; }
    }
}
