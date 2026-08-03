using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IPharmacyService
    {
        Task<IReadOnlyList<PharmacyPatientSearchResult>> SearchPatientsAsync(string query);
        Task<IReadOnlyList<PharmacyItemSearchResult>> GetActiveItemsAsync(int branchId, int storeId);
        Task<IReadOnlyList<PharmacyDoctorSearchResult>> GetActiveDoctorsAsync();
        Task<IReadOnlyList<PharmacyPendingPrescriptionItem>> GetPendingPrescriptionsAsync(int patientId, int storeId);
        Task<PharmacyChallanDetails> CreateOrAppendProvisionalAsync(PharmacyProvisionalDispenseRequest request, int branchId, int actingUserId);
        Task<PharmacyChallanDetails> FinalizeDispenseAsync(int provisionalChallanId, PharmacyFinalizeDispenseRequest request, int actingUserId);
        Task<PharmacyChallanDetails?> GetChallanByIdAsync(int id);
        Task<PharmacyLookups> GetLookupsAsync(int branchId);

        // Pharmacy Department Store
        Task<IReadOnlyList<PharmacyDepartmentStoreMapping>> GetDepartmentStoreMappingsAsync();
        Task<IReadOnlyList<PharmacyLookupItem>> GetBranchDepartmentsAsync(int branchId);
        Task<PharmacyDepartmentStoreMapping> CreateDepartmentStoreMappingAsync(PharmacyDepartmentStoreMappingRequest request);
        Task<PharmacyDepartmentStoreMapping?> UpdateDepartmentStoreMappingAsync(int id, PharmacyDepartmentStoreMappingRequest request);
        Task<bool> DeleteDepartmentStoreMappingAsync(int id);

        // Refund Medicine
        Task<IReadOnlyList<PharmacyRefundLineItem>> GetRefundableLinesAsync(int storeId, string challanNo);
        Task<PharmacyChallanDetails> ProcessRefundAsync(PharmacyRefundRequest request, int actingUserId);

        // Daily Sale
        Task<IReadOnlyList<PharmacyDailySaleEntry>> GetDailySaleAsync(int? storeId, DateTime? dateFrom, DateTime? dateTo, string? challanType);

        // Item Wise Sale
        Task<IReadOnlyList<PharmacyItemWiseSaleEntry>> GetItemWiseSaleAsync(int? storeId, int? itemId, DateTime? dateFrom, DateTime? dateTo);

        // Pharmacy Queue
        Task<IReadOnlyList<PharmacyQueueEntry>> GetQueueAsync(int storeId);

        // Pharmacy Online Order
        Task<IReadOnlyList<PharmacyOnlineOrderEntry>> GetOnlineOrdersAsync(DateTime? dateFrom, DateTime? dateTo, int? storeId, string? status);

        // Pharmacy Dashboard
        Task<PharmacyDashboardSummary> GetDashboardSummaryAsync(int branchId, int? storeId, DateTime? dateFrom, DateTime? dateTo);

        // Immunization
        Task<IReadOnlyList<PharmacyLookupItem>> GetVaccinesAsync();
        Task<IReadOnlyList<PharmacyVaccineRecord>> GetVaccineRecordsAsync(DateTime? dateFrom, DateTime? dateTo, int? patientId);
        Task<PharmacyVaccineRecord> CreateVaccineRecordAsync(PharmacyVaccineCreateRequest request, int actingUserId);
    }
}
