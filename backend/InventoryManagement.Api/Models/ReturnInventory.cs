using System.ComponentModel.DataAnnotations;
using InventoryManagement.Api.Models;

namespace InventoryManagement.API.Models
{
    public class ReturnInventory
    {
        public int Id { get; set; }
        public string? InventoryNo { get; set; }
        public string? PurchaseOrderNo { get; set; }
        public int? BranchId { get; set; }
        public string? BranchName { get; set; }
        public int? StoreId { get; set; }
        public string? StoreName { get; set; }
        public int? ItemTypeId { get; set; }
        public string? ItemTypeName { get; set; }
        public int? ItemId { get; set; }
        public string? ItemName { get; set; }
        public int ReturnQuantity { get; set; }
        public int? StockTypeId { get; set; }
        public string? StockTypeName { get; set; }
        public int? VendorId { get; set; }
        public string? VendorName { get; set; }
        public DateTime ReturnDate { get; set; }
        public string? Reason { get; set; }
        public string? Notes { get; set; }
        public bool IsActive { get; set; }
        public int? CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
    }

    public class ReturnInventoryCreateRequest
    {
        // Optional: when set, this return is applied against a specific
        // Purchase Order / GRN invoice, and that document's remaining
        // quantity for the returned item is decremented too (in addition to
        // the store's stock).
        public string? PurchaseOrderNo { get; set; }
        public string? InventoryNo { get; set; }

        // Set server-side from the caller's session, not trusted from the client.
        public int? BranchId { get; set; }

        [Required(ErrorMessage = "Store is required")]
        public int? StoreId { get; set; }

        [Required(ErrorMessage = "Item Type is required")]
        public int? ItemTypeId { get; set; }

        [Required(ErrorMessage = "Item is required")]
        public int ItemId { get; set; }

        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "Return quantity must be at least 1")]
        public int ReturnQuantity { get; set; }

        public int? VendorId { get; set; }
        public DateTime? ReturnDate { get; set; }
        public string? Reason { get; set; }
        public string? Notes { get; set; }
    }

    public class ReturnInventoryUpdateRequest
    {
        public string? PurchaseOrderNo { get; set; }

        [Required]
        public int StoreId { get; set; }

        public int? ItemTypeId { get; set; }
        public int? VendorId { get; set; }

        [Required]
        public DateTime ReturnDate { get; set; }

        public string? Reason { get; set; }
        public string? Notes { get; set; }
    }

    public class ReturnInventoryFilterRequest : PagedRequest
    {
        public int? BranchId { get; set; }
        public int? StoreId { get; set; }
        public int? ItemTypeId { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public string? PurchaseOrderNo { get; set; }
        public int? ItemId { get; set; }
        public string? InventoryNo { get; set; }
    }

    public class ReturnInventoryLookupData
    {
        public List<LookupItem> Branches { get; set; } = new();
        public List<LookupItem> Stores { get; set; } = new();
        public List<LookupItem> ItemTypes { get; set; } = new();
        public List<LookupItem> Vendors { get; set; } = new();
    }

    // Backs the "Return Inventory" modal launched from an Add Inventory row -
    // processes every checked GRN/Inventory line as one return (one
    // Inv.ReturnInventory header + one Inv.ReturnInventoryItems row per line),
    // unlike ReturnInventoryCreateRequest above which is strictly single-line.
    public class ReturnInventoryBatchLineRequest
    {
        [Required]
        public int InventoryDetailId { get; set; }

        public int? ItemId { get; set; }
        public int? MedicineId { get; set; }
        public int? SubServiceId { get; set; }

        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "Return quantity must be at least 1")]
        public int ReturnQuantity { get; set; }
    }

    public class ReturnInventoryBatchCreateRequest
    {
        [Required(ErrorMessage = "Inventory is required")]
        public int InventoryId { get; set; }

        [Required(ErrorMessage = "Store is required")]
        public int StoreId { get; set; }

        public int? VendorId { get; set; }
        public DateTime? ReturnDate { get; set; }
        public decimal? AdjustmentAmount { get; set; }
        public string? AdjustmentRemarks { get; set; }

        [Required]
        [MinLength(1, ErrorMessage = "At least one line must be selected")]
        public List<ReturnInventoryBatchLineRequest> Lines { get; set; } = new();
    }

    // A batch return covers multiple ReturnInventoryItems rows under one
    // ReturnInventory header, so it can't be represented by the single-item
    // ReturnInventory model above (which assumes exactly one line per return).
    public class ReturnInventoryBatchResult
    {
        public int Id { get; set; }
        public string ReturnNumber { get; set; } = string.Empty;
        public decimal TotalAmount { get; set; }
        public decimal? AdjustmentAmount { get; set; }
        public decimal ReturnAmount { get; set; }
    }
}
