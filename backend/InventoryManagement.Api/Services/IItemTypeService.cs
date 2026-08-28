using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IItemTypeService
    {
        Task<IEnumerable<ItemType>> GetAllItemTypesAsync(int branchId);
        Task<ItemType?> GetItemTypeByIdAsync(int id);
        Task<int> CreateItemTypeAsync(CreateItemTypeRequest request);
        Task<bool> UpdateItemTypeAsync(UpdateItemTypeRequest request);
        Task<bool> DeleteItemTypeAsync(int id, int modifiedById);
    }
}