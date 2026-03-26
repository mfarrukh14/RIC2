namespace InventoryManagement.Api.Models
{
    public class Manufacturer
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? Email { get; set; }
        public string? Address { get; set; }
        public string? CNo { get; set; }
        public string? NTN { get; set; }
        public string? STN { get; set; }
        public string? CPName1 { get; set; }
        public string? CPEmail1 { get; set; }
        public string? CPContactNumber1 { get; set; }
        public string? CPName2 { get; set; }
        public string? CPEmail2 { get; set; }
        public string? CPContactNumber2 { get; set; }
        public int? CountryId { get; set; }
        public int? StateOrProvinceId { get; set; }
        public int? CityId { get; set; }
        public int? BranchId { get; set; }
        public string? RegisteredOwner { get; set; }
        public bool IsActive { get; set; } = true;
        public int? CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }

        // Navigation properties for related data
        public string? CountryName { get; set; }
        public string? StateOrProvinceName { get; set; }
        public string? CityName { get; set; }
        public string? BranchName { get; set; }
    }

    public class CreateManufacturerRequest
    {
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? Email { get; set; }
        public string? Address { get; set; }
        public string? CNo { get; set; }
        public string? NTN { get; set; }
        public string? STN { get; set; }
        public string? CPName1 { get; set; }
        public string? CPEmail1 { get; set; }
        public string? CPContactNumber1 { get; set; }
        public string? CPName2 { get; set; }
        public string? CPEmail2 { get; set; }
        public string? CPContactNumber2 { get; set; }
        public int? CountryId { get; set; }
        public int? StateOrProvinceId { get; set; }
        public int? CityId { get; set; }
        public int? BranchId { get; set; }
        public string? RegisteredOwner { get; set; }
        public int CreatedById { get; set; }
    }

    public class UpdateManufacturerRequest
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? Email { get; set; }
        public string? Address { get; set; }
        public string? CNo { get; set; }
        public string? NTN { get; set; }
        public string? STN { get; set; }
        public string? CPName1 { get; set; }
        public string? CPEmail1 { get; set; }
        public string? CPContactNumber1 { get; set; }
        public string? CPName2 { get; set; }
        public string? CPEmail2 { get; set; }
        public string? CPContactNumber2 { get; set; }
        public int? CountryId { get; set; }
        public int? StateOrProvinceId { get; set; }
        public int? CityId { get; set; }
        public int? BranchId { get; set; }
        public string? RegisteredOwner { get; set; }
        public bool IsActive { get; set; } = true;
        public int ModifiedById { get; set; }
    }
}