namespace InventoryManagement.Api.Models
{
    public class User
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Email { get; set; }
        public string? UserName { get; set; }
        public string? Department { get; set; }
        public string? Designation { get; set; }
        public bool IsActive { get; set; }
    }

    public class Room
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? Floor { get; set; }
        public string? Building { get; set; }
        public int? Capacity { get; set; }
        public bool IsActive { get; set; }
    }

    public class Department
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? Head { get; set; }
        public bool IsActive { get; set; }
    }

    public class SubDepartment
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int? DepartmentId { get; set; }
        public string? DepartmentName { get; set; }
        public bool IsActive { get; set; }
    }

    public class InventoryItem
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? SerialNumber { get; set; }
        public string? Model { get; set; }
        public int? BrandId { get; set; }
        public string? BrandName { get; set; }
        public int? ItemTypeId { get; set; }
        public string? ItemTypeName { get; set; }
        public int? ItemUnitId { get; set; }
        public string? ItemUnitName { get; set; }
        public int? ManufacturerId { get; set; }
        public string? ManufacturerName { get; set; }
        public DateTime? PurchaseDate { get; set; }
        public decimal? PurchasePrice { get; set; }
        public decimal? CurrentValue { get; set; }
        public string? Condition { get; set; }
        public string? Status { get; set; }
        public int? BranchId { get; set; }
        public string? BranchName { get; set; }
        public bool IsActive { get; set; }
    }
}