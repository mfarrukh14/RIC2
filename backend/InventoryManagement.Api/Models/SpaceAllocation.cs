namespace InventoryManagement.Api.Models
{
    public class SpaceAllocation
    {
        public int Id { get; set; }
        public int StoreId { get; set; }
        public int ItemId { get; set; }
        public int? FeeId { get; set; }
        public int RackId { get; set; }
        public int? RackRowId { get; set; }
        public int? RackColumnId { get; set; }
        public int? RackDrawerId { get; set; }
        public int? MedicineId { get; set; }
        public bool IsActive { get; set; } = true;
        public int? CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }

        // Navigation properties
        public string? StoreName { get; set; }
        public string? ItemName { get; set; }
        public string? RackName { get; set; }
        public string? RowName { get; set; }
        public string? ColumnName { get; set; }
        public string? DrawerName { get; set; }
    }

    public class SpaceAllocationCreateRequest
    {
        public int StoreId { get; set; }
        public int ItemId { get; set; }
        public int? FeeId { get; set; }
        public int RackId { get; set; }
        public int? RackRowId { get; set; }
        public int? RackColumnId { get; set; }
        public int? RackDrawerId { get; set; }
        public int? MedicineId { get; set; }
        public bool IsActive { get; set; } = true;
        public int? CreatedById { get; set; }
    }

    public class SpaceAllocationUpdateRequest
    {
        public int StoreId { get; set; }
        public int ItemId { get; set; }
        public int? FeeId { get; set; }
        public int RackId { get; set; }
        public int? RackRowId { get; set; }
        public int? RackColumnId { get; set; }
        public int? RackDrawerId { get; set; }
        public int? MedicineId { get; set; }
        public bool IsActive { get; set; }
        public int? ModifiedById { get; set; }
    }
}
