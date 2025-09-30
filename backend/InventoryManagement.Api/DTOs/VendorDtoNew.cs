using System.ComponentModel.DataAnnotations;

namespace InventoryManagement.Api.DTOs
{
    public class VendorDtoNew
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? Email { get; set; }
        public string? CNo { get; set; }
        public string? Address { get; set; }
        public string? NTN { get; set; }
        public string? STN { get; set; }

        // Contact Person 1
        public string? CPName1 { get; set; }
        public string? CPEmail1 { get; set; }
        public string? CPContactNumber1 { get; set; }

        // Contact Person 2
        public string? CPName2 { get; set; }
        public string? CPEmail2 { get; set; }
        public string? CPContactNumber2 { get; set; }

        // Foreign Keys with Names
        public int? CountryId { get; set; }
        public string? CountryName { get; set; }
        public int? StateOrProvinceId { get; set; }
        public string? StateOrProvinceName { get; set; }
        public int? CityId { get; set; }
        public string? CityName { get; set; }
        public int? BranchId { get; set; }
        public string? BranchName { get; set; }

        // Additional fields
        public string? Code { get; set; }
        public int? VendorOrCustomer { get; set; }
        public int? IncomeTaxStatus { get; set; }
        public int? VendorType { get; set; }
        public int? TaxPayerCategoryId { get; set; }
        public string? TaxPayerCategoryName { get; set; }
        public int? TaxPayerStatus { get; set; }
        public int? SaleTaxType { get; set; }
        public string? ExemptUnderSRO { get; set; }
        public int? AccountPayableId { get; set; }
        public string? AccountPayableName { get; set; }
        public int? AccountReceivableId { get; set; }
        public string? AccountReceivableName { get; set; }
        public int? CreditStatus { get; set; }
        public int? NetDueDays { get; set; }
        public int? CreditLimit { get; set; }
        public string? FaxNo { get; set; }
        public bool IsVerified { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedOn { get; set; }
        public DateTime? ModifiedOn { get; set; }
    }

    public class CreateVendorDtoNew
    {
        [Required]
        public string Name { get; set; } = string.Empty;

        public string? Description { get; set; }

        [EmailAddress]
        public string? Email { get; set; }

        public string? CNo { get; set; }
        public string? Address { get; set; }
        public string? NTN { get; set; }
        public string? STN { get; set; }

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
        public int? StateOrProvinceId { get; set; }
        public int? CityId { get; set; }
        public int? BranchId { get; set; }

        // Additional fields
        public string? Code { get; set; }
        public int? VendorOrCustomer { get; set; }
        public int? IncomeTaxStatus { get; set; }
        public int? VendorType { get; set; }
        public int? TaxPayerCategoryId { get; set; }
        public int? TaxPayerStatus { get; set; }
        public int? SaleTaxType { get; set; }
        public string? ExemptUnderSRO { get; set; }
        public int? AccountPayableId { get; set; }
        public int? AccountReceivableId { get; set; }
        public int? CreditStatus { get; set; }
        public int? NetDueDays { get; set; }
        public int? CreditLimit { get; set; }
        public string? FaxNo { get; set; }
        public bool IsVerified { get; set; } = false;
        public bool IsActive { get; set; } = true;
    }

    public class UpdateVendorDtoNew
    {
        [Required]
        public string Name { get; set; } = string.Empty;

        public string? Description { get; set; }

        [EmailAddress]
        public string? Email { get; set; }

        public string? CNo { get; set; }
        public string? Address { get; set; }
        public string? NTN { get; set; }
        public string? STN { get; set; }

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
        public int? StateOrProvinceId { get; set; }
        public int? CityId { get; set; }
        public int? BranchId { get; set; }

        // Additional fields
        public string? Code { get; set; }
        public int? VendorOrCustomer { get; set; }
        public int? IncomeTaxStatus { get; set; }
        public int? VendorType { get; set; }
        public int? TaxPayerCategoryId { get; set; }
        public int? TaxPayerStatus { get; set; }
        public int? SaleTaxType { get; set; }
        public string? ExemptUnderSRO { get; set; }
        public int? AccountPayableId { get; set; }
        public int? AccountReceivableId { get; set; }
        public int? CreditStatus { get; set; }
        public int? NetDueDays { get; set; }
        public int? CreditLimit { get; set; }
        public string? FaxNo { get; set; }
        public bool IsVerified { get; set; }
        public bool IsActive { get; set; }
    }
}