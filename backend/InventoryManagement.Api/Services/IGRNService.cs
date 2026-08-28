using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IGRNService
    {
        Task<PagedResult<GRN>> GetAllAsync(int pageNumber, int pageSize, string? search);
        Task<GRN?> GetByIdAsync(int id);
        Task<POForGRN?> GetPODetailsAsync(int purchaseOrderId);
        Task<GRN> CreateAsync(GRNCreateRequest request);
        Task<bool> UpdateAsync(int id, GRNUpdateRequest request);
        Task<bool> DeleteAsync(int id);
        Task<GRNLookupData> GetLookupDataAsync();
    }
}
