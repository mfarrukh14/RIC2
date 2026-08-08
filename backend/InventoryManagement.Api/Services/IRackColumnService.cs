using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IRackColumnService
    {
        Task<IEnumerable<RackColumn>> GetAllRackColumnsAsync(int branchId);
        Task<RackColumn?> GetRackColumnByIdAsync(int id);
        Task<IEnumerable<RackColumn>> GetRackColumnsByRackIdAsync(int rackId);
        Task<int> CreateRackColumnAsync(RackColumnCreateRequest request);
        Task<bool> UpdateRackColumnAsync(RackColumnUpdateRequest request);
        Task<bool> DeleteRackColumnAsync(int id);
    }
}
