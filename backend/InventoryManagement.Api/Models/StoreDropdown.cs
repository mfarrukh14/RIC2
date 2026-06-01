namespace InventoryManagement.Api.Models
{
    public class PharmacyStoreDropdownRequest
    {
        public int? Id { get; set; }
        public int? BranchId { get; set; }
        public int? DepartmentId { get; set; }
        public int? BranchDepartmentId { get; set; }
        public int? PharmacyStoreId { get; set; }
        public DateTime? ModifiedOn { get; set; }
        public int? GenderType { get; set; }
        public int? MinAge { get; set; }
        public int? MaxAge { get; set; }
        public int? PatientType { get; set; }
        public int? StockType { get; set; }
    }

    public class PharmacyStoreDropdownResponse
    {
        public string Status { get; set; } = "Ok";
        public int StatusCode { get; set; } = 200;
        public string Message { get; set; } = "Pharmacy store dropdown fetched successfully.";
        public List<DropdownItem> Data { get; set; } = new();
    }

    public class DropdownItem
    {
        public int Value { get; set; }
        public string Text { get; set; } = string.Empty;
    }

    public class StoreLocationLookupResponse
    {
        public List<StoreBuildingOption> Buildings { get; set; } = new();
        public List<StoreFloorOption> Floors { get; set; } = new();
        public List<StoreRoomOption> Rooms { get; set; } = new();
    }

    public class StoreBuildingOption
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
    }

    public class StoreFloorOption
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public int BuildingId { get; set; }
    }

    public class StoreRoomOption
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public int BuildingId { get; set; }
        public int FloorId { get; set; }
    }
}
