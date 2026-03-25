using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IDemandRequestService
    {
        Task<IReadOnlyList<DemandRequestSummary>> GetAllAsync(DemandRequestFilter filter);
        Task<DemandRequestDetails?> GetByIdAsync(int id);
        Task<IReadOnlyList<DemandRequestLifeCycleEntry>> GetLifeCycleAsync(int id);
        Task<DemandRequestDetails> CreateAsync(DemandRequestCreateRequest request);
        Task<DemandRequestDetails?> ReceiveAsync(int id, DemandRequestReceiveRequest request);
    }
}