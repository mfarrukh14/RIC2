using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IDemandRequestStatusService
    {
        Task<IReadOnlyList<DemandRequestStatusDto>> GetAllAsync();
        Task<DemandRequestStatusDto?> GetByIdAsync(int id);
        Task<DemandRequestStatusDto> CreateAsync(DemandRequestStatusUpsertRequest request);
        Task<DemandRequestStatusDto?> UpdateAsync(int id, DemandRequestStatusUpsertRequest request);
    }
}