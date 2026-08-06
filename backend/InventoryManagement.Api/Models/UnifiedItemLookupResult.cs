namespace InventoryManagement.Api.Models
{
    // One row from Item_GetAllWithMedicines: exactly one of ItemId/MedicineId/
    // SubServiceId is populated per row. Callers pass whichever one back when
    // saving a transaction line (StockConsumption, StockAdjustment, GRN,
    // PurchaseOrder, PurchaseRequisition, DemandRequest).
    public class UnifiedItemLookupResult
    {
        public int? ItemId { get; set; }
        public int? MedicineId { get; set; }
        public int? SubServiceId { get; set; }
        public string SourceType { get; set; } = string.Empty; // "Item" | "Medicine" | "Disposable"
        public string Name { get; set; } = string.Empty;
        public string? BarCode { get; set; }
        public decimal? Price { get; set; }
        public bool IsActive { get; set; }
    }
}
