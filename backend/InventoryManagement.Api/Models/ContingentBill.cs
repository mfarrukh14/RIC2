using System.ComponentModel.DataAnnotations;

namespace InventoryManagement.API.Models
{
    public class ContingentBill
    {
        public int Id { get; set; }
        public int FinancialYearId { get; set; }
        public string? FinancialYearName { get; set; }
        public int PurchaseOrderTypeId { get; set; }
        public string? PurchaseOrderTypeName { get; set; }
        public DateTime PurchaseOrderDate { get; set; }
        public int VendorId { get; set; }
        public string? VendorName { get; set; }
        public string? BudgetSetupId { get; set; }
        public string? BillNo { get; set; }
        public DateTime BillDate { get; set; }
        public float? BudgetAllotment { get; set; }
        public float? BillAmount { get; set; }
        public float? TotalPreviousBill { get; set; }
        public float? TotalUptoDate { get; set; }
        public float? AvailableBalance { get; set; }
        public float? GrandTotal { get; set; }
        public float? TaxAmount { get; set; }
        public float? NetPayment { get; set; }
        public string? AmountInWords { get; set; }
        public string? Stamp1 { get; set; }
        public string? Stamp2 { get; set; }
        public string? Stamp3 { get; set; }
        public string? Stamp4 { get; set; }
        public string? Stamp5 { get; set; }
        public string? Stamp6 { get; set; }
        public string? TermsAndConditions { get; set; }
        public float? PreAuditedAmount { get; set; }
        public string? PreAuditedAmountInWords { get; set; }
        public string? TokenNo { get; set; }
        public DateTime? AuditDate { get; set; }
        public bool? DisplayStampFormatForAuditSection { get; set; }
        public bool IsClosed { get; set; }
        public string? Remarks { get; set; }
        public string? RegisterPageNo { get; set; }
        public string? SRNO { get; set; }
        public int BranchId { get; set; }
        public string? BranchName { get; set; }
        public int? ContingentBillStatusId { get; set; }
        public int? AssignedToId { get; set; }
        public int? AssignedFromId { get; set; }
        public int? ApprovedById { get; set; }
        public string? CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public string? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
        public bool IsDeleted { get; set; }
        public bool IsActive { get; set; }
    }

    public class CreateContingentBillRequest
    {
        [Required(ErrorMessage = "Financial Year is required")]
        public int FinancialYearId { get; set; }

        [Required(ErrorMessage = "PO Type is required")]
        public int PurchaseOrderTypeId { get; set; }

        [Required(ErrorMessage = "PO Date is required")]
        public DateTime PurchaseOrderDate { get; set; }

        [Required(ErrorMessage = "Vendor is required")]
        public int VendorId { get; set; }

        public string? BudgetSetupId { get; set; }

        public string? BillNo { get; set; }

        [Required(ErrorMessage = "Bill Date is required")]
        public DateTime BillDate { get; set; }

        public float? BudgetAllotment { get; set; }
        public float? BillAmount { get; set; }
        public float? TotalPreviousBill { get; set; }
        public float? TotalUptoDate { get; set; }
        public float? AvailableBalance { get; set; }
        public float? GrandTotal { get; set; }
        public float? TaxAmount { get; set; }
        public float? NetPayment { get; set; }
        public string? AmountInWords { get; set; }
        public string? Stamp1 { get; set; }
        public string? Stamp2 { get; set; }
        public string? Stamp3 { get; set; }
        public string? Stamp4 { get; set; }
        public string? Stamp5 { get; set; }
        public string? Stamp6 { get; set; }
        public string? TermsAndConditions { get; set; }
        public float? PreAuditedAmount { get; set; }
        public string? PreAuditedAmountInWords { get; set; }
        public string? TokenNo { get; set; }
        public DateTime? AuditDate { get; set; }
        public bool? DisplayStampFormatForAuditSection { get; set; }
        public bool IsClosed { get; set; }
        public string? Remarks { get; set; }
        public string? RegisterPageNo { get; set; }
        public string? SRNO { get; set; }
        public int BranchId { get; set; } = 1;
        public int? ContingentBillStatusId { get; set; }
        public int? AssignedToId { get; set; }
        public int? AssignedFromId { get; set; }
        public int? ApprovedById { get; set; }
        public string? CreatedById { get; set; }
    }

    public class UpdateContingentBillRequest
    {
        [Required(ErrorMessage = "Financial Year is required")]
        public int FinancialYearId { get; set; }

        [Required(ErrorMessage = "PO Type is required")]
        public int PurchaseOrderTypeId { get; set; }

        [Required(ErrorMessage = "PO Date is required")]
        public DateTime PurchaseOrderDate { get; set; }

        [Required(ErrorMessage = "Vendor is required")]
        public int VendorId { get; set; }

        public string? BudgetSetupId { get; set; }
        public string? BillNo { get; set; }

        [Required(ErrorMessage = "Bill Date is required")]
        public DateTime BillDate { get; set; }

        public float? BudgetAllotment { get; set; }
        public float? BillAmount { get; set; }
        public float? TotalPreviousBill { get; set; }
        public float? TotalUptoDate { get; set; }
        public float? AvailableBalance { get; set; }
        public float? GrandTotal { get; set; }
        public float? TaxAmount { get; set; }
        public float? NetPayment { get; set; }
        public string? AmountInWords { get; set; }
        public string? Stamp1 { get; set; }
        public string? Stamp2 { get; set; }
        public string? Stamp3 { get; set; }
        public string? Stamp4 { get; set; }
        public string? Stamp5 { get; set; }
        public string? Stamp6 { get; set; }
        public string? TermsAndConditions { get; set; }
        public float? PreAuditedAmount { get; set; }
        public string? PreAuditedAmountInWords { get; set; }
        public string? TokenNo { get; set; }
        public DateTime? AuditDate { get; set; }
        public bool? DisplayStampFormatForAuditSection { get; set; }
        public bool IsClosed { get; set; }
        public string? Remarks { get; set; }
        public string? RegisterPageNo { get; set; }
        public string? SRNO { get; set; }
        public int? ContingentBillStatusId { get; set; }
        public int? AssignedToId { get; set; }
        public int? AssignedFromId { get; set; }
        public int? ApprovedById { get; set; }
        public string? ModifiedById { get; set; }
    }

    public class ContingentBillFilterRequest
    {
        public string? BudgetSetupId { get; set; }
        public int? VendorId { get; set; }
        public int? FinancialYearId { get; set; }
        public int? PurchaseOrderTypeId { get; set; }
        public int? ContingentBillStatusId { get; set; }
        public DateTime? DateStart { get; set; }
        public DateTime? DateEnd { get; set; }
    }

    public class ContingentBillLookupData
    {
        public List<LookupItem> FinancialYears { get; set; } = new();
        public List<LookupItem> PurchaseOrderTypes { get; set; } = new();
        public List<LookupItem> Vendors { get; set; } = new();
        public List<LookupItem> Branches { get; set; } = new();
    }
}
