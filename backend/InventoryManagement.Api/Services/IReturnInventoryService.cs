using InventoryManagement.API.Models;

namespace InventoryManagement.API.Services
{
    public interface IReturnInventoryService
    {
        Task<List<ReturnInventory>> GetAllAsync(ReturnInventoryFilterRequest? filter = null);
        Task<ReturnInventory?> GetByIdAsync(int id);
        Task<ReturnInventory> CreateAsync(ReturnInventoryCreateRequest request, int branchId, int createdById);
        Task<bool> UpdateAsync(int id, ReturnInventoryUpdateRequest request, int modifiedById);
        Task<bool> DeleteAsync(int id, int modifiedById);
        Task<ReturnInventoryLookupData> GetLookupDataAsync();
    }
}
