namespace InventoryManagement.Api.Models
{
    public class StoreAllocationToUser
    {
        public int Id { get; set; }
        public int StoreId { get; set; }
        public string? StoreName { get; set; }
        public int? UserId { get; set; }
        public string EmployeeName { get; set; } = string.Empty;
        public bool IsActive { get; set; } = true;
        public bool IsDeleted { get; set; }
        public int? CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
    }

    public class StoreAllocationToUserCreateRequest
    {
        public int StoreId { get; set; }
        public int UserId { get; set; }
        public bool IsActive { get; set; } = true;
    }

    public class StoreAllocationToUserUpdateRequest
    {
        public int Id { get; set; }
        public int StoreId { get; set; }
        public int UserId { get; set; }
        public bool IsActive { get; set; }
    }
}
