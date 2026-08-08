using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IInventoryService
    {
        // Inventory header operations
        Task<PagedResult<Inventory>> GetAllAsync(InventoryFilterRequest? filter = null);
        Task<Inventory?> GetByIdAsync(int id);
        Task<int> CreateAsync(InventoryCreateRequest request);
        Task<bool> UpdateAsync(int id, InventoryUpdateRequest request);
        Task<bool> DeleteAsync(int id);
        
        // Inventory detail operations
        Task<int> CreateDetailAsync(InventoryDetailCreateRequest request);
        Task<bool> UpdateDetailAsync(int id, InventoryDetailUpdateRequest request);
        Task<bool> DeleteDetailAsync(int id);
        
        // Lookup data
        Task<InventoryLookupData> GetLookupDataAsync();
    }
}
