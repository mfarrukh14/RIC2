namespace InventoryManagement.Api.Models
{
    public class PharmacyPatientSearchResult
    {
        public int PatientId { get; set; }
        public string MRNo { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string? MaskedContact { get; set; }
    }

    // Backed by Inv.Items/Inv.Stocks - the same general item catalog and stock ledger
    // used everywhere else in this app (Add Items, Demand Requests, GRN, etc.), not the
    // separate legacy Pharmacy.BranchMedicines/PharmacyMedicinesStocks domain (that one
    // still backs prescription-linked dispensing - see PharmacyPendingPrescriptionItem).
    public class PharmacyItemSearchResult
    {
        public int ItemId { get; set; }
        public string ItemName { get; set; } = string.Empty;
        public decimal UnitPrice { get; set; }
        public decimal StoreStockQty { get; set; }
    }

    public class PharmacyPendingPrescriptionItem
    {
        public int PatientPharmacyDetailId { get; set; }
        public int? PatientsMedicineId { get; set; }
        public int PatientPharmacyId { get; set; }
        public int? MedicineId { get; set; }
        public int? BranchMedicineId { get; set; }
        public string MedicineName { get; set; } = string.Empty;
        public int PrescribedQuantity { get; set; }
        public string? Frequency { get; set; }
        public decimal CurrentStock { get; set; }
    }

    public class PharmacyDispenseItemRequest
    {
        // Exactly one of ItemId (ad-hoc, Inv.Items/Inv.Stocks) or BranchMedicineId
        // (prescription-linked, Pharmacy.BranchMedicines/PharmacyMedicinesStocks) must be set.
        public int? ItemId { get; set; }
        public int? BranchMedicineId { get; set; }
        public int? PatientPharmacyDetailId { get; set; }
        public int? PatientsMedicineId { get; set; }
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
    }

    public class PharmacyProvisionalDispenseRequest
    {
        public int? PatientId { get; set; }
        public string? VisitNo { get; set; }
        public int StoreId { get; set; }
        public int? PrescribedInId { get; set; }
        public int? PrescribedById { get; set; }
        public List<PharmacyDispenseItemRequest> Items { get; set; } = new();
    }

    public class PharmacyFinalizeDispenseRequest
    {
        // 1 = flat amount, 2 = percentage - matches the legacy DiscountType convention.
        public int? DiscountType { get; set; }
        public decimal DiscountAmount { get; set; }
        public decimal PaidAmount { get; set; }
        public int? PaymentTypeId { get; set; }
    }

    public class PharmacyChallanItem
    {
        public int Id { get; set; }
        public int? BranchMedicineId { get; set; }
        public string MedicineName { get; set; } = string.Empty;
        public int Quantity { get; set; }
        public decimal Total { get; set; }
    }

    public class PharmacyChallanDetails
    {
        public int Id { get; set; }
        public string? ChallanNo { get; set; }
        public string ChallanType { get; set; } = string.Empty;
        public bool IsFinalized { get; set; }
        public int? PatientId { get; set; }
        public string? PatientName { get; set; }
        public string? VisitNo { get; set; }
        public int? StoreId { get; set; }
        public string? StoreName { get; set; }
        public DateTime Timestamp { get; set; }
        public decimal Amount { get; set; }
        public decimal Discount { get; set; }
        public int? DiscountType { get; set; }
        public decimal Total { get; set; }
        public decimal PaidAmount { get; set; }
        public decimal Remaining { get; set; }
        public decimal Change { get; set; }
        public int? PaymentTypeId { get; set; }
        public string? PaymentTypeName { get; set; }
        public List<PharmacyChallanItem> Items { get; set; } = new();
    }

    public class PharmacyLookups
    {
        public IReadOnlyList<PharmacyLookupItem> Stores { get; set; } = new List<PharmacyLookupItem>();
        public IReadOnlyList<PharmacyLookupItem> PaymentTypes { get; set; } = new List<PharmacyLookupItem>();
        public IReadOnlyList<PharmacyLookupItem> PrescribedIns { get; set; } = new List<PharmacyLookupItem>();
    }

    public class PharmacyLookupItem
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
    }

    public class PharmacyDoctorSearchResult
    {
        public int DoctorId { get; set; }
        public string Name { get; set; } = string.Empty;
    }

    // ---- Pharmacy Department Store (Department -> Pharmacy Store routing) ----

    public class PharmacyDepartmentStoreMapping
    {
        public int Id { get; set; }
        public int BranchDepartmentId { get; set; }
        public string DepartmentName { get; set; } = string.Empty;
        public int PharmacyStoreId { get; set; }
        public string StoreName { get; set; } = string.Empty;
        public DateTime? ModifiedOn { get; set; }
    }

    public class PharmacyDepartmentStoreMappingRequest
    {
        public int BranchDepartmentId { get; set; }
        public int PharmacyStoreId { get; set; }
    }

    // ---- Refund Medicine ----

    public class PharmacyRefundLineItem
    {
        public int ChallanFormDetailId { get; set; }
        public string MedicineName { get; set; } = string.Empty;
        public decimal Rate { get; set; }
        public int IssuedQuantity { get; set; }
        public int AlreadyRefundedQuantity { get; set; }
        public int RefundableQuantity { get; set; }
    }

    public class PharmacyRefundItemRequest
    {
        public int ChallanFormDetailId { get; set; }
        public int RefundQuantity { get; set; }
    }

    public class PharmacyRefundRequest
    {
        public int StoreId { get; set; }
        public string ChallanNo { get; set; } = string.Empty;
        public List<PharmacyRefundItemRequest> Items { get; set; } = new();
    }

    // ---- Daily Sale ----

    public class PharmacyDailySaleEntry
    {
        public int Id { get; set; }
        public string? MRNo { get; set; }
        public string? PatientName { get; set; }
        public string? VisitNo { get; set; }
        public string? ChallanNo { get; set; }
        public string ChallanType { get; set; } = string.Empty;
        public string? StoreName { get; set; }
        public DateTime Timestamp { get; set; }
        public decimal Discount { get; set; }
        public decimal Total { get; set; }
        public decimal PaidAmount { get; set; }
        public decimal Remaining { get; set; }
    }

    // ---- Item Wise Sale ----

    public class PharmacyItemWiseSaleEntry
    {
        public string? PatientName { get; set; }
        public string? MRNo { get; set; }
        public string? VisitNo { get; set; }
        public string? ChallanNo { get; set; }
        public DateTime Timestamp { get; set; }
        public string? StoreName { get; set; }
        public string ItemName { get; set; } = string.Empty;
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
        public decimal Total { get; set; }
    }

    // ---- Pharmacy Queue ----

    public class PharmacyQueueEntry
    {
        public int PatientPharmacyId { get; set; }
        public int? PatientId { get; set; }
        public string? PatientName { get; set; }
        public string? MRNo { get; set; }
        public string? VisitNo { get; set; }
        public string? PrescribedByName { get; set; }
        public string? PrescribedInName { get; set; }
        public DateTime Timestamp { get; set; }
    }

    // ---- Pharmacy Online Order ----

    public class PharmacyOnlineOrderEntry
    {
        public int PatientPharmacyId { get; set; }
        public string? OrderNumber { get; set; }
        public string? PatientName { get; set; }
        public string? CNIC { get; set; }
        public string? MRNo { get; set; }
        public string? ActionByName { get; set; }
        public string? StoreName { get; set; }
        public DateTime Timestamp { get; set; }
        public string? Status { get; set; }
    }

    // ---- Pharmacy Dashboard ----

    public class PharmacyDashboardItemStat
    {
        public string Name { get; set; } = string.Empty;
        public decimal Quantity { get; set; }
    }

    public class PharmacyDashboardExpiryStat
    {
        public string Name { get; set; } = string.Empty;
        public DateTime ExpiryDate { get; set; }
        public decimal Quantity { get; set; }
    }

    public class PharmacyDashboardSummary
    {
        public int DailyPrescriptionsDispensed { get; set; }
        public List<PharmacyDashboardItemStat> TopDispensedItems { get; set; } = new();
        public List<PharmacyDashboardItemStat> TopItemsInStock { get; set; } = new();
        public List<PharmacyDashboardExpiryStat> ExpiringSoon { get; set; } = new();
    }

    // ---- Immunization ----

    public class PharmacyVaccineRecord
    {
        public int PatientVaccineId { get; set; }
        public int PatientId { get; set; }
        public string? PatientName { get; set; }
        public string? MRNo { get; set; }
        public int VaccineId { get; set; }
        public string? VaccineName { get; set; }
        public DateTime? VaccinationDate { get; set; }
        public string? Remarks { get; set; }
    }

    public class PharmacyVaccineCreateRequest
    {
        public int PatientId { get; set; }
        public int VaccineId { get; set; }
        public DateTime? VaccinationDate { get; set; }
        public string? Remarks { get; set; }
    }
}
