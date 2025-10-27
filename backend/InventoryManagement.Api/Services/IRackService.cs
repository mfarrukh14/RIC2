using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IRackService
    {
        Task<IEnumerable<Rack>> GetAllRacksAsync();
        Task<Rack?> GetRackByIdAsync(int id);
        Task<int> CreateRackAsync(RackRequest request, Guid userId);
        Task<bool> UpdateRackAsync(RackRequest request, Guid userId);
        Task<bool> DeleteRackAsync(int id, Guid userId);
    }
}
