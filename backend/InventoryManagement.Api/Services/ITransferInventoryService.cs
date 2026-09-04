using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface ITransferInventoryService
    {
        Task<PagedResult<TransferInventory>> GetAllAsync(TransferInventoryFilterRequest? filter, bool isAdmin, IReadOnlyCollection<int> allowedStoreIds);
        Task<TransferInventory?> GetByIdAsync(int id);
        Task<TransferInventory> CreateAsync(TransferInventoryCreateRequest request, int userId);
        Task<bool> UpdateAsync(int id, TransferInventoryUpdateRequest request, int userId);
        Task<bool> DeleteAsync(int id, int userId);
        Task<TransferInventoryLookupData> GetLookupDataAsync();
        Task<int> GetAvailableQuantityAsync(int storeId, int itemId);
    }
}
