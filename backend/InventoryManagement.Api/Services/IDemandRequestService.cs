using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IDemandRequestService
    {
        Task<PagedResult<DemandRequestSummary>> GetAllAsync(DemandRequestFilter filter);
        Task<DemandRequestDetails?> GetByIdAsync(int id);
        Task<IReadOnlyList<DemandRequestLifeCycleEntry>> GetLifeCycleAsync(int id);
        Task<IReadOnlyList<DemandRequestItemLogEntry>> GetItemLogsAsync(int id);
        Task<DemandRequestDetails> CreateAsync(DemandRequestCreateRequest request);
        Task<DemandRequestDetails?> ReceiveAsync(int id, DemandRequestReceiveRequest request);
        Task<DemandRequestDetails?> UpdateAsync(int id, DemandRequestUpdateRequest request);
        Task<DemandRequestDetails?> ApproveAsync(int id, DemandRequestUpdateRequest request);
        Task<DemandRequestDetails?> DispatchAsync(int id, DemandRequestDispatchRequest request);
        Task<DemandRequestDetails?> RejectAsync(int id, DemandRequestRejectRequest request);
    }
}