namespace InventoryManagement.Api.Models
{
    public class PurchaseRequisitionLookupItem
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
    }

    public class PurchaseRequisitionFilter
    {
        // "Pending", "Processed", or "Closed" - matches Inv.PurchaseRequisitionStatus.Category.
        public string? StatusCategory { get; set; }
        public int? BranchId { get; set; }
        public string? Search { get; set; }
    }

    public class PurchaseRequisitionListItem
    {
        public int Id { get; set; }
        public string PRNumber { get; set; } = string.Empty;
        public string? DepartmentName { get; set; }
        public string? VendorName { get; set; }
        public int Priority { get; set; }
        public string PriorityName { get; set; } = string.Empty;
        public decimal TotalEstimatedCost { get; set; }
        public DateTime? DateRequiredBy { get; set; }
        public bool IsTechnicalReviewed { get; set; }
        public string? AssignedToName { get; set; }
        public DateTime ModifiedOn { get; set; }
        public string StatusName { get; set; } = string.Empty;
        public string StatusCategory { get; set; } = string.Empty;
    }

    public class PurchaseRequisitionItemModel
    {
        public int Id { get; set; }
        public int? ItemId { get; set; }
        public int? MedicineId { get; set; }
        public int? SubServiceId { get; set; }
        public string? ItemName { get; set; }
        public int Quantity { get; set; }
        public decimal UnitEstimatedCost { get; set; }
        public decimal TotalEstimatedCost { get; set; }
        public int? BudgetHeadId { get; set; }
        public string? BudgetHeadName { get; set; }
        public decimal? AvailableBudget { get; set; }
        public string? BudgetRestriction { get; set; }
        public string? Remarks { get; set; }
    }

    public class PurchaseRequisitionDetails
    {
        public int Id { get; set; }
        public string PRNumber { get; set; } = string.Empty;
        public int? DemandRequestId { get; set; }
        public string? DemandNo { get; set; }
        public int BranchId { get; set; }
        public int? StoreId { get; set; }
        public string? StoreName { get; set; }
        public int? DepartmentId { get; set; }
        public string? DepartmentName { get; set; }
        public int? FinancialYearId { get; set; }
        public string? FinancialYearName { get; set; }
        public string? DistributionPlan { get; set; }
        public int Priority { get; set; }
        public DateTime? DateRequiredBy { get; set; }
        public int PRType { get; set; }
        public int? VendorId { get; set; }
        public string? VendorName { get; set; }
        public string? SuggestedProcurementMethod { get; set; }
        public string? Subject { get; set; }
        public string? ScopeOfWork { get; set; }
        public string? Instructions { get; set; }
        public string? Remarks { get; set; }
        public string? GoodsDeliveredContactPerson { get; set; }
        public string? GoodsDeliveredCellNumber { get; set; }
        public string? GoodsDeliveredEmail { get; set; }
        public string? GoodsDeliveredTelephone { get; set; }
        public string? GoodsDeliveredFaxNo { get; set; }
        public string? GoodsDeliveryAddress { get; set; }
        public string? TermsAndConditions { get; set; }
        public bool IsTechnicalReviewed { get; set; }
        public string? TechnicalReviewRemarks { get; set; }
        public decimal TotalEstimatedCost { get; set; }
        public int PurchaseRequisitionStatusId { get; set; }
        public string StatusName { get; set; } = string.Empty;
        public string StatusCategory { get; set; } = string.Empty;
        public int? AssignedToId { get; set; }
        public string? AssignedToName { get; set; }
        public DateTime CreatedOn { get; set; }
        public DateTime? ModifiedOn { get; set; }
        public List<PurchaseRequisitionItemModel> Items { get; set; } = new();
    }

    public class PurchaseRequisitionItemRequest
    {
        public int? ItemId { get; set; }
        public int? MedicineId { get; set; }
        public int? SubServiceId { get; set; }
        public int Quantity { get; set; }
        public decimal UnitEstimatedCost { get; set; }
        public int? BudgetHeadId { get; set; }
        public decimal? AvailableBudget { get; set; }
        public string? BudgetRestriction { get; set; }
        public string? Remarks { get; set; }
    }

    public class PurchaseRequisitionCreateRequest
    {
        public int? DemandRequestId { get; set; }
        public string? DemandNo { get; set; }
        public int BranchId { get; set; }
        public int? StoreId { get; set; }
        public int? DepartmentId { get; set; }
        public int? FinancialYearId { get; set; }
        public string? DistributionPlan { get; set; }
        public int Priority { get; set; } = 1;
        public DateTime? DateRequiredBy { get; set; }
        public int PRType { get; set; } = 1;
        public int? VendorId { get; set; }
        public string? SuggestedProcurementMethod { get; set; }
        public string? Subject { get; set; }
        public string? ScopeOfWork { get; set; }
        public string? Instructions { get; set; }
        public string? Remarks { get; set; }
        public string? GoodsDeliveredContactPerson { get; set; }
        public string? GoodsDeliveredCellNumber { get; set; }
        public string? GoodsDeliveredEmail { get; set; }
        public string? GoodsDeliveredTelephone { get; set; }
        public string? GoodsDeliveredFaxNo { get; set; }
        public string? GoodsDeliveryAddress { get; set; }
        public string? TermsAndConditions { get; set; }
        public int? ForwardToUserId { get; set; }
        public string? ForwardRemarks { get; set; }
        public List<PurchaseRequisitionItemRequest> Items { get; set; } = new();
    }

    public class PurchaseRequisitionForwardRequest
    {
        public int ToUserId { get; set; }
        public string? Remarks { get; set; }
    }

    public class PurchaseRequisitionStatusChangeRequest
    {
        public string Status { get; set; } = string.Empty; // "Approved", "Rejected", "Closed", etc.
        public string? Remarks { get; set; }
    }

    public class PurchaseRequisitionLifeCycleEntry
    {
        public int Id { get; set; }
        public string Status { get; set; } = string.Empty;
        public string? ActionBy { get; set; }
        public string? Remarks { get; set; }
        public DateTime CreatedOn { get; set; }
    }
}
