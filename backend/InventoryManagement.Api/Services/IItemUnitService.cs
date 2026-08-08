using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IItemUnitService
    {
        Task<IEnumerable<ItemUnit>> GetAllItemUnitsAsync(int branchId);
        Task<ItemUnit?> GetItemUnitByIdAsync(int id);
        Task<int> CreateItemUnitAsync(CreateItemUnitRequest request);
        Task<bool> UpdateItemUnitAsync(UpdateItemUnitRequest request);
        Task<bool> DeleteItemUnitAsync(int id, int modifiedById);
    }
}