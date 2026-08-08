using InventoryManagement.API.Models;

namespace InventoryManagement.API.Services
{
    public interface ISurgicalItemGroupService
    {
        Task<IEnumerable<SurgicalItemGroup>> GetAllAsync(int branchId);
        Task<SurgicalItemGroup?> GetByIdAsync(int id);
        Task<int> CreateAsync(CreateSurgicalItemGroupRequest request);
        Task<bool> UpdateAsync(int id, UpdateSurgicalItemGroupRequest request);
        Task<bool> DeleteAsync(int id);
        Task<SurgicalItemGroupLookupData> GetLookupDataAsync();
    }
}
