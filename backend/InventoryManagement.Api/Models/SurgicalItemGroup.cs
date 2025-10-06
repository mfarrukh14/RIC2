using System.ComponentModel.DataAnnotations;

namespace InventoryManagement.API.Models
{
    public class SurgicalItemGroup
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public string? Description { get; set; }
        public int BranchId { get; set; }
        public string? BranchName { get; set; }
        public string? SubServiceId { get; set; }
        public bool IsActive { get; set; }
        public string? CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public string? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
        public bool IsDeleted { get; set; }
    }

    public class CreateSurgicalItemGroupRequest
    {
        [Required(ErrorMessage = "Name is required")]
        public string Name { get; set; } = string.Empty;

        public string? Description { get; set; }

        [Required(ErrorMessage = "Service is required")]
        public string SubServiceId { get; set; } = string.Empty;

        public int BranchId { get; set; } = 1; // Default branch

        public string? CreatedById { get; set; }
    }

    public class UpdateSurgicalItemGroupRequest
    {
        [Required(ErrorMessage = "Name is required")]
        public string Name { get; set; } = string.Empty;

        public string? Description { get; set; }

        [Required(ErrorMessage = "Service is required")]
        public string SubServiceId { get; set; } = string.Empty;

        public int BranchId { get; set; } = 1;

        public string? ModifiedById { get; set; }
    }

    public class SurgicalItemGroupLookupData
    {
        public List<LookupItem> Branches { get; set; } = new();
    }
}
