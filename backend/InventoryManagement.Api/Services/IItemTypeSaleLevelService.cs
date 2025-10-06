using InventoryManagement.API.Models;

namespace InventoryManagement.API.Services
{
    public interface IItemTypeSaleLevelService
    {
        Task<IEnumerable<ItemTypeSaleLevel>> GetAllAsync();
        Task<ItemTypeSaleLevel?> GetByIdAsync(int id);
        Task<int> CreateAsync(CreateItemTypeSaleLevelRequest request);
        Task<bool> UpdateAsync(int id, UpdateItemTypeSaleLevelRequest request);
        Task<bool> DeleteAsync(int id);
        Task<ItemTypeSaleLevelLookupData> GetLookupDataAsync();
    }
}
