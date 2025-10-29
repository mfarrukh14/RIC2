using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IRackColumnService
    {
        Task<IEnumerable<RackColumn>> GetAllRackColumnsAsync();
        Task<RackColumn?> GetRackColumnByIdAsync(Guid id);
        Task<IEnumerable<RackColumn>> GetRackColumnsByRackIdAsync(int rackId);
        Task<Guid> CreateRackColumnAsync(RackColumnCreateRequest request, Guid userId);
        Task<bool> UpdateRackColumnAsync(RackColumnUpdateRequest request, Guid userId);
        Task<bool> DeleteRackColumnAsync(Guid id);
    }
}
