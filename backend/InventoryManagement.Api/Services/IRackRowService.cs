using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IRackRowService
    {
        Task<IEnumerable<RackRow>> GetAllRackRowsAsync();
        Task<RackRow?> GetRackRowByIdAsync(int id);
        Task<IEnumerable<RackRow>> GetRackRowsByRackIdAsync(int rackId);
        Task<RackRow> CreateRackRowAsync(RackRowCreateRequest request);
        Task<bool> UpdateRackRowAsync(int id, RackRowUpdateRequest request);
        Task<bool> DeleteRackRowAsync(int id);
    }
}
