namespace InventoryManagement.Api.Models
{
    public class RackRow
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int StoreId { get; set; }
        public int RackId { get; set; }
        public int? BranchId { get; set; }
        public bool IsActive { get; set; } = true;
        public int? CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }

        // Navigation properties
        public string? StoreName { get; set; }
        public string? RackName { get; set; }
    }

    public class RackRowCreateRequest
    {
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int StoreId { get; set; }
        public int RackId { get; set; }
        public int? BranchId { get; set; }
        public bool IsActive { get; set; } = true;
        public int? CreatedById { get; set; }
    }

    public class RackRowUpdateRequest
    {
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int StoreId { get; set; }
        public int RackId { get; set; }
        public int? BranchId { get; set; }
        public bool IsActive { get; set; }
        public int? ModifiedById { get; set; }
    }
}
