namespace InventoryManagement.Api.Models
{
    // Main Stock Consumption model
    public class StockConsumption
    {
        public Guid Id { get; set; }
        public Guid StoreId { get; set; }
        public string? StoreName { get; set; }
        public int Type { get; set; }
        public Guid BranchId { get; set; }
        public string? BranchName { get; set; }
        public Guid? VoucherId { get; set; }
        public bool IsActive { get; set; }
        public Guid? CreatedById { get; set; }
        public string? CreatedByName { get; set; }
        public DateTime CreatedOn { get; set; }
        public Guid? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
        public bool IsDeleted { get; set; }
        public string? Remarks { get; set; }
        
        public List<StockConsumptionDetail>? Details { get; set; }
    }

    // Stock Consumption Detail model (line items)
    public class StockConsumptionDetail
    {
        public Guid Id { get; set; }
        public Guid StoreId { get; set; }
        public string? StoreName { get; set; }
        public Guid? MedicineId { get; set; }
        public string? MedicineName { get; set; }
        public Guid? SubServiceId { get; set; }
        public string? SubServiceName { get; set; }
        public int ItemId { get; set; }
        public string? ItemName { get; set; }
        public int Type { get; set; }
        public int StockTypeId { get; set; }
        public string? StockTypeName { get; set; }
        public decimal Quantity { get; set; }
        public Guid BranchId { get; set; }
        public Guid? InventoryItemId { get; set; }
        public string? SysBatchNo { get; set; }
        public string? BatchNo { get; set; }
        public bool IsActive { get; set; }
        public Guid? CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public Guid? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
        public bool IsDeleted { get; set; }
        public Guid? StockConsumptionId { get; set; }
    }

    // Request models
    public class StockConsumptionCreateRequest
    {
        public Guid StoreId { get; set; }
        public Guid BranchId { get; set; }
        public int Type { get; set; }
        public Guid? CreatedById { get; set; }
        public string? Remarks { get; set; }
        public List<StockConsumptionDetailCreateRequest> Details { get; set; } = new();
    }

    public class StockConsumptionDetailCreateRequest
    {
        public int ItemId { get; set; }
        public int Type { get; set; }
        public int StockTypeId { get; set; }
        public decimal Quantity { get; set; }
        public string? Remarks { get; set; }
    }

    public class StockConsumptionUpdateRequest
    {
        public Guid Id { get; set; }
        public Guid StoreId { get; set; }
        public Guid BranchId { get; set; }
        public int Type { get; set; }
        public Guid? ModifiedById { get; set; }
        public string? Remarks { get; set; }
        public List<StockConsumptionDetailUpdateRequest> Details { get; set; } = new();
    }

    public class StockConsumptionDetailUpdateRequest
    {
        public Guid? Id { get; set; }
        public int ItemId { get; set; }
        public int Type { get; set; }
        public int StockTypeId { get; set; }
        public decimal Quantity { get; set; }
        public string? Remarks { get; set; }
    }

    public class StockConsumptionSearchRequest
    {
        public Guid? BranchId { get; set; }
        public Guid? StoreId { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
    }

    // View model for list display
    public class StockConsumptionView
    {
        public Guid Id { get; set; }
        public string? StoreName { get; set; }
        public string? ItemName { get; set; }
        public string? Type { get; set; }
        public string? StockType { get; set; }
        public decimal Quantity { get; set; }
        public string? CreatedBy { get; set; }
        public DateTime? CreatedOn { get; set; }
    }
}
