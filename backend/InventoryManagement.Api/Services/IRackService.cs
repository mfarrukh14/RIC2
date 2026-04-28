using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IRackService
    {
        Task<IEnumerable<Rack>> GetAllRacksAsync();
        Task<Rack?> GetRackByIdAsync(int id);
        Task<int> CreateRackAsync(RackRequest request, int userId);
        Task<bool> UpdateRackAsync(RackRequest request, int userId);
        Task<bool> DeleteRackAsync(int id, int userId);
    }
}
