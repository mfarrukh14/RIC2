using InventoryManagement.API.Models;

namespace InventoryManagement.API.Services
{
    public interface IReturnInventoryService
    {
        Task<InventoryManagement.Api.Models.PagedResult<ReturnInventory>> GetAllAsync(ReturnInventoryFilterRequest? filter, bool isAdmin, IReadOnlyCollection<int> allowedStoreIds);
        Task<ReturnInventory?> GetByIdAsync(int id);
        Task<ReturnInventory> CreateAsync(ReturnInventoryCreateRequest request, int branchId, int createdById);
        Task<ReturnInventoryBatchResult> CreateBatchAsync(ReturnInventoryBatchCreateRequest request, int branchId, int createdById);
        Task<bool> UpdateAsync(int id, ReturnInventoryUpdateRequest request, int modifiedById);
        Task<bool> DeleteAsync(int id, int modifiedById);
        Task<ReturnInventoryLookupData> GetLookupDataAsync();
    }
}
