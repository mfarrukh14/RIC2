using System.ComponentModel.DataAnnotations;

namespace InventoryManagement.Api.Models
{
    public class Vendor
    {
        public int Id { get; set; }

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

        // Contact Information
        [StringLength(100)]
        public string? ContactPersonName1 { get; set; }

        [StringLength(50)]
        public string? ContactPersonType1 { get; set; }

        [StringLength(100)]
        [EmailAddress]
        public string? Email1 { get; set; }

        [StringLength(20)]
        public string? Phone1 { get; set; }

        [StringLength(100)]
        public string? ContactPersonName2 { get; set; }

        [StringLength(50)]
        public string? ContactPersonType2 { get; set; }

        [StringLength(100)]
        [EmailAddress]
        public string? Email2 { get; set; }

        [StringLength(20)]
        public string? Phone2 { get; set; }

        // Account Details
        [StringLength(50)]
        public string? VendorAccountNumber { get; set; }

        [StringLength(50)]
        public string? TaxIdNumber { get; set; }

        // Bank Details
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

        // Additional Fields
        [StringLength(20)]
        public string? CreditLimit { get; set; }

        [StringLength(50)]
        public string? PaymentTerms { get; set; }

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }
    }
}