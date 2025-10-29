namespace InventoryManagement.Api.Models
{
    public class RackDrawer
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int StoreId { get; set; }
        public int RackId { get; set; }
        public Guid? RackRowId { get; set; }
        public Guid? RackColumnId { get; set; }
        public Guid? BranchId { get; set; }
        public bool IsActive { get; set; }
        public Guid? CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public Guid? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
        
        // Navigation properties for display
        public string? StoreName { get; set; }
        public string? RackName { get; set; }
        public string? RowName { get; set; }
        public string? ColumnName { get; set; }
    }

    public class RackDrawerCreateRequest
    {
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int StoreId { get; set; }
        public int RackId { get; set; }
        public Guid? RackRowId { get; set; }
        public Guid? RackColumnId { get; set; }
        public Guid? BranchId { get; set; }
        public bool IsActive { get; set; } = true;
    }

    public class RackDrawerUpdateRequest
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int StoreId { get; set; }
        public int RackId { get; set; }
        public Guid? RackRowId { get; set; }
        public Guid? RackColumnId { get; set; }
        public Guid? BranchId { get; set; }
        public bool IsActive { get; set; }
    }
}
