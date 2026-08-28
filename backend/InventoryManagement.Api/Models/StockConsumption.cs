namespace InventoryManagement.Api.Models
{
    // Main Stock Consumption model
    public class StockConsumption
    {
        public int Id { get; set; }
        public int StoreId { get; set; }
        public string? StoreName { get; set; }
        public int Type { get; set; }
        public int BranchId { get; set; }
        public string? BranchName { get; set; }
        public int? VoucherId { get; set; }
        public bool IsActive { get; set; }
        public int? CreatedById { get; set; }
        public string? CreatedByName { get; set; }
        public DateTime CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
        public bool IsDeleted { get; set; }
        public string? Remarks { get; set; }

        public List<StockConsumptionDetail>? Details { get; set; }
    }

    // Stock Consumption Detail model (line items)
    public class StockConsumptionDetail
    {
        public int Id { get; set; }
        public int StoreId { get; set; }
        public string? StoreName { get; set; }
        public int? MedicineId { get; set; }
        public string? MedicineName { get; set; }
        public int? SubServiceId { get; set; }
        public string? SubServiceName { get; set; }
        public int? ItemId { get; set; }
        public string? ItemName { get; set; }
        public int Type { get; set; }
        public int StockTypeId { get; set; }
        public string? StockTypeName { get; set; }
        public decimal Quantity { get; set; }
        public int BranchId { get; set; }
        public int? InventoryItemId { get; set; }
        public string? SysBatchNo { get; set; }
        public string? BatchNo { get; set; }
        public bool IsActive { get; set; }
        public int? CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
        public bool IsDeleted { get; set; }
        public int? StockConsumptionId { get; set; }
    }

    // Request models
    public class StockConsumptionCreateRequest
    {
        public int StoreId { get; set; }
        public int BranchId { get; set; }
        public int Type { get; set; }
        public int? CreatedById { get; set; }
        public string? Remarks { get; set; }
        public List<StockConsumptionDetailCreateRequest> Details { get; set; } = new();
    }

    public class StockConsumptionDetailCreateRequest
    {
        // Exactly one of ItemId/MedicineId/SubServiceId should be set - see
        // Item_GetAllWithMedicines / UnifiedItemLookupResult.
        public int? ItemId { get; set; }
        public int? MedicineId { get; set; }
        public int? SubServiceId { get; set; }
        public int Type { get; set; }
        public int StockTypeId { get; set; }
        public decimal Quantity { get; set; }
        public string? Remarks { get; set; }
    }

    public class StockConsumptionUpdateRequest
    {
        public int Id { get; set; }
        public int StoreId { get; set; }
        public int BranchId { get; set; }
        public int Type { get; set; }
        public int? ModifiedById { get; set; }
        public string? Remarks { get; set; }
        public List<StockConsumptionDetailUpdateRequest> Details { get; set; } = new();
    }

    public class StockConsumptionDetailUpdateRequest
    {
        public int? Id { get; set; }
        public int? ItemId { get; set; }
        public int? MedicineId { get; set; }
        public int? SubServiceId { get; set; }
        public int Type { get; set; }
        public int StockTypeId { get; set; }
        public decimal Quantity { get; set; }
        public string? Remarks { get; set; }
    }

    public class StockConsumptionSearchRequest : PagedRequest
    {
        public int? BranchId { get; set; }
        public int? StoreId { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public string? SearchTerm { get; set; }
    }

    // View model for list display
    public class StockConsumptionView
    {
        public int Id { get; set; }
        public string? StoreName { get; set; }
        public string? ItemName { get; set; }
        public string? Type { get; set; }
        public string? StockType { get; set; }
        public decimal Quantity { get; set; }
        public string? CreatedBy { get; set; }
        public DateTime? CreatedOn { get; set; }
    }
}
