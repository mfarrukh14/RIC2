using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IAssetAllocationService
    {
        Task<IEnumerable<AssetAllocation>> GetAllAsync();
        Task<AssetAllocation?> GetByIdAsync(int id);
        Task<int> CreateAsync(AssetAllocationCreateRequest request);
        Task<bool> UpdateAsync(int id, AssetAllocationUpdateRequest request);
        Task<bool> DeleteAsync(int id);
        
        // Lookup data methods
        Task<IEnumerable<User>> GetUsersAsync();
        Task<IEnumerable<Room>> GetRoomsAsync();
        Task<IEnumerable<Department>> GetDepartmentsAsync();
        Task<IEnumerable<SubDepartment>> GetSubDepartmentsAsync();
        Task<IEnumerable<InventoryItem>> GetAvailableInventoryItemsAsync();
    }
}