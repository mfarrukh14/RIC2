using System.ComponentModel.DataAnnotations;

namespace InventoryManagement.Api.Models
{
    public class DemandRequestFilter
    {
        public DateTime? DateFrom { get; set; }
        public DateTime? DateTo { get; set; }
        public int? BranchId { get; set; }
        public int? RequestingStoreId { get; set; }
        public int? RequestedStoreId { get; set; }
        public int? StockTypeId { get; set; }
        public string? Search { get; set; }
    }

    public class DemandRequestSummary
    {
        public int DemandRequestId { get; set; }
        public string DRNo { get; set; } = string.Empty;
        public string? IndentNo { get; set; }
        public DateTime DateFrom { get; set; }
        public DateTime DateTo { get; set; }
        public int BranchId { get; set; }
        public string RequestingBranchName { get; set; } = string.Empty;
        public int? RequestingStoreId { get; set; }
        public string? RequestingStoreName { get; set; }
        public int RequestedStoreId { get; set; }
        public string RequestedStoreName { get; set; } = string.Empty;
        public int? StockTypeId { get; set; }
        public string? StockTypeName { get; set; }
        public int ItemsCount { get; set; }
        public int TotalRequestedQuantity { get; set; }
        public string? ItemSummary { get; set; }
        public string Status { get; set; } = string.Empty;
        public string? Remarks { get; set; }
        public DateTime CreatedOn { get; set; }
        public string? RequestedByName { get; set; }
        public DateTime? ApprovedDate { get; set; }
        public DateTime? IssuedDate { get; set; }
        public string? DriverName { get; set; }
        public string? VehicleNumber { get; set; }
        public string? ContactNumber { get; set; }
        public string? Detail { get; set; }
    }

    public class DemandRequestDetails : DemandRequestSummary
    {
        public List<DemandRequestItem> Items { get; set; } = new();
    }

    public class DemandRequestLifeCycleEntry
    {
        public int Id { get; set; }
        public int DemandRequestId { get; set; }
        public int DemandRequestStatusId { get; set; }
        public string Status { get; set; } = string.Empty;
        public int? UserId { get; set; }
        public string ActionBy { get; set; } = string.Empty;
        public DateTime CreatedOn { get; set; }
    }

    public class DemandRequestItem
    {
        public int Id { get; set; }
        public int DemandRequestId { get; set; }
        public int? ItemId { get; set; }
        public string? ItemName { get; set; }
        public int RequestedQuantity { get; set; }
        public int? ApprovedQuantity { get; set; }
        public int BranchId { get; set; }
        public string? BranchName { get; set; }
        public int? MedicineId { get; set; }
        public int? SubServiceId { get; set; }
        public bool IsActive { get; set; }
        public int? CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
        public string? Remarks { get; set; }
        public int? StockTypeId { get; set; }
        public string? StockTypeName { get; set; }
        public int? IssuedQuantity { get; set; }
        public int? IssuingQuantity { get; set; }
        public int? RemainingQuantity { get; set; }
        public int AvailableQuantityInRequestingStore { get; set; }
        public int AvailableQuantityInRequestedStore { get; set; }
    }

    public class DemandRequestCreateRequest
    {
        public string? DRNo { get; set; }
        public string? IndentNo { get; set; }

        [Required]
        public DateTime DateFrom { get; set; }

        [Required]
        public DateTime DateTo { get; set; }

        [Required]
        public int BranchId { get; set; }

        [Required]
        public int RequestedStoreId { get; set; }

        public int? RequestingStoreId { get; set; }

        public int? StockTypeId { get; set; }
        public string? Status { get; set; }
        public string? Remarks { get; set; }

        [MinLength(1, ErrorMessage = "At least one demand item is required.")]
        public List<DemandRequestCreateItem> Items { get; set; } = new();
    }

    public class DemandRequestCreateItem
    {
        public int? ItemId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Requested quantity must be at least 1.")]
        public int RequestedQuantity { get; set; }

        public int? ApprovedQuantity { get; set; }
        public int? BranchId { get; set; }
        public int? MedicineId { get; set; }
        public int? SubServiceId { get; set; }
        public string? Remarks { get; set; }
        public int? StockTypeId { get; set; }
        public int? IssuedQuantity { get; set; }
        public int? IssuingQuantity { get; set; }
        public int? RemainingQuantity { get; set; }
    }

    public class DemandRequestReceiveRequest
    {
        public string? IndentNo { get; set; }
        public string? DriverName { get; set; }
        public string? VehicleNumber { get; set; }
        public string? ContactNumber { get; set; }
        public string? Detail { get; set; }
    }

    public class DemandRequestItemLogEntry
    {
        public int Id { get; set; }
        public int DemandRequestId { get; set; }
        public int DemandRequestItemId { get; set; }
        public int? ItemId { get; set; }
        public string? ItemName { get; set; }
        public string ActionType { get; set; } = string.Empty;
        public int Quantity { get; set; }
        public int? IssuedQuantity { get; set; }
        public int? ReceivedQuantity { get; set; }
        public int? RemainingQuantity { get; set; }
        public string? ActionBy { get; set; }
        public DateTime CreatedOn { get; set; }
    }

    public class DemandRequestDispatchItem
    {
        public int Id { get; set; }
        public int IssuingQuantity { get; set; }
    }

    public class DemandRequestDispatchRequest
    {
        public string? DriverName { get; set; }
        public string? VehicleNumber { get; set; }
        public string? ContactNumber { get; set; }
        public string? Detail { get; set; }
        public List<DemandRequestDispatchItem> Items { get; set; } = new();
    }

    public class DemandRequestUpdateItem
    {
        // Null/0 means this is a new item line being added to the demand.
        public int? Id { get; set; }
        public int? ItemId { get; set; }
        public int? MedicineId { get; set; }
        public int? SubServiceId { get; set; }
        public int RequestedQuantity { get; set; }
        public int ApprovedQuantity { get; set; }
        public string? Remarks { get; set; }
    }

    public class DemandRequestUpdateRequest
    {
        public string? IndentNo { get; set; }
        public string? DemandNotes { get; set; }
        public List<DemandRequestUpdateItem> Items { get; set; } = new();
    }

    public class DemandRequestRejectRequest
    {
        public string? Remarks { get; set; }
    }
}