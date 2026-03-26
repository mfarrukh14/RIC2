using System.ComponentModel.DataAnnotations;

namespace InventoryManagement.Api.Models
{
    public class PurchaseOrderTypeDto
    {
        public int PurchaseOrderTypeId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedOn { get; set; }
    }

    public class PurchaseOrderTypeUpsertRequest
    {
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        public string? Description { get; set; }
        public bool IsActive { get; set; } = true;
    }
}