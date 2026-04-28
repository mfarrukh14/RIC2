using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface ISpaceAllocationService
    {
        Task<IEnumerable<SpaceAllocation>> GetAllSpaceAllocationsAsync();
        Task<SpaceAllocation?> GetSpaceAllocationByIdAsync(int id);
        Task<SpaceAllocation> CreateSpaceAllocationAsync(SpaceAllocationCreateRequest request);
        Task<bool> UpdateSpaceAllocationAsync(int id, SpaceAllocationUpdateRequest request);
        Task<bool> DeleteSpaceAllocationAsync(int id);
    }
}
