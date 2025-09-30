namespace InventoryManagement.Api.Models
{
    public class Brand
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int? BranchId { get; set; }
        public bool IsActive { get; set; } = true;
        public int CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }

        // Navigation properties for related data
        public string? BranchName { get; set; }
    }

    public class CreateBrandRequest
    {
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int? BranchId { get; set; }
        public int CreatedById { get; set; }
    }

    public class UpdateBrandRequest
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int? BranchId { get; set; }
        public bool IsActive { get; set; } = true;
        public int ModifiedById { get; set; }
    }
}