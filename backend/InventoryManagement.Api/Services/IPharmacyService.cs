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
        Task<PharmacyDailySaleReport> GetDailySaleAsync(int? storeId, DateTime? dateFrom, DateTime? dateTo, string? challanType, int pageNumber, int pageSize);

        // Item Wise Sale
        Task<PharmacyItemWiseSaleReport> GetItemWiseSaleAsync(int? storeId, int? itemId, DateTime? dateFrom, DateTime? dateTo, int pageNumber, int pageSize);

        // Pharmacy Queue
        Task<IReadOnlyList<PharmacyQueueEntry>> GetQueueAsync(int storeId);

        // Pharmacy Online Order
        Task<PagedResult<PharmacyOnlineOrderEntry>> GetOnlineOrdersAsync(DateTime? dateFrom, DateTime? dateTo, int? storeId, string? status, int pageNumber, int pageSize);

        // Pharmacy Dashboard
        Task<PharmacyDashboardSummary> GetDashboardSummaryAsync(int branchId, int? storeId, DateTime? dateFrom, DateTime? dateTo);

        // Immunization
        Task<IReadOnlyList<PharmacyLookupItem>> GetVaccinesAsync();
        Task<PagedResult<PharmacyVaccineRecord>> GetVaccineRecordsAsync(DateTime? dateFrom, DateTime? dateTo, int? patientId, int pageNumber, int pageSize);
        Task<PharmacyVaccineRecord> CreateVaccineRecordAsync(PharmacyVaccineCreateRequest request, int actingUserId);
    }
}
