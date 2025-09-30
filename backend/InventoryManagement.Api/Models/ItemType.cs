namespace InventoryManagement.Api.Models
{
    public class ItemType
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int? Value { get; set; }
        public int? BranchId { get; set; }
        public bool IsActive { get; set; } = true;
        public int CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }

        // Navigation properties for related data
        public string? BranchName { get; set; }
    }

    public class CreateItemTypeRequest
    {
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int? Value { get; set; }
        public int? BranchId { get; set; }
        public int CreatedById { get; set; }
    }

    public class UpdateItemTypeRequest
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int? Value { get; set; }
        public int? BranchId { get; set; }
        public bool IsActive { get; set; } = true;
        public int ModifiedById { get; set; }
    }
}