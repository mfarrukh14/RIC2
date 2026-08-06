using System.ComponentModel.DataAnnotations;
using InventoryManagement.Api.Validation;

namespace InventoryManagement.Api.DTOs
{
    public class VendorDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Code { get; set; }
        public string? Type { get; set; }
        public string? Description { get; set; }
        public string? Address { get; set; }
        public string? City { get; set; }
        public string? State { get; set; }
        public string? PostalCode { get; set; }
        public string? Country { get; set; }
        public string? Email { get; set; }
        public string? Phone { get; set; }
        public string? ContactPersonName1 { get; set; }
        public string? ContactPersonType1 { get; set; }
        public string? Email1 { get; set; }
        public string? Phone1 { get; set; }
        public string? ContactPersonName2 { get; set; }
        public string? ContactPersonType2 { get; set; }
        public string? Email2 { get; set; }
        public string? Phone2 { get; set; }
        public string? VendorAccountNumber { get; set; }
        public string? TaxIdNumber { get; set; }
        public string? BankName { get; set; }
        public string? AccountNumber { get; set; }
        public string? RoutingNumber { get; set; }
        public string? SwiftCode { get; set; }
        public string? IbanNumber { get; set; }
        public string? CreditLimit { get; set; }
        public string? PaymentTerms { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }

    public class CreateVendorDto
    {
        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [StringLength(20)]
        public string? Code { get; set; }

        [StringLength(50)]
        public string? Type { get; set; }

        [StringLength(500)]
        public string? Description { get; set; }

        [StringLength(200)]
        public string? Address { get; set; }

        [StringLength(50)]
        public string? City { get; set; }

        [StringLength(50)]
        public string? State { get; set; }

        [StringLength(20)]
        public string? PostalCode { get; set; }

        [StringLength(50)]
        public string? Country { get; set; }

        [StringLength(100)]
        public string? ContactPersonName1 { get; set; }

        [StringLength(50)]
        public string? ContactPersonType1 { get; set; }

        [StringLength(100)]
        [OptionalEmailAddress]
        public string? Email1 { get; set; }

        [StringLength(20)]
        public string? Phone1 { get; set; }

        [StringLength(100)]
        public string? ContactPersonName2 { get; set; }

        [StringLength(50)]
        public string? ContactPersonType2 { get; set; }

        [StringLength(100)]
        [OptionalEmailAddress]
        public string? Email2 { get; set; }

        [StringLength(20)]
        public string? Phone2 { get; set; }

        [StringLength(50)]
        public string? VendorAccountNumber { get; set; }

        [StringLength(50)]
        public string? TaxIdNumber { get; set; }

        [StringLength(100)]
        public string? BankName { get; set; }

        [StringLength(50)]
        public string? AccountNumber { get; set; }

        [StringLength(20)]
        public string? RoutingNumber { get; set; }

        [StringLength(20)]
        public string? SwiftCode { get; set; }

        [StringLength(50)]
        public string? IbanNumber { get; set; }

        [StringLength(20)]
        public string? CreditLimit { get; set; }

        [StringLength(50)]
        public string? PaymentTerms { get; set; }

        public bool IsActive { get; set; } = true;
    }

    public class UpdateVendorDto
    {
        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [StringLength(20)]
        public string? Code { get; set; }

        [StringLength(50)]
        public string? Type { get; set; }

        [StringLength(500)]
        public string? Description { get; set; }

        [StringLength(200)]
        public string? Address { get; set; }

        [StringLength(50)]
        public string? City { get; set; }

        [StringLength(50)]
        public string? State { get; set; }

        [StringLength(20)]
        public string? PostalCode { get; set; }

        [StringLength(50)]
        public string? Country { get; set; }

        [StringLength(100)]
        public string? ContactPersonName1 { get; set; }

        [StringLength(50)]
        public string? ContactPersonType1 { get; set; }

        [StringLength(100)]
        [OptionalEmailAddress]
        public string? Email1 { get; set; }

        [StringLength(20)]
        public string? Phone1 { get; set; }

        [StringLength(100)]
        public string? ContactPersonName2 { get; set; }

        [StringLength(50)]
        public string? ContactPersonType2 { get; set; }

        [StringLength(100)]
        [OptionalEmailAddress]
        public string? Email2 { get; set; }

        [StringLength(20)]
        public string? Phone2 { get; set; }

        [StringLength(50)]
        public string? VendorAccountNumber { get; set; }

        [StringLength(50)]
        public string? TaxIdNumber { get; set; }

        [StringLength(100)]
        public string? BankName { get; set; }

        [StringLength(50)]
        public string? AccountNumber { get; set; }

        [StringLength(20)]
        public string? RoutingNumber { get; set; }

        [StringLength(20)]
        public string? SwiftCode { get; set; }

        [StringLength(50)]
        public string? IbanNumber { get; set; }

        [StringLength(20)]
        public string? CreditLimit { get; set; }

        [StringLength(50)]
        public string? PaymentTerms { get; set; }

        public bool IsActive { get; set; }
    }
}