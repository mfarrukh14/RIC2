using System.ComponentModel.DataAnnotations;

namespace InventoryManagement.Api.Models
{
    public class Branch
    {
        public int Id { get; set; }

        [Required]
        public string Name { get; set; } = string.Empty;

        public string? Description { get; set; }
        public string? Address { get; set; }
        public string? ContactNumber { get; set; }
        public string? Email { get; set; }

        // System fields
        public bool IsActive { get; set; } = true;
        public int? CreatedById { get; set; }
        public DateTime CreatedOn { get; set; } = DateTime.UtcNow;
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
    }
}
