using System.ComponentModel.DataAnnotations;

namespace InventoryManagement.API.Models
{
    public class ItemTypeSaleLevel
    {
        public int Id { get; set; }
        public int ItemTypeId { get; set; }
        public string? ItemTypeName { get; set; }
        public int FastRunningLevel { get; set; }
        public int SlowMovingLevel { get; set; }
        public int DeadLevel { get; set; }
        public int BranchId { get; set; }
        public string? BranchName { get; set; }
        public bool IsActive { get; set; }
        public string? CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public string? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
        public bool IsDeleted { get; set; }
    }

    public class CreateItemTypeSaleLevelRequest
    {
        [Required(ErrorMessage = "Item Type is required")]
        public int ItemTypeId { get; set; }

        [Required(ErrorMessage = "Fast Running Level is required")]
        [Range(0, int.MaxValue, ErrorMessage = "Fast Running Level must be a positive number")]
        public int FastRunningLevel { get; set; }

        [Required(ErrorMessage = "Slow Moving Level is required")]
        [Range(0, int.MaxValue, ErrorMessage = "Slow Moving Level must be a positive number")]
        public int SlowMovingLevel { get; set; }

        [Required(ErrorMessage = "Dead Level is required")]
        [Range(0, int.MaxValue, ErrorMessage = "Dead Level must be a positive number")]
        public int DeadLevel { get; set; }

        public int BranchId { get; set; } = 1; // Default branch

        public string? CreatedById { get; set; }
    }

    public class UpdateItemTypeSaleLevelRequest
    {
        [Required(ErrorMessage = "Item Type is required")]
        public int ItemTypeId { get; set; }

        [Required(ErrorMessage = "Fast Running Level is required")]
        [Range(0, int.MaxValue, ErrorMessage = "Fast Running Level must be a positive number")]
        public int FastRunningLevel { get; set; }

        [Required(ErrorMessage = "Slow Moving Level is required")]
        [Range(0, int.MaxValue, ErrorMessage = "Slow Moving Level must be a positive number")]
        public int SlowMovingLevel { get; set; }

        [Required(ErrorMessage = "Dead Level is required")]
        [Range(0, int.MaxValue, ErrorMessage = "Dead Level must be a positive number")]
        public int DeadLevel { get; set; }

        public int BranchId { get; set; } = 1;

        public string? ModifiedById { get; set; }
    }

    public class ItemTypeSaleLevelLookupData
    {
        public List<LookupItem> ItemTypes { get; set; } = new();
        public List<LookupItem> Branches { get; set; } = new();
    }
}
