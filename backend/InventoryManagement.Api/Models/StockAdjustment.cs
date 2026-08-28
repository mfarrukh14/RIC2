namespace InventoryManagement.Api.Models
{
    // Main Stock Adjustment model
    public class StockAdjustment
    {
        public int Id { get; set; }
        public int StoreId { get; set; }
        public string? StoreName { get; set; }
        public int Type { get; set; } // 1 = Less/Decrease, 2 = Issue (based on image dropdown)
        public string? TypeName { get; set; }
        public int? VoucherId { get; set; }
        public int BranchId { get; set; }
        public string? BranchName { get; set; }
        public int? CreatedById { get; set; }
        public string? CreatedByName { get; set; }
        public DateTime CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
        public bool IsActive { get; set; }
        public bool IsDeleted { get; set; }
        
        public List<StockAdjustmentDetail>? Details { get; set; }
    }

    // Stock Adjustment Detail model (line items)
    public class StockAdjustmentDetail
    {
        public int Id { get; set; }
        public int StockAdjustmentId { get; set; }
        public int? MedicineId { get; set; }
        public string? MedicineName { get; set; }
        public int? SubServiceId { get; set; }
        public string? SubServiceName { get; set; }
        public int? ItemId { get; set; }
        public string? ItemName { get; set; }
        public int Type { get; set; } // 1 = Less/Decrease, 2 = Issue
        public string? TypeName { get; set; }
        public int StockTypeId { get; set; }
        public string? StockTypeName { get; set; }
        public decimal Quantity { get; set; }
        public int BranchId { get; set; }
        public int? CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
        public bool IsActive { get; set; }
        public bool IsDeleted { get; set; }
        public int? InventoryItemId { get; set; }
        public string? SysBatchNo { get; set; }
        public string? BatchNo { get; set; }
        public int? StockAdjustmentId2 { get; set; }
        public decimal? PurchaseValue { get; set; }
        public decimal? SaleValue { get; set; }
    }

    // Request models
    public class StockAdjustmentCreateRequest
    {
        public int StoreId { get; set; }
        public int BranchId { get; set; }
        public int Type { get; set; }
        public int? CreatedById { get; set; }
        public List<StockAdjustmentDetailCreateRequest> Details { get; set; } = new();
    }

    public class StockAdjustmentDetailCreateRequest
    {
        public int? ItemId { get; set; }
        public int? MedicineId { get; set; }
        public int? SubServiceId { get; set; }
        public int Type { get; set; }
        public int StockTypeId { get; set; }
        public decimal Quantity { get; set; }
        public decimal? SaleValue { get; set; }
        public string? Remarks { get; set; }
    }

    public class StockAdjustmentUpdateRequest
    {
        public int Id { get; set; }
        public int StoreId { get; set; }
        public int BranchId { get; set; }
        public int Type { get; set; }
        public int? ModifiedById { get; set; }
        public List<StockAdjustmentDetailUpdateRequest> Details { get; set; } = new();
    }

    public class StockAdjustmentDetailUpdateRequest
    {
        public int? Id { get; set; }
        public int? ItemId { get; set; }
        public int? MedicineId { get; set; }
        public int? SubServiceId { get; set; }
        public int Type { get; set; }
        public int StockTypeId { get; set; }
        public decimal Quantity { get; set; }
        public decimal? SaleValue { get; set; }
        public string? Remarks { get; set; }
    }

    public class StockAdjustmentSearchRequest : PagedRequest
    {
        public int? BranchId { get; set; }
        public int? StoreId { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public string? SearchTerm { get; set; }
    }

    // View model for list display
    public class StockAdjustmentView
    {
        public int Id { get; set; }
        public string? StoreName { get; set; }
        public string? ItemNames { get; set; } // Comma-separated list
        public string? StockType { get; set; }
        public string? ActionBy { get; set; }
        public DateTime? ActionOn { get; set; }
        public decimal TotalQuantity { get; set; }
        public decimal TotalPurchaseValue { get; set; }
        public decimal TotalSaleValue { get; set; }
    }
}
