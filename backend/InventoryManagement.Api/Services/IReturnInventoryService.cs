using InventoryManagement.API.Models;

namespace InventoryManagement.API.Services
{
    public interface IReturnInventoryService
    {
        Task<List<ReturnInventory>> GetAllAsync(ReturnInventoryFilterRequest? filter = null);
        Task<ReturnInventory?> GetByIdAsync(int id);
        Task<ReturnInventory> CreateAsync(ReturnInventoryCreateRequest request);
        Task<bool> UpdateAsync(int id, ReturnInventoryUpdateRequest request);
        Task<bool> DeleteAsync(int id);
        Task<ReturnInventoryLookupData> GetLookupDataAsync();
    }
}
