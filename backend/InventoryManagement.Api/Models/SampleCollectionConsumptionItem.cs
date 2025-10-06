using System.ComponentModel.DataAnnotations;

namespace InventoryManagement.API.Models
{
    public class SampleCollectionConsumptionItem
    {
        public int Id { get; set; }
        public int ItemId { get; set; }
        public string? ItemName { get; set; }
        public int? MedicineId { get; set; }
        public int? FeeId { get; set; }
        public int DepartmentId { get; set; }
        public string? DepartmentName { get; set; }
        public int BranchId { get; set; }
        public string? BranchName { get; set; }
        public int Quantity { get; set; }
        public string? CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public string? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
        public bool IsDeleted { get; set; }
        public bool IsActive { get; set; }
    }

    public class CreateSampleCollectionConsumptionItemRequest
    {
        [Required(ErrorMessage = "Item is required")]
        public int ItemId { get; set; }

        public int? MedicineId { get; set; }

        public int? FeeId { get; set; }

        [Required(ErrorMessage = "Department is required")]
        public int DepartmentId { get; set; }

        [Required(ErrorMessage = "Branch is required")]
        public int BranchId { get; set; }

        [Required(ErrorMessage = "Quantity is required")]
        [Range(1, int.MaxValue, ErrorMessage = "Quantity must be greater than 0")]
        public int Quantity { get; set; }

        public string? CreatedById { get; set; }
    }

    public class UpdateSampleCollectionConsumptionItemRequest
    {
        [Required(ErrorMessage = "Item is required")]
        public int ItemId { get; set; }

        public int? MedicineId { get; set; }

        public int? FeeId { get; set; }

        [Required(ErrorMessage = "Department is required")]
        public int DepartmentId { get; set; }

        [Required(ErrorMessage = "Branch is required")]
        public int BranchId { get; set; }

        [Required(ErrorMessage = "Quantity is required")]
        [Range(1, int.MaxValue, ErrorMessage = "Quantity must be greater than 0")]
        public int Quantity { get; set; }

        public string? ModifiedById { get; set; }
    }

    public class SampleCollectionConsumptionItemLookupData
    {
        public List<LookupItem> Departments { get; set; } = new();
        public List<LookupItem> Items { get; set; } = new();
        public List<LookupItem> Branches { get; set; } = new();
    }
}
