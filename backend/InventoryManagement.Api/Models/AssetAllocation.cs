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
}