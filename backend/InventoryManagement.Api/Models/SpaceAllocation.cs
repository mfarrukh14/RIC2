namespace InventoryManagement.Api.Models
{
    public class SpaceAllocation
    {
        public Guid Id { get; set; }
        public int StoreId { get; set; }
        public Guid ItemId { get; set; }
        public Guid? FeeId { get; set; }
        public int RackId { get; set; }
        public Guid? RackRowId { get; set; }
        public Guid? RackColumnId { get; set; }
        public Guid? RackDrawerId { get; set; }
        public Guid? MedicineId { get; set; }
        public bool IsActive { get; set; } = true;
        public Guid? CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public Guid? ModifiedById { get; set; }
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
        public Guid ItemId { get; set; }
        public Guid? FeeId { get; set; }
        public int RackId { get; set; }
        public Guid? RackRowId { get; set; }
        public Guid? RackColumnId { get; set; }
        public Guid? RackDrawerId { get; set; }
        public Guid? MedicineId { get; set; }
        public bool IsActive { get; set; } = true;
        public Guid? CreatedById { get; set; }
    }

    public class SpaceAllocationUpdateRequest
    {
        public int StoreId { get; set; }
        public Guid ItemId { get; set; }
        public Guid? FeeId { get; set; }
        public int RackId { get; set; }
        public Guid? RackRowId { get; set; }
        public Guid? RackColumnId { get; set; }
        public Guid? RackDrawerId { get; set; }
        public Guid? MedicineId { get; set; }
        public bool IsActive { get; set; }
        public Guid? ModifiedById { get; set; }
    }
}
