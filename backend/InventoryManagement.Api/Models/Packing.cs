namespace InventoryManagement.Api.Models
{
    public class Packing
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int? Pack { get; set; }
        public int? Leaf { get; set; }
        public int? NumberOfItems { get; set; }
        public int? BranchId { get; set; }
        public bool IsActive { get; set; } = true;
        public int CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }

        // Navigation properties for related data
        public string? BranchName { get; set; }
    }

    public class CreatePackingRequest
    {
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int? Pack { get; set; }
        public int? Leaf { get; set; }
        public int? NumberOfItems { get; set; }
        public int? BranchId { get; set; }
        public int CreatedById { get; set; }
    }

    public class UpdatePackingRequest
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int? Pack { get; set; }
        public int? Leaf { get; set; }
        public int? NumberOfItems { get; set; }
        public int? BranchId { get; set; }
        public bool IsActive { get; set; } = true;
        public int ModifiedById { get; set; }
    }
}