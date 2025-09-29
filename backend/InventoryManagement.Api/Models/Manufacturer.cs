using System.ComponentModel.DataAnnotations;

namespace InventoryManagement.Api.Models
{
    public class Manufacturer
    {
        public int Id { get; set; }

        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [StringLength(100)]
        [EmailAddress]
        public string? Email { get; set; }

        [StringLength(50)]
        public string? Ntn { get; set; }

        [StringLength(20)]
        public string? Stn { get; set; }

        [StringLength(50)]
        public string? Country { get; set; }

        [StringLength(50)]
        public string? StateProvince { get; set; }

        [StringLength(50)]
        public string? City { get; set; }

        [StringLength(200)]
        public string? Address { get; set; }

        [StringLength(20)]
        public string? ContactNo { get; set; }

        [StringLength(500)]
        public string? Description { get; set; }

        // Contact Person Info
        [StringLength(100)]
        public string? ContactPersonName1 { get; set; }

        [StringLength(100)]
        [EmailAddress]
        public string? ContactPersonEmail1 { get; set; }

        [StringLength(20)]
        public string? ContactPersonPhone1 { get; set; }

        [StringLength(100)]
        public string? ContactPersonName2 { get; set; }

        [StringLength(100)]
        [EmailAddress]
        public string? ContactPersonEmail2 { get; set; }

        [StringLength(20)]
        public string? ContactPersonPhone2 { get; set; }

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }
    }
}