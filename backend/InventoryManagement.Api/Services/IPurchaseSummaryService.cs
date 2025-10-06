using InventoryManagement.API.Models;

namespace InventoryManagement.API.Services
{
    public interface IPurchaseSummaryService
    {
        Task<PurchaseSummaryResponse> GetAllAsync(PurchaseSummaryFilterRequest? filter = null);
        Task<PurchaseSummary?> GetByIdAsync(int id);
        Task<PurchaseSummary> CreateAsync(PurchaseSummaryCreateRequest request);
        Task<bool> UpdateAsync(int id, PurchaseSummaryUpdateRequest request);
        Task<bool> DeleteAsync(int id);
        Task<PurchaseSummaryLookupData> GetLookupDataAsync();
    }
}
