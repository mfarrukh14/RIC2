namespace InventoryManagement.Api.Models
{
    public class AssetAllocation
    {
        public int Id { get; set; }
        public string? Remarks { get; set; }
        public DateTime AllocatedDate { get; set; }
        public DateTime? ReturnDate { get; set; }
        public int? UserId { get; set; }
        public string? UserName { get; set; }
        public string? UserEmail { get; set; }
        public string? UserDepartment { get; set; }
        public int? DepartmentId { get; set; }
        public string? DepartmentName { get; set; }
        public int? SubDepartmentId { get; set; }
        public string? SubDepartmentName { get; set; }
        public int? RoomId { get; set; }
        public string? RoomName { get; set; }
        public string? Building { get; set; }
        public string? Floor { get; set; }
        public int? ItemId { get; set; }
        public int? BranchId { get; set; }
        public string? BranchName { get; set; }
        public bool IsReturn { get; set; }
        public string? ReturnRemarks { get; set; }
        public int Quantity { get; set; }
        public int? InventoryItemId { get; set; }
        public string? InventoryItemName { get; set; }
        public string? SerialNumber { get; set; }
        public string? Model { get; set; }
        public string? ItemStatus { get; set; }
        public decimal? PurchasePrice { get; set; }
        public decimal? CurrentValue { get; set; }
        public string? SysBatchNo { get; set; }
        public string? BatchNo { get; set; }
        public bool IsActive { get; set; }
        public int? CreatedById { get; set; }
        public DateTime? CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
    }

    public class AssetAllocationCreateRequest
    {
        public string? Remarks { get; set; }
        public DateTime AllocatedDate { get; set; }
        public int? UserId { get; set; }
        public int? DepartmentId { get; set; }
        public int? SubDepartmentId { get; set; }
        public int? RoomId { get; set; }
        public int? ItemId { get; set; }
        public int? BranchId { get; set; }
        public int Quantity { get; set; } = 1;
        public int? InventoryItemId { get; set; }
        public string? SysBatchNo { get; set; }
        public string? BatchNo { get; set; }
        public bool IsActive { get; set; } = true;
    }

    public class AssetAllocationUpdateRequest
    {
        public string? Remarks { get; set; }
        public DateTime AllocatedDate { get; set; }
        public DateTime? ReturnDate { get; set; }
        public int? UserId { get; set; }
        public int? DepartmentId { get; set; }
        public int? SubDepartmentId { get; set; }
        public int? RoomId { get; set; }
        public int? ItemId { get; set; }
        public int? BranchId { get; set; }
        public bool IsReturn { get; set; }
        public string? ReturnRemarks { get; set; }
        public int Quantity { get; set; } = 1;
        public int? InventoryItemId { get; set; }
        public string? SysBatchNo { get; set; }
        public string? BatchNo { get; set; }
        public bool IsActive { get; set; } = true;
    }

    public class AssetAllocationReport
    {
        public int Id { get; set; }
        public DateTime AllocatedDate { get; set; }
        public DateTime? ReturnDate { get; set; }
        public int Quantity { get; set; }
        public string? Remarks { get; set; }
        public bool IsReturn { get; set; }
        public string? ReturnRemarks { get; set; }
        
        // Asset Information
        public int? AssetId { get; set; }
        public string? AssetName { get; set; }
        public string? SerialNumber { get; set; }
        public string? Model { get; set; }
        public decimal? UnitPrice { get; set; }
        public decimal? TotalPrice { get; set; }
        
        // User Information
        public int? UserId { get; set; }
        public string? UserName { get; set; }
        public string? UserEmail { get; set; }
        public string? UserDepartment { get; set; }
        public string? UserDesignation { get; set; }
        
        // Room Information
        public int? RoomId { get; set; }
        public string? RoomName { get; set; }
        public string? Building { get; set; }
        public string? Floor { get; set; }
        public string? RoomDescription { get; set; }
        
        // Department Information
        public int? DepartmentId { get; set; }
        public string? DepartmentName { get; set; }
        public int? SubDepartmentId { get; set; }
        public string? SubDepartmentName { get; set; }
        
        // Branch Information
        public int? BranchId { get; set; }
        public string? BranchName { get; set; }
        
        // Additional Details
        public string? BrandName { get; set; }
        public string? ItemTypeName { get; set; }
        public string? ManufacturerName { get; set; }
        public string? AllocationNo { get; set; }
    }

    public class AssetAllocationReportFilter
    {
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public string AllocationType { get; set; } = "Room"; // "Room" or "User"
        public int? RoomId { get; set; }
        public int? UserId { get; set; }
        public int? AssetId { get; set; }
        public string? Building { get; set; }
        public string? Floor { get; set; }
    }
}