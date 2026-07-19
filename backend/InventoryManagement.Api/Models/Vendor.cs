using System.ComponentModel.DataAnnotations;
using InventoryManagement.Api.Validation;

namespace InventoryManagement.Api.Models
{
    public class Vendor
    {
        public int Id { get; set; }

        [Required]
        public string Name { get; set; } = string.Empty;

        public string? Description { get; set; }

        [OptionalEmailAddress]
        public string? Email { get; set; }

        public string? CNo { get; set; } // Contact Number

        public string? Address { get; set; }

        public string? NTN { get; set; } // National Tax Number

        public string? STN { get; set; } // Sales Tax Number

        // Contact Person 1
        public string? CPName1 { get; set; }
        public string? CPEmail1 { get; set; }
        public string? CPContactNumber1 { get; set; }

        // Contact Person 2
        public string? CPName2 { get; set; }
        public string? CPEmail2 { get; set; }
        public string? CPContactNumber2 { get; set; }

        // Foreign Keys
        public int? CountryId { get; set; }
        public string? CountryName { get; set; } // For display

        public int? StateOrProvinceId { get; set; }
        public string? StateOrProvinceName { get; set; } // For display

        public int? CityId { get; set; }
        public string? CityName { get; set; } // For display

        public int? BranchId { get; set; }
        public string? BranchName { get; set; } // For display

        // System fields
        public bool IsActive { get; set; } = true;
        public int? CreatedById { get; set; }
        public DateTime CreatedOn { get; set; } = DateTime.UtcNow;
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }

        // Additional fields from schema
        public string? Code { get; set; }
        public int? VendorOrCustomer { get; set; }
        public int? IncomeTaxStatus { get; set; }
        public int? VendorType { get; set; }

        public int? TaxPayerCategoryId { get; set; }
        public string? TaxPayerCategoryName { get; set; } // For display

        public int? TaxPayerStatus { get; set; }
        public int? SaleTaxType { get; set; }
        public string? ExemptUnderSRO { get; set; }

        public int? AccountPayableId { get; set; }
        public string? AccountPayableName { get; set; } // For display

        public int? AccountReceivableId { get; set; }
        public string? AccountReceivableName { get; set; } // For display

        public int? CreditStatus { get; set; }
        public int? NetDueDays { get; set; }
        public int? CreditLimit { get; set; }
        public string? FaxNo { get; set; }
        public bool IsVerified { get; set; } = false;
    }
}