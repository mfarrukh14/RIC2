using System.ComponentModel.DataAnnotations;

namespace InventoryManagement.Api.DTOs
{
    public class ManufacturerDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Email { get; set; }
        public string? Ntn { get; set; }
        public string? Stn { get; set; }
        public string? Country { get; set; }
        public string? StateProvince { get; set; }
        public string? City { get; set; }
        public string? Address { get; set; }
        public string? ContactNo { get; set; }
        public string? Description { get; set; }
        public string? ContactPersonName1 { get; set; }
        public string? ContactPersonEmail1 { get; set; }
        public string? ContactPersonPhone1 { get; set; }
        public string? ContactPersonName2 { get; set; }
        public string? ContactPersonEmail2 { get; set; }
        public string? ContactPersonPhone2 { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }

    public class CreateManufacturerDto
    {
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
    }

    public class UpdateManufacturerDto
    {
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

        public bool IsActive { get; set; }
    }
}