using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface ISpaceAllocationService
    {
        Task<IEnumerable<SpaceAllocation>> GetAllSpaceAllocationsAsync();
        Task<SpaceAllocation?> GetSpaceAllocationByIdAsync(Guid id);
        Task<SpaceAllocation> CreateSpaceAllocationAsync(SpaceAllocationCreateRequest request);
        Task<bool> UpdateSpaceAllocationAsync(Guid id, SpaceAllocationUpdateRequest request);
        Task<bool> DeleteSpaceAllocationAsync(Guid id);
    }
}
