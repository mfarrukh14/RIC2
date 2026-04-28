using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IRackDrawerService
    {
        Task<IEnumerable<RackDrawer>> GetAllAsync();
        Task<RackDrawer?> GetByIdAsync(int id);
        Task<RackDrawer> CreateAsync(RackDrawerCreateRequest request);
        Task<RackDrawer?> UpdateAsync(RackDrawerUpdateRequest request);
        Task<bool> DeleteAsync(int id);
    }
}
